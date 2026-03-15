import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF10B981); // Emerald 500
  static const Color darkBackground = Color(0xFF0F172A); // Matching web app dark
  static const Color cardBackground = Color(0xFF1E293B);
  static const Color white = Colors.white;
  static const Color greyLight = Color(0xFFD1D5DB);
  static const Color greyDark = Color(0xFF6B7280);
  static const Color black = Colors.black;
  
  // Brand specific colors matching web app
  static const Color brandGreen = Color(0xFF10B981);
  static const Color brandSecondary = Color(0xFF7C3AED); // Matching web app secondary
  
  // Gradient colors
  static const List<Color> backgroundGradient = [
    Colors.transparent,
    Color(0x800F172A),
    Color(0xFF0F172A),
  ];
  
  static const List<double> gradientStops = [0.0, 0.6, 1.0];
}