// lib/features/home/presentation/widgets/playlist_list_item.dart
import 'package:flutter/material.dart';

class PlaylistListItem extends StatelessWidget {
  final String title;
  final String artist;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const PlaylistListItem({
    Key? key,
    required this.title,
    required this.artist,
    required this.gradientColors,
    this.onTap,
    this.onMoreTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF141414),
              offset: Offset(6, 6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: Color(0xFF202020),
              offset: Offset(-6, -6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    artist,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onMoreTap,
              child: Icon(
                Icons.more_horiz,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}