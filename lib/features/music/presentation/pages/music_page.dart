import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/music_model.dart';
import '../../../../data/providers/audio_provider.dart';
import '../../../../data/services/music_service.dart';
import '../../../../core/config/api_config.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({Key? key}) : super(key: key);

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  List<MusicModel> _songs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final musicService = context.read<MusicService>();
      final songs = await musicService.getSongs(limit: 50);
      if (mounted) {
        setState(() {
          _songs = songs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Music',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white.withOpacity(0.4), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load songs',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() { _loading = true; _error = null; });
                          _loadSongs();
                        },
                        child: const Text('Retry', style: TextStyle(color: Color(0xFF10B981))),
                      ),
                    ],
                  ),
                )
              : _songs.isEmpty
                  ? Center(
                      child: Text(
                        'No songs available',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _songs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return _buildSongItem(song);
                      },
                    ),
    );
  }

  Widget _buildSongItem(MusicModel song) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, _) {
        final isCurrentSong = audioProvider.currentMusic?.id == song.id;
        final isPlaying = isCurrentSong && audioProvider.isPlaying;

        return Material(
          color: isCurrentSong
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              audioProvider.playMusic(song, queue: _songs);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: song.imageUrl.isNotEmpty
                          ? Image.network(
                              song.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderArt(),
                            )
                          : _placeholderArt(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title + Artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: isCurrentSong
                                ? const Color(0xFF10B981)
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Play indicator
                  if (isCurrentSong && audioProvider.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    )
                  else
                    Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isCurrentSong
                          ? const Color(0xFF10B981)
                          : Colors.white.withOpacity(0.5),
                      size: 28,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderArt() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Icon(Icons.music_note, color: Color(0xFF10B981), size: 24),
    );
  }
}
