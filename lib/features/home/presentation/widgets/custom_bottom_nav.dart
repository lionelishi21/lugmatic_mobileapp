// lib/features/home/presentation/widgets/custom_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';

class _NavDestination {
  final IconData outlined;
  final IconData filled;
  final String label;
  final int index;

  const _NavDestination({
    required this.outlined,
    required this.filled,
    required this.label,
    required this.index,
  });
}

/// Bottom nav matching lugmatic-music web sidebar style:
/// dark glass surface, white icons, sliding green active indicator,
/// and a center quick-play button sized/placed like the Artist shell's
/// "Go Live" button (inline in the row, bottom-aligned, not floating above it).
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

  static const _left = [
    _NavDestination(outlined: Icons.home_outlined, filled: Icons.home_rounded, label: 'Home', index: 0),
    _NavDestination(outlined: Icons.auto_awesome_outlined, filled: Icons.auto_awesome_rounded, label: 'For You', index: 1),
  ];

  static const _right = [
    _NavDestination(outlined: Icons.sensors_outlined, filled: Icons.sensors_rounded, label: 'Live', index: 2),
    _NavDestination(outlined: Icons.play_circle_outline_rounded, filled: Icons.play_circle_rounded, label: 'Video', index: 3),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _NavGroup(destinations: _left, currentIndex: currentIndex, onTap: onTap),
                ),
                if (onPlayTap != null) _CenterPlayButton(onTap: onPlayTap!),
                Expanded(
                  child: _NavGroup(destinations: _right, currentIndex: currentIndex, onTap: onTap),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of nav items with a single indicator bar that slides smoothly
/// between them as the selection changes within this group.
class _NavGroup extends StatelessWidget {
  final List<_NavDestination> destinations;
  final int currentIndex;
  final Function(int) onTap;

  const _NavGroup({
    required this.destinations,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedPos = destinations.indexWhere((d) => d.index == currentIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / destinations.length;
        const indicatorWidth = 28.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (selectedPos != -1)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                top: 0,
                left: itemWidth * selectedPos + (itemWidth - indicatorWidth) / 2,
                width: indicatorWidth,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Row(
              children: destinations
                  .map((d) => Expanded(
                        child: _NavItem(
                          destination: d,
                          selected: d.index == currentIndex,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(d.index);
                          },
                        ),
                      ))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _NavItem extends StatefulWidget {
  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.88),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? widget.destination.filled : widget.destination.outlined,
                size: 22,
                color: selected ? AppColors.primary : AppColors.mutedForeground,
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.mutedForeground,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(widget.destination.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sized and placed to match the Artist shell's "Go Live" center button:
/// a 56px circle, inline in the row (not floating above it), bottom-aligned
/// alongside the shorter nav items so it naturally reads as elevated.
class _CenterPlayButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CenterPlayButton({required this.onTap});

  @override
  State<_CenterPlayButton> createState() => _CenterPlayButtonState();
}

class _CenterPlayButtonState extends State<_CenterPlayButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDim],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Play',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedForeground,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
