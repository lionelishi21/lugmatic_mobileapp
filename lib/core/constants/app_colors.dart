import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color darkBackground = Color(0xFF111827);
  static const Color white = Colors.white;
  static const Color greyLight = Color(0xFFD1D5DB);
  static const Color greyDark = Color(0xFF6B7280);
  static const Color black = Colors.black;
  
  // Gradient colors
  static const List<Color> backgroundGradient = [
    Colors.transparent,
    Color(0x80111827),
    Color(0xFF111827),
  ];
  
  static const List<double> gradientStops = [0.0, 0.6, 1.0];
}