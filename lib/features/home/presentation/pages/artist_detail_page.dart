import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/widgets/brand_gradient_fallback.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/artist_model.dart';
import '../../../../data/models/music_model.dart';
import '../../../../shared/widgets/gift_bottom_sheet.dart';
import '../../../../shared/widgets/comment_section_widget.dart';
import '../../../../data/providers/audio_provider.dart';
import '../../../../data/services/artist_service.dart';
import '../../../../data/services/video_service.dart';
import '../../../../data/models/video_model.dart';
import '../../../../ui/widgets/player_screen.dart';
import '../../../video/presentation/pages/videos_page.dart';
import '../../../../data/providers/message_provider.dart';

const Color _kBg = Color(0xFF0F172A);
const Color _kAccent = Color(0xFF10B981);

class ArtistDetailPage extends StatefulWidget {
  final String artistId;
  final ArtistModel? initialData;

  const ArtistDetailPage({Key? key, required this.artistId, this.initialData}) : super(key: key);

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  ArtistModel? _artist;
  List<MusicModel> _songs = [];
  List<Map<String, dynamic>> _albums = [];
  List<VideoModel> _videos = [];
  bool _loading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _artist = widget.initialData;
    // Best-known state until _loadData() resolves — also the fallback if it
    // fails, instead of silently regressing the button to "Follow".
    _isFollowing = widget.initialData?.isFollowing ?? false;
    _loadData();
  }

  Future<void> _loadData() async {
    final apiClient = context.read<ApiClient>();
    try {
      final results = await Future.wait([
        apiClient.dio.get('${ApiConfig.mobileArtists}/${widget.artistId}'),
        apiClient.dio.get(
          ApiConfig.songs,
          queryParameters: {'artist': widget.artistId, 'limit': 20},
        ),
        apiClient.dio.get(
          ApiConfig.albums,
          queryParameters: {'artist': widget.artistId, 'limit': 10},
        ),
        context.read<VideoService>().getVideos(artistId: widget.artistId),
      ]);

      // Artist
      final aBody = (results[0] as dynamic).data;
      final aData = aBody['data'] ?? aBody;
      final artist = ArtistModel.fromJson(aData as Map<String, dynamic>);

      // Songs
      final sBody = (results[1] as dynamic).data;
      final sItems = sBody['data'] ?? sBody['songs'] ?? [];
      final songs = (sItems as List)
          .map((j) => MusicModel.fromJson(j as Map<String, dynamic>))
          .toList();

      // Albums
      final alBody = (results[2] as dynamic).data;
      final alItems = alBody['data'] ?? alBody['albums'] ?? [];
      final albums = List<Map<String, dynamic>>.from(alItems);

      // Videos
      final videos = results[3] as List<VideoModel>;

      if (mounted) {
        setState(() {
          _artist = artist;
          _songs = songs;
          _albums = albums;
          _videos = videos;
          _isFollowing = artist.isFollowing;
          _loading = false;
        });
      }
    } catch (e) {
      // Don't let a hiccup in songs/albums/videos wipe out the follow state
      // we already know from widget.initialData — only _loading changes.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Re-fetches just the follow state from the canonical source, used after
  /// a successful toggle so the button reflects the backend, not just the
  /// optimistic local flip.
  Future<void> _refreshFollowState() async {
    final apiClient = context.read<ApiClient>();
    try {
      final res = await apiClient.dio.get('${ApiConfig.mobileArtists}/${widget.artistId}');
      final body = res.data;
      final data = body['data'] ?? body;
      final isFollowing = data['isFollowing'] as bool?;
      if (mounted && isFollowing != null) {
        setState(() => _isFollowing = isFollowing);
      }
    } catch (_) {
      // Keep the optimistic value — a failed refresh shouldn't flip the button.
    }
  }

  Future<void> _toggleFollow() async {
    final artistService = context.read<ArtistService>();
    final oldState = _isFollowing;
    setState(() => _isFollowing = !_isFollowing);
    try {
      if (oldState) {
        await artistService.unfollowArtist(widget.artistId);
      } else {
        await artistService.followArtist(widget.artistId);
      }
      await _refreshFollowState();
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowing = oldState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update following: $e')),
        );
      }
    }
  }

  Future<void> _messageArtist(ArtistModel artist) async {
    if (artist.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This artist cannot be messaged directly.')),
      );
      return;
    }
    final provider = context.read<MessageProvider>();
    try {
      final conv = await provider.startConversation(artist.userId!);
      if (!context.mounted) return;
      Navigator.pushNamed(context, '/chat', arguments: conv);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final artist = _artist;
    return Scaffold(
      backgroundColor: _kBg,
      body: _loading && artist == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
              ),
            )
          : artist == null
              ? const Center(child: Text('Artist not found', style: TextStyle(color: Colors.white)))
              : DefaultTabController(
                  length: 3,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      _buildBannerAppBar(context, artist),
                      SliverToBoxAdapter(child: _buildProfileHeader(context, artist)),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyTabBarDelegate(
                          const TabBar(
                            indicatorColor: _kAccent,
                            indicatorWeight: 3,
                            labelColor: _kAccent,
                            unselectedLabelColor: Colors.white54,
                            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                            tabs: [
                              Tab(text: 'Music'),
                              Tab(text: 'Community'),
                              Tab(text: 'About'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      children: [
                        _buildMusicTab(artist),
                        _buildCommunityTab(artist),
                        _buildAboutTab(artist),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBannerAppBar(BuildContext context, ArtistModel artist) {
    final hasImage = artist.imageUrl.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _kBg,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: ClipOval(
            child: Material(
              color: Colors.black.withValues(alpha: 0.35),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: ClipOval(
              child: Material(
                color: Colors.black.withValues(alpha: 0.35),
                child: IconButton(
                  icon: const Icon(Icons.ios_share, color: Colors.white, size: 18),
                  onPressed: () => Share.share('Check out ${artist.name} on Lugmatic!'),
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            hasImage
                ? Image.network(
                    artist.imageUrl,
                    fit: BoxFit.cover,
                    // Most artist photos are portrait headshots — centering the
                    // crop (BoxFit.cover's default) cuts off the top of the
                    // head/face on a wide, short banner. Bias toward the top.
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => const BrandGradientFallback(iconSize: 64, borderRadius: BorderRadius.zero),
                  )
                : const BrandGradientFallback(iconSize: 64, borderRadius: BorderRadius.zero),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    _kBg.withValues(alpha: 0.85),
                    _kBg,
                  ],
                  stops: const [0.0, 0.35, 0.85, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${artist.followers} Followers',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    if (artist.totalSongs > 0) ...[
                      const SizedBox(height: 2),
                      Text('${artist.totalSongs} Tracks',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ),
            if (artist.isLive)
              Positioned(
                top: 50,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/live', arguments: artist.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.5), blurRadius: 10)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 9),
                        SizedBox(width: 6),
                        Text('LIVE — TAP TO JOIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ArtistModel artist) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: -40),
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kBg, width: 4),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12)],
            ),
            child: ClipOval(
              child: artist.imageUrl.isNotEmpty
                  ? Image.network(artist.imageUrl, fit: BoxFit.cover, alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => const BrandGradientFallback(iconSize: 32, borderRadius: BorderRadius.zero))
                  : const BrandGradientFallback(iconSize: 32, borderRadius: BorderRadius.zero),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Flexible(
                child: Text(
                  artist.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
              ),
              if (artist.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: _kAccent, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showRatingDialog(context, artist),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD700), size: 15),
                const SizedBox(width: 4),
                Text(
                  artist.averageRating > 0 ? artist.averageRating.toStringAsFixed(1) : 'New',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                if (artist.ratingCount > 0)
                  Text(' (${artist.ratingCount})', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                if (artist.location.isNotEmpty) ...[
                  Text('  •  ', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                  Icon(Icons.location_on, color: Colors.white.withValues(alpha: 0.4), size: 13),
                  const SizedBox(width: 3),
                  Text(artist.location, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          if (artist.genres.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: artist.genres.map((g) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
                ),
                child: Text(g.toUpperCase(),
                    style: const TextStyle(color: _kAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              )).toList(),
            ),
          ],
          if (artist.bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              artist.bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.5),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _toggleFollow,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: _isFollowing ? Colors.transparent : _kAccent,
                      borderRadius: BorderRadius.circular(23),
                      border: _isFollowing ? Border.all(color: Colors.white.withValues(alpha: 0.25)) : null,
                    ),
                    child: Center(
                      child: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          color: _isFollowing ? Colors.white : _kBg,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _messageArtist(artist),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Message', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => GiftBottomSheet.show(context, artistId: widget.artistId, artistName: artist.name),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, ArtistModel artist) {
    double currentRating = artist.userRating ?? 5.0;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Rate Artist', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How would you rate this artist?', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < currentRating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFD700),
                          size: 36,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            currentRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await context.read<ArtistService>().rateArtist(artist.id, currentRating);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Rating submitted!')));
                        _loadData(); // reload to get new rating
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Failed to rate: $e')));
                      }
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildMusicTab(ArtistModel artist) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_songs.isNotEmpty) ...[
          _PlayButton(
            onTap: () {
              context.read<AudioProvider>().playMusic(_songs[0], queue: _songs);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => PlayerScreen(music: _songs[0]),
              );
            },
          ),
          const SizedBox(height: 28),
        ],

        // Popular Tracks Section
        if (_songs.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              if (_songs.length > 5)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ArtistAllTracksPage(artist: artist, songs: _songs),
                    ),
                  ),
                  child: Text('See all', style: TextStyle(color: _kAccent.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _songs.length.clamp(0, 5),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = _songs[i];
              return _TrackRow(
                index: i + 1,
                song: s,
                coverUrl: s.imageUrl.isNotEmpty ? s.imageUrl : (artist.imageUrl.isNotEmpty ? artist.imageUrl : ''),
                onTap: () {
                  context.read<AudioProvider>().playMusic(s, queue: _songs);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => PlayerScreen(music: s),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 40),
        ],

        // Discography Section
        if (_albums.isNotEmpty) ...[
          const Text('Discography', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _albums.length,
              itemBuilder: (ctx, i) {
                final al = _albums[i];
                final coverArt = ApiConfig.resolveUrl(al['coverArt']?.toString() ?? '');
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/album', arguments: al['_id']);
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: coverArt.isNotEmpty
                                ? Image.network(coverArt, width: 160, height: 160, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const BrandGradientFallback(iconSize: 48, borderRadius: BorderRadius.zero))
                                : const BrandGradientFallback(iconSize: 48, borderRadius: BorderRadius.zero),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(al['name']?.toString() ?? al['title']?.toString() ?? '',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        Text('${al['releaseDate']?.toString().split('-')[0] ?? ''} • Album',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],

        // Music Videos Section
        if (_videos.isNotEmpty) ...[
          const Text('Music Videos', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _videos.length,
              itemBuilder: (ctx, i) {
                final v = _videos[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(video: v),
                      ),
                    );
                  },
                  child: Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: v.thumbnailUrl.isNotEmpty
                                  ? Image.network(v.thumbnailUrl, width: 240, height: 135, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _videoPlaceholder())
                                  : _videoPlaceholder(),
                            ),
                            const Positioned.fill(
                              child: Center(
                                child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(v.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],

        // Past Lives Section
        const Text('Past Lives', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off, color: Colors.white.withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 12),
                Text(
                  'No recorded sessions yet',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'When ${artist.name} saves a live stream, it will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCommunityTab(ArtistModel artist) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        CommentSectionWidget(contentType: 'artist', contentId: widget.artistId),
      ],
    );
  }

  Widget _buildAboutTab(ArtistModel artist) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Followers', value: '${artist.followers}')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Tracks', value: '${artist.totalSongs}')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Releases', value: '${artist.totalAlbums}')),
          ],
        ),
        const SizedBox(height: 24),
        if (artist.bio.isNotEmpty || artist.genres.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (artist.bio.isNotEmpty) ...[
                  const Text('Biography', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(artist.bio,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15, height: 1.6)),
                  const SizedBox(height: 24),
                ],
                if (artist.genres.isNotEmpty) ...[
                  const Text('Genres', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: artist.genres.map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(g, style: const TextStyle(color: _kAccent, fontSize: 13, fontWeight: FontWeight.w700)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'No additional information available for this artist.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _videoPlaceholder() => Container(
    width: 240, height: 135, color: const Color(0xFF1A2332),
    child: const Icon(Icons.video_library, color: Colors.white24, size: 40),
  );
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: _kBg, child: tabBar);
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}

// ── Supporting widgets ───────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _PlayButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_kAccent, Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(onTap == null ? Icons.block : Icons.play_arrow_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(onTap == null ? 'NO TRACKS' : 'PLAY ALL',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final int index;
  final MusicModel song;
  final String coverUrl;
  final VoidCallback onTap;
  const _TrackRow({required this.index, required this.song, required this.coverUrl, required this.onTap});

  String _fmtDur(Duration d) {
    return '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('$index', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: coverUrl.isNotEmpty
                  ? Image.network(coverUrl, width: 42, height: 42, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const BrandGradientFallback(width: 42, height: 42, iconSize: 18, borderRadius: BorderRadius.zero))
                  : const BrandGradientFallback(width: 42, height: 42, iconSize: 18, borderRadius: BorderRadius.zero),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Text(_fmtDur(song.duration),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_outline, color: _kAccent, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ArtistAllTracksPage extends StatelessWidget {
  final ArtistModel artist;
  final List<MusicModel> songs;

  const _ArtistAllTracksPage({required this.artist, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text('${artist.name} — All Tracks', style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final s = songs[i];
          return _TrackRow(
            index: i + 1,
            song: s,
            coverUrl: s.imageUrl.isNotEmpty ? s.imageUrl : (artist.imageUrl.isNotEmpty ? artist.imageUrl : ''),
            onTap: () {
              context.read<AudioProvider>().playMusic(s, queue: songs);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => PlayerScreen(music: s),
              );
            },
          );
        },
      ),
    );
  }
}
