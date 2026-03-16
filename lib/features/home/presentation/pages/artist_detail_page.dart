import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/artist_model.dart';
import '../../../../data/models/music_model.dart';
import '../../../../shared/widgets/gift_bottom_sheet.dart';
import '../../../../data/providers/audio_provider.dart';
import '../../../../ui/widgets/player_screen.dart';
import '../../../song/presentation/pages/song_detail_page.dart';

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
  bool _loading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _artist = widget.initialData;
    _loadData();
  }

  Future<void> _loadData() async {
    final apiClient = context.read<ApiClient>();
    try {
      final results = await Future.wait([
        apiClient.dio.get('${ApiConfig.artistDetails}/${widget.artistId}'),
        apiClient.dio.get(
          ApiConfig.songs,
          queryParameters: {'artist': widget.artistId, 'limit': 20},
        ),
        apiClient.dio.get(
          ApiConfig.albums,
          queryParameters: {'artist': widget.artistId, 'limit': 10},
        ),
      ]);

      // Artist
      final aBody = results[0].data;
      final aData = aBody['data'] ?? aBody;
      final artist = ArtistModel.fromJson(aData as Map<String, dynamic>);

      // Songs
      final sBody = results[1].data;
      final sItems = sBody['data'] ?? sBody['songs'] ?? [];
      final songs = (sItems as List)
          .map((j) => MusicModel.fromJson(j as Map<String, dynamic>))
          .toList();

      // Albums
      final alBody = results[2].data;
      final alItems = alBody['data'] ?? alBody['albums'] ?? [];
      final albums = List<Map<String, dynamic>>.from(alItems);

      if (mounted) {
        setState(() {
          _artist = artist;
          _songs = songs;
          _albums = albums;
          _isFollowing = artist.isFollowing;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final artist = _artist;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _loading && artist == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            )
          : artist == null
              ? const Center(child: Text('Artist not found', style: TextStyle(color: Colors.white)))
              : _buildContent(context, artist),
    );
  }

  Widget _buildContent(BuildContext context, ArtistModel artist) {
    final imageUrl = artist.imageUrl.isNotEmpty
        ? artist.imageUrl
        : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop';

    return CustomScrollView(
      slivers: [
        // Immersive Hero sliver
        SliverAppBar(
          expandedHeight: 380,
          pinned: true,
          stretch: true,
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Center(
              child: ClipOval(
                child: Material(
                  color: Colors.black.withOpacity(0.3),
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
                    color: Colors.black.withOpacity(0.3),
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
              StretchMode.fadeTitle,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A2332))),
                // Dynamic Overlays
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        const Color(0xFF0F172A).withOpacity(0.6),
                        const Color(0xFF0F172A),
                      ],
                      stops: const [0.0, 0.3, 0.8, 1.0],
                    ),
                  ),
                ),
                // Artist Name & Status at bottom of hero
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (artist.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 10)],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text('VERIFIED ARTIST', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        artist.name,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 48, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: -1.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${artist.followers ?? 0} Followers',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PlayButton(
                          onTap: _songs.isNotEmpty
                              ? () {
                                  context.read<AudioProvider>().playMusic(_songs[0], queue: _songs);
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => PlayerScreen(music: _songs[0]),
                                  );
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _CircleActionButton(
                        icon: _isFollowing ? Icons.person_add_disabled : Icons.person_add,
                        isActive: _isFollowing,
                        onTap: () => setState(() => _isFollowing = !_isFollowing),
                      ),
                      const SizedBox(width: 12),
                      _CircleActionButton(
                        icon: Icons.card_giftcard,
                        color: const Color(0xFFFFD700),
                        onTap: () => GiftBottomSheet.show(
                          context,
                          artistId: widget.artistId,
                          artistName: artist.name,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(height: 32),

                // Popular Tracks Section
                if (_songs.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Popular Tracks', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      TextButton(
                        onPressed: () {},
                        child: Text('See all', style: TextStyle(color: const Color(0xFF10B981).withOpacity(0.8), fontWeight: FontWeight.w700)),
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
                  const Text('Discography', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: coverArt.isNotEmpty
                                        ? Image.network(coverArt, width: 160, height: 160, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _albumPlaceholder())
                                        : _albumPlaceholder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(al['name']?.toString() ?? al['title']?.toString() ?? '',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                                Text('${al['releaseDate']?.toString().split('-')[0] ?? ''} • Album',
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],

                // About Section
                if (artist.bio.isNotEmpty || artist.genres.isNotEmpty) ...[
                  const Text('About', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (artist.bio.isNotEmpty) ...[
                          Text(artist.bio,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.6)),
                          const SizedBox(height: 20),
                        ],
                        if (artist.genres.isNotEmpty)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: artist.genres.map((g) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                              ),
                              child: Text(g, style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w700)),
                            )).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _albumPlaceholder() => Container(
    width: 140, height: 140, color: const Color(0xFF1A2332),
    child: const Icon(Icons.album, color: Colors.white24, size: 48),
  );
}

// ── Supporting widgets ───────────────────────────────────────────────────────
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
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
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

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color? color;
  const _CircleActionButton({required this.icon, required this.onTap, this.isActive = false, this.color});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? const Color(0xFF10B981).withOpacity(0.5) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color ?? (isActive ? const Color(0xFF10B981) : Colors.white), size: 24),
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
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('$index', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: coverUrl.isNotEmpty
                  ? Image.network(coverUrl, width: 42, height: 42, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 42, height: 42, color: Colors.white.withOpacity(0.1)))
                  : Container(width: 42, height: 42, color: Colors.white.withOpacity(0.1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Text(_fmtDur(song.duration),
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_outline, color: Color(0xFF10B981), size: 22),
          ],
        ),
      ),
    );
  }
}
