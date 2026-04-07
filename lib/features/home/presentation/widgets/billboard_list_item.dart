import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/music_model.dart';

class BillboardListItem extends StatelessWidget {
  final MusicModel music;
  final int rank;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;

  const BillboardListItem({
    Key? key,
    required this.music,
    required this.rank,
    this.onTap,
    this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine rank color
    final Color rankColor = rank == 1 
        ? const Color(0xFFFFD700) // Gold
        : rank == 2 
            ? const Color(0xFFC0C0C0) // Silver
            : rank == 3 
                ? const Color(0xFFCD7F32) // Bronze
                : Colors.white.withOpacity(0.5);

    final stats = music.billboardStats;
    final plays = stats?['plays'] ?? 0;
    final gifts = stats?['gifts'] ?? 0;
    final likes = stats?['likes'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            // Ranking Number
            SizedBox(
              width: 40,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rankColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    if (rank <= 3)
                      Shadow(
                        color: rankColor.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            
            // Album Art
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(music.imageUrl, 64, 64),
                ),
                if (onPlay != null)
                  Positioned.fill(
                    child: Center(
                      child: GestureDetector(
                        onTap: onPlay,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    music.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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
                  
                  // Score Metrics
                  Row(
                    children: [
                      _buildMiniStat(Icons.play_arrow_outlined, _formatNumber(plays)),
                      const SizedBox(width: 12),
                      _buildMiniStat(Icons.card_giftcard_outlined, _formatNumber(gifts)),
                      const SizedBox(width: 12),
                      _buildMiniStat(Icons.favorite_outline, _formatNumber(likes)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Trend Indicator (Mocked for now as we don't have historical diffs yet)
            const Icon(
              Icons.trending_up,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _buildImage(String imageUrl, double width, double height) {
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(width, height),
      );
    }
    return _placeholder(width, height);
  }

  Widget _placeholder(double width, double height) => Container(
        width: width,
        height: height,
        color: const Color(0xFF1A2332),
        child: const Icon(Icons.music_note, color: Colors.white24, size: 24),
      );
}
