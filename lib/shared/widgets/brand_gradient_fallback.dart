import 'package:flutter/material.dart';

class BrandGradientFallback extends StatelessWidget {
  final double? width;
  final double? height;
  final double iconSize;
  final BorderRadius? borderRadius;

  const BrandGradientFallback({
    Key? key,
    this.width,
    this.height,
    this.iconSize = 32,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.87), // 150 degrees angle direction
          end: Alignment(0.5, 0.87),
          colors: [
            Color(0xFF4A8E27),
            Color(0xFF0A0B0A),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          color: Colors.white.withValues(alpha: 0.8),
          size: iconSize,
        ),
      ),
    );
  }
}
