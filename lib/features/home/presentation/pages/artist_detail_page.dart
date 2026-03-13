import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/artist_model.dart';
import '../../../../data/models/music_model.dart';
import '../../../../shared/widgets/gift_bottom_sheet.dart';
import '../../../../ui/widgets/music_player_widget.dart';
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
        // Hero sliver
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: const Color(0xFF0F172A),
          leading: IconButton(
            icon: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A2332))),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xFF0F172A)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + name row (overlapping hero)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0F172A), width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
                      ),
                      child: ClipOval(
                        child: Image.network(imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF10B981).withOpacity(0.3))),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (artist.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            artist.name,
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    _StatChip(label: 'Followers', value: '${artist.followers}'),
                    const SizedBox(width: 16),
                    _StatChip(label: 'Tracks', value: '${_songs.length}'),
                    const SizedBox(width: 16),
                    _StatChip(label: 'Albums', value: '${_albums.length}'),
                  ],
                ),
                const SizedBox(height: 16),

                // Bio
                if (artist.bio.isNotEmpty) ...[
                  Text(
                    artist.bio,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: _songs.isNotEmpty ? 'Play All' : 'No Tracks',
                        icon: Icons.play_arrow_rounded,
                        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                        onTap: _songs.isNotEmpty
                            ? () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => MusicPlayerWidget(music: _songs[0]),
                                fullscreenDialog: true))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _OutlineButton(
                      label: _isFollowing ? 'Following' : 'Follow',
                      onTap: () => setState(() => _isFollowing = !_isFollowing),
                    ),
                    const SizedBox(width: 10),
                    _IconBtn(
                      icon: Icons.card_giftcard_rounded,
                      color: const Color(0xFFFFD700),
                      onTap: () => GiftBottomSheet.show(
                        context,
                        artistId: widget.artistId,
                        artistName: artist.name,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Popular Tracks
                if (_songs.isNotEmpty) ...[
                  const Text('Popular Tracks', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ..._songs.take(5).toList().asMap().entries.map((e) {
                    final i = e.key;
                    final s = e.value;
                    return _TrackRow(
                      index: i + 1,
                      song: s,
                      coverUrl: s.imageUrl.isNotEmpty ? s.imageUrl : imageUrl,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SongDetailPage(songId: s.id, initialData: s),
                      )),
                    );
                  }),
                  const SizedBox(height: 28),
                ],

                // Discography / Albums
                if (_albums.isNotEmpty) ...[
                  const Text('Discography', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _albums.length,
                      itemBuilder: (ctx, i) {
                        final al = _albums[i];
                        final coverArt = ApiConfig.resolveUrl(al['coverArt']?.toString() ?? '');
                        return GestureDetector(
                          onTap: () {
                            // Navigate to album detail
                            Navigator.pushNamed(context, '/album', arguments: al['_id']);
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: coverArt.isNotEmpty
                                      ? Image.network(coverArt, width: 140, height: 140, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _albumPlaceholder())
                                      : _albumPlaceholder(),
                                ),
                                const SizedBox(height: 8),
                                Text(al['name']?.toString() ?? al['title']?.toString() ?? '',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Genre chips
                if (artist.genres.isNotEmpty) ...[
                  const Text('Genres', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: artist.genres.map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Text(g, style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 100),
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
class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;
  const _ActionButton({required this.label, required this.icon, required this.gradient, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: onTap != null ? LinearGradient(colors: gradient) : null,
          color: onTap != null ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: color, size: 22),
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
