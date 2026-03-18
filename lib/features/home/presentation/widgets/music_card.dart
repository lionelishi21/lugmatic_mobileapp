import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/music_model.dart';

class MusicCard extends StatelessWidget {
  final MusicModel music;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onLike;
  final bool showGlow;

  const MusicCard({
    Key? key,
    required this.music,
    this.onTap,
    this.onPlay,
    this.onLike,
    this.showGlow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (showGlow)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: -5,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Art with Play Button
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                Hero(
                  tag: 'music_art_${music.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildImage(music.imageUrl, 160, 160),
                  ),
                ),
                // Gradient overlay
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                // Play button overlay
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onPlay,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDim],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  music.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  music.artist,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (music.genre.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Text(
                          music.genre,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.access_time_rounded,
                      color: AppColors.mutedForeground.withOpacity(0.6),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(music.duration),
                      style: TextStyle(
                        color: AppColors.mutedForeground.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl, double width, double height) {
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
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
      } else {
        return Image.asset(
          imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(width, height),
        );
      }
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
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ),
      );

  String _formatDuration(Duration duration) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
