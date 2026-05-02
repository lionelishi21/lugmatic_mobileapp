import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/music_model.dart';
import '../../../../shared/widgets/gift_bottom_sheet.dart';
import '../../../../shared/widgets/comment_section_widget.dart';
import '../../../../data/providers/audio_provider.dart';
import '../../../../ui/widgets/player_screen.dart';

class SongDetailPage extends StatefulWidget {
  final String songId;
  final MusicModel? initialData;

  const SongDetailPage({Key? key, required this.songId, this.initialData}) : super(key: key);

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  MusicModel? _song;
  List<MusicModel> _related = [];
  bool _loading = true;
  bool _isLiked = false;
  String _tab = 'about'; // 'about' | 'lyrics' | 'comments'
  String? _lyrics;

  @override
  void initState() {
    super.initState();
    _song = widget.initialData;
    _loadData();
  }

  Future<void> _loadData() async {
    final apiClient = context.read<ApiClient>();
    try {
      // Fetch song details
      final res = await apiClient.dio.get('${ApiConfig.songDetails}/${widget.songId}');
      final body = res.data;
      final data = body['data'] ?? body;
      final song = MusicModel.fromJson(data as Map<String, dynamic>);

      // Fetch related (same artist)
      List<MusicModel> related = [];
      if (song.artistId.isNotEmpty) {
        try {
          final rRes = await apiClient.dio.get(
            ApiConfig.songs,
            queryParameters: {'artist': song.artistId, 'limit': 10},
          );
          final rBody = rRes.data;
          final rItems = rBody['data'] ?? rBody['songs'] ?? [];
          related = (rItems as List)
              .map((j) => MusicModel.fromJson(j as Map<String, dynamic>))
              .where((s) => s.id != widget.songId)
              .toList();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _song = song;
          _related = related;
          _lyrics = data['lyrics'] as String?;
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
    final song = _song;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _loading && song == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            )
          : song == null
              ? const Center(
                  child: Text('Song not found', style: TextStyle(color: Colors.white)),
                )
              : _buildContent(context, song),
    );
  }

  Widget _buildContent(BuildContext context, MusicModel song) {
    final coverUrl = song.imageUrl.isNotEmpty
        ? song.imageUrl
        : 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop';

    return CustomScrollView(
      slivers: [
        // Hero + AppBar
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          backgroundColor: const Color(0xFF0F172A),
          leading: IconButton(
            icon: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Blurred background
                Image.network(coverUrl, fit: BoxFit.cover,
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
                // Cover art centered
                Center(
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1A2332),
                          child: const Icon(Icons.music_note, color: Colors.white38, size: 64),
                        ),
                      ),
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
                // Title + Artist
                Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  song.artist,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (song.album.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    song.album,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    // Play button
                    Expanded(
                      child: _ActionButton(
                        onTap: () {
                          context.read<AudioProvider>().playMusic(song, queue: [song, ..._related]);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => PlayerScreen(music: song),
                          );
                        },
                        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text('Play', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Like button
                    _IconActionButton(
                      onTap: () => setState(() => _isLiked = !_isLiked),
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? const Color(0xFFEF4444) : Colors.white,
                    ),
                    const SizedBox(width: 10),
                    // Gift button
                    _IconActionButton(
                      onTap: () => GiftBottomSheet.show(
                        context,
                        artistId: song.artistId,
                        artistName: song.artist,
                      ),
                      icon: Icons.card_giftcard_rounded,
                      color: const Color(0xFFFFD700),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Tabs
                Row(
                  children: [
                    _Tab(label: 'About', selected: _tab == 'about', onTap: () => setState(() => _tab = 'about')),
                    const SizedBox(width: 8),
                    _Tab(label: 'Lyrics', selected: _tab == 'lyrics', onTap: () => setState(() => _tab = 'lyrics')),
                    const SizedBox(width: 8),
                    _Tab(label: 'Comments', selected: _tab == 'comments', onTap: () => setState(() => _tab = 'comments')),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab content
                if (_tab == 'about') _buildAboutTab(song)
                else if (_tab == 'lyrics') _buildLyricsTab()
                else CommentSectionWidget(contentType: 'song', contentId: widget.songId),
                const SizedBox(height: 32),

                // Related / More from artist
                if (_related.isNotEmpty) ...[
                  Text(
                    'More from ${song.artist}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._related.take(8).map((s) => _SongRow(song: s, onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SongDetailPage(songId: s.id, initialData: s),
                      ),
                    );
                  })),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTab(MusicModel song) {
    final rows = <Map<String, String>>[
      if (song.artist.isNotEmpty) {'label': 'Artist', 'value': song.artist},
      if (song.album.isNotEmpty) {'label': 'Album', 'value': song.album},
      if (song.genre.isNotEmpty) {'label': 'Genre', 'value': song.genre},
      {'label': 'Duration', 'value': _formatDuration(song.duration)},
      if (song.playCount > 0) {'label': 'Plays', 'value': '${song.playCount}'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final row = e.value;
          final isLast = e.key == rows.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row['label']!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                Text(row['value']!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLyricsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: _lyrics != null && _lyrics!.isNotEmpty
          ? Text(
              _lyrics!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                height: 1.8,
              ),
            )
          : Column(
              children: [
                Icon(Icons.mic_none, color: Colors.white.withOpacity(0.2), size: 48),
                const SizedBox(height: 12),
                Text('No lyrics available', style: TextStyle(color: Colors.white.withOpacity(0.4))),
              ],
            ),
    );
  }
}

// ── Song Row ────────────────────────────────────────────────────────────────
class _SongRow extends StatelessWidget {
  final MusicModel song;
  final VoidCallback onTap;

  const _SongRow({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.imageUrl.isNotEmpty
                  ? Image.network(song.imageUrl, width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52, height: 52, color: const Color(0xFF10B981).withOpacity(0.2),
                        child: const Icon(Icons.music_note, color: Colors.white38),
                      ))
                  : Container(
                      width: 52, height: 52, color: const Color(0xFF10B981).withOpacity(0.2),
                      child: const Icon(Icons.music_note, color: Colors.white38),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline, color: const Color(0xFF10B981).withOpacity(0.7), size: 28),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────
class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
              : null,
          color: selected ? null : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withOpacity(0.6),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final List<Color> gradient;
  final Widget child;

  const _ActionButton({required this.onTap, required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _IconActionButton({required this.onTap, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50, height: 50,
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
