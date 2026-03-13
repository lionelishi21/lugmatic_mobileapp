import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';

class ArtistCard extends StatelessWidget {
  final ArtistModel artist;
  final VoidCallback? onTap;
  final VoidCallback? onFollow;
  final VoidCallback? onGift;

  const ArtistCard({
    Key? key,
    required this.artist,
    this.onTap,
    this.onFollow,
    this.onGift,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 140,
        child: Column(
          children: [
            // Artist Image (circular)
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Stack(
                children: [
                  ClipOval(child: _buildImage(artist.imageUrl, 110, 110)),
                  // Verified badge
                  if (artist.isVerified)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                        child: const Icon(Icons.verified, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              artist.name,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${_formatNumber(artist.followers)} followers',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onFollow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: artist.isFollowing
                          ? Colors.white.withOpacity(0.15)
                          : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      artist.isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onGift,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url, double w, double h) {
    if (url.isNotEmpty) {
      return Image.network(
        url, width: w, height: h, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(w, h),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _placeholder(w, h),
      );
    }
    return _placeholder(w, h);
  }

  Widget _placeholder(double w, double h) => Container(
    width: w, height: h,
    color: const Color(0xFF1A2332),
    child: Icon(Icons.person, color: Colors.white.withOpacity(0.3), size: w * 0.4),
  );

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
