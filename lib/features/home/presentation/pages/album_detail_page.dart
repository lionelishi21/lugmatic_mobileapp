import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/music_model.dart';
import '../../../../shared/widgets/gift_bottom_sheet.dart';
import '../../../../ui/widgets/music_player_widget.dart';
import '../../../song/presentation/pages/song_detail_page.dart';
import '../pages/artist_detail_page.dart';
import '../../../../data/models/artist_model.dart';

class AlbumDetailPage extends StatefulWidget {
  final String albumId;
  final Map<String, dynamic>? initialData;

  const AlbumDetailPage({Key? key, required this.albumId, this.initialData}) : super(key: key);

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  Map<String, dynamic>? _album;
  List<MusicModel> _songs = [];
  List<Map<String, dynamic>> _recommended = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _album = widget.initialData;
    _loadData();
  }

  Future<void> _loadData() async {
    final apiClient = context.read<ApiClient>();
    try {
      final res = await apiClient.dio.get('${ApiConfig.albumDetails}/${widget.albumId}');
      final body = res.data;
      final data = (body['data'] ?? body) as Map<String, dynamic>;

      // Extract songs from album
      List<MusicModel> songs = [];
      final rawSongs = data['songs'] ?? data['tracks'] ?? [];
      if (rawSongs is List && rawSongs.isNotEmpty) {
        songs = rawSongs.map((j) => MusicModel.fromJson(j as Map<String, dynamic>)).toList();
      }

      // Fetch recommended albums from same artist
      List<Map<String, dynamic>> recommended = [];
      final artistField = data['artist'];
      String? artistId;
      if (artistField is Map) {
        artistId = artistField['_id']?.toString() ?? artistField['id']?.toString();
      }
      if (artistId != null) {
        try {
          final recRes = await apiClient.dio.get(
            ApiConfig.albums,
            queryParameters: {'artist': artistId, 'limit': 6},
          );
          final recBody = recRes.data;
          final recItems = recBody['data'] ?? recBody['albums'] ?? [];
          recommended = (recItems as List)
              .map((j) => j as Map<String, dynamic>)
              .where((al) => al['_id']?.toString() != widget.albumId)
              .toList();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _album = data;
          _songs = songs;
          _recommended = recommended;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDur(Duration d) {
    return '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _loading && _album == null
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981))))
          : _album == null
              ? const Center(child: Text('Album not found', style: TextStyle(color: Colors.white)))
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final album = _album!;
    final title = album['name']?.toString() ?? album['title']?.toString() ?? 'Unknown Album';
    final coverArt = ApiConfig.resolveUrl(album['coverArt']?.toString() ?? '');

    // Artist info
    final artistField = album['artist'];
    String artistName = '';
    String artistId = '';
    if (artistField is Map) {
      artistName = artistField['name']?.toString() ?? '';
      artistId = artistField['_id']?.toString() ?? artistField['id']?.toString() ?? '';
    }

    final releaseDate = album['releaseDate'] != null
        ? DateTime.tryParse(album['releaseDate'].toString())
        : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
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
                // Blurred background
                if (coverArt.isNotEmpty)
                  Image.network(coverArt, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A2332)))
                else
                  Container(color: const Color(0xFF1A2332)),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xFF0F172A)],
                    ),
                  ),
                ),
                // Centered album art
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 40, offset: const Offset(0, 20))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: coverArt.isNotEmpty
                          ? Image.network(coverArt, width: 190, height: 190, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Album label
                Text(
                  (album['type'] ?? 'Album').toString().toUpperCase(),
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 8),

                // Artist + date row
                Row(
                  children: [
                    if (artistName.isNotEmpty) ...[
                      GestureDetector(
                        onTap: artistId.isNotEmpty
                            ? () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ArtistDetailPage(artistId: artistId)))
                            : null,
                        child: Text(
                          artistName,
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    if (releaseDate != null) ...[
                      Text('  ·  ', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                      Text(
                        '${releaseDate.year}',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                      ),
                    ],
                    if (_songs.isNotEmpty) ...[
                      Text('  ·  ', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                      Text(
                        '${_songs.length} tracks',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _songs.isNotEmpty
                            ? () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => MusicPlayerWidget(music: _songs[0]),
                                fullscreenDialog: true))
                            : null,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: _songs.isNotEmpty
                                ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                                : null,
                            color: _songs.isEmpty ? Colors.white.withOpacity(0.08) : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _songs.isNotEmpty ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))] : [],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text('Play Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (artistId.isNotEmpty)
                      GestureDetector(
                        onTap: () => GiftBottomSheet.show(
                          context,
                          artistId: artistId,
                          artistName: artistName,
                        ),
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD700), size: 22),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                // Track list
                if (_songs.isNotEmpty) ...[
                  const Text('Tracks', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ..._songs.asMap().entries.map((e) => GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SongDetailPage(songId: e.value.id, initialData: e.value),
                    )),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Text('${e.key + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.value.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                if (e.value.artist.isNotEmpty)
                                  Text(e.value.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(_fmtDur(e.value.duration),
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                          const SizedBox(width: 8),
                          const Icon(Icons.play_circle_outline, color: Color(0xFF10B981), size: 22),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 32),
                ],

                // More from artist / Recommendations
                if (_recommended.isNotEmpty) ...[
                  Text(
                    'More from ${artistName.isNotEmpty ? artistName : 'Artist'}',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recommended.length,
                      itemBuilder: (ctx, i) {
                        final al = _recommended[i];
                        final alCover = ApiConfig.resolveUrl(al['coverArt']?.toString() ?? '');
                        final alTitle = al['name']?.toString() ?? al['title']?.toString() ?? '';
                        return GestureDetector(
                          onTap: () => Navigator.push(ctx, MaterialPageRoute(
                            builder: (_) => AlbumDetailPage(albumId: al['_id']?.toString() ?? '', initialData: al),
                          )),
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: alCover.isNotEmpty
                                      ? Image.network(alCover, width: 140, height: 140, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _placeholder())
                                      : _placeholder(),
                                ),
                                const SizedBox(height: 8),
                                Text(alTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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

  Widget _placeholder() => Container(
    width: 140, height: 140,
    decoration: BoxDecoration(
      color: const Color(0xFF1A2332),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.album, color: Colors.white24, size: 48),
  );
}
