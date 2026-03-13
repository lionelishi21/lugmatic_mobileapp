import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';

class MusicCard extends StatelessWidget {
  final MusicModel music;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onLike;

  const MusicCard({
    Key? key,
    required this.music,
    this.onTap,
    this.onPlay,
    this.onLike,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Art with Play Button
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(music.imageUrl, 160, 160),
                ),
                // Gradient overlay
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Play button
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onPlay,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            music.title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            music.artist,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (music.genre.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    music.genre,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                ),
              const Spacer(),
              Text(
                _formatDuration(music.duration),
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl, double width, double height) {
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(width, height),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingPlaceholder(width, height);
        },
      );
    }
    return _placeholder(width, height);
  }

  Widget _placeholder(double width, double height) => Container(
    width: width,
    height: height,
    color: const Color(0xFF1A2332),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.music_note, color: Colors.white.withOpacity(0.3), size: 40),
      ],
    ),
  );

  Widget _loadingPlaceholder(double width, double height) => Container(
    width: width,
    height: height,
    color: const Color(0xFF1A2332),
    child: const Center(
      child: SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981))),
      ),
    ),
  );

  String _formatDuration(Duration duration) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
