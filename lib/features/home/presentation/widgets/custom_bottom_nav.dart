// lib/features/home/presentation/widgets/custom_bottom_nav.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';

/// Bottom nav matching lugmatic-music web sidebar style:
/// dark glass surface, white icons, green active indicator pill.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onPlayTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.onPlayTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                _item(context, Icons.home_rounded, 'Home', 0),
                _item(context, Icons.grid_view_rounded, 'Explore', 1),
                _item(context, Icons.sensors_rounded, 'Live', 2),
                _item(context, Icons.play_circle_outline_rounded, 'Video', 3),
                _item(context, Icons.library_music_rounded, 'Library', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext ctx, IconData icon, String label, int index) {
    final selected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected
                    ? AppColors.primary
                    : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: selected
                    ? AppColors.primary
                    : AppColors.mutedForeground,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
