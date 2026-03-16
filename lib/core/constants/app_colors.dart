import 'package:flutter/material.dart';

/// Design tokens extracted directly from lugmatic-music (staging-setup branch).
/// CSS source: src/app/globals.css
///
/// --background:  oklch(0.08 0.01 270)  → #0E0E15 near-black
/// --card:        oklch(0.12 0.01 270)  → #16161F dark card
/// --primary:     oklch(0.75 0.2 145)   → #86E560 vibrant lime-green
/// --secondary:   oklch(0.45 0.18 300)  → #7B3FAF purple accent
/// --muted:       oklch(0.2 0.01 270)   → #27272F
/// --muted-fg:    oklch(0.65 0 0)       → #A6A6A6
/// Fonts: DM Sans (body), Bebas Neue (display/headings)
class AppColors {
  // ── Core backgrounds ──────────────────────────────────────────
  static const Color background = Color(0xFF0E0E15);
  static const Color card = Color(0xFF16161F);
  static const Color muted = Color(0xFF27272F);
  static const Color sidebar = Color(0xFF0F0F16);

  // ── Brand green (primary) ─────────────────────────────────────
  static const Color primary = Color(0xFF86E560);
  static const Color primaryDim = Color(0xFF5EC43A);
  static const Color primaryDeep = Color(0xFF3A8A22);

  // ── Purple accent (secondary) ─────────────────────────────────
  static const Color secondary = Color(0xFF7B3FAF);
  static const Color secondaryDim = Color(0xFF5C2E85);

  // ── Text ──────────────────────────────────────────────────────
  static const Color foreground = Color(0xFFF9F9FC);
  static const Color mutedForeground = Color(0xFFA6A6A6);
  static const Color white = Colors.white;

  // ── Border / input ────────────────────────────────────────────
  static const Color border = Color(0x1FFFFFFF);    // white/12%
  static const Color input = Color(0x26FFFFFF);     // white/15%
  static const Color surfaceSubtle = Color(0x0DFFFFFF); // white/5%
  static const Color surface10 = Color(0x1AFFFFFF); // white/10%

  // ── Status ────────────────────────────────────────────────────
  static const Color destructive = Color(0xFFE05252);
  static const Color error = Color(0xFFE05252);
  static const Color success = primary;

  // ── Glass surface (.glass CSS class) ─────────────────────────
  static const Color glassBg = Color(0xCC16161F); // card at 80%

  // ── Legacy aliases (backward compat with existing screens) ────
  static const Color darkBackground = background;
  static const Color cardBackground = card;
  static const Color cardBackgroundDark = card;
  static const Color surfaceLight = muted;
  static const Color textPrimary = foreground;
  static const Color textSecondary = Color(0xFFD4D4E0);
  static const Color textMuted = mutedForeground;
  static const Color textLight = Color(0xFF6B6B7A);
  static const Color primaryGreen = primary;
  static const Color primaryGreenLight = Color(0xFFA3F075);
  static const Color limeGreen = primary;
  static const Color deepGreen = primaryDeep;
  static const Color emeraldDark = primaryDeep;
  static const Color btnGradientStart = primary;
  static const Color btnGradientMid = primary;
  static const Color btnGradientEnd = primaryDim;
  static const Color brandGreen = primary;
  static const Color brandSecondary = secondary;
  static const Color greyDark = mutedForeground;
  static const Color greyLight = Color(0xFF3A3A48);
  static const Color black = Colors.black;
  static const Color borderFocus = primary;
  static const Color errorLight = Color(0x33E05252);
  static const Color bgGradientStart = background;
  static const Color bgGradientMid = Color(0xFF0E1510);
  static const Color bgGradientEnd = background;
  static const List<Color> backgroundGradient = [background, Color(0xFF0E1510), background];
  static const List<double> gradientStops = [0.0, 0.5, 1.0];

  // ── Gradients ─────────────────────────────────────────────────

  /// Page background — near-black with faint green tint (matches web fixed orbs)
  static LinearGradient get screenGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [background, Color(0xFF0E1510), background],
        stops: [0.0, 0.5, 1.0],
      );

  /// Primary button — solid green matching web bg-primary
  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [primary, primaryDim],
      );
}
