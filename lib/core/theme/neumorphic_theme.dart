import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Design tokens aligned with lugmatic-music (staging-setup):
/// Dark backgrounds, glass cards, brand-green primary, purple secondary glow.
class NeumorphicTheme {
  // ── Surfaces ──────────────────────────────────────────────────
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.card;
  static const Color cardColor = AppColors.card;

  // ── Accents ───────────────────────────────────────────────────
  static const Color primaryAccent = AppColors.primary;
  static const Color secondaryAccent = AppColors.secondary;
  static const Color accentGradientStart = AppColors.primary;
  static const Color accentGradientEnd = AppColors.secondary;

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary = AppColors.foreground;
  static const Color textSecondary = AppColors.mutedForeground;
  static const Color textTertiary = Color(0xFF6B6B7A);
  static const Color textOnCard = AppColors.foreground;
  static const Color textOnCardMuted = AppColors.mutedForeground;

  // ── Shadows ───────────────────────────────────────────────────
  static const Color lightShadow = Color(0x0DFFFFFF);
  static const Color darkShadow = Color(0x99000000);

  // ─────────────────────────────────────────────────────────────
  // Decorations
  // ─────────────────────────────────────────────────────────────

  /// Glass card decoration — dark glassmorphism matching .glass CSS
  static BoxDecoration cardDecoration({
    BorderRadius? borderRadius,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.glassBg,
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      border: Border.all(color: AppColors.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ],
    );
  }

  /// Legacy neumorphic — now maps to dark card
  static BoxDecoration neumorphicDecoration({
    Color? color,
    BorderRadius? borderRadius,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: Border.all(color: AppColors.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isPressed ? 0.2 : 0.4),
          blurRadius: isPressed ? 6 : 16,
          offset: Offset(0, isPressed ? 2 : 8),
        ),
      ],
    );
  }

  static BoxDecoration flatNeumorphicDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: Border.all(color: AppColors.border, width: 1),
    );
  }

  static BoxDecoration concaveNeumorphicDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.muted,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: Border.all(color: AppColors.border, width: 1),
    );
  }

  /// Green primary button — solid brand-green matching web bg-primary
  static BoxDecoration gradientNeumorphicDecoration({
    List<Color>? gradientColors,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: AppColors.primary,
      borderRadius: borderRadius ?? BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Input decoration matching web: bg-white/5 border-white/10
  static InputDecoration cardInputDecoration({
    required String label,
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: AppColors.mutedForeground,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        color: AppColors.mutedForeground,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.mutedForeground, size: 18)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.input,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.destructive, width: 1.5),
      ),
    );
  }

  static InputDecoration neumorphicInputDecoration({
    required String label,
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) =>
      cardInputDecoration(
          label: label,
          hint: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon);
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool isGradient;
  final List<Color>? gradientColors;

  const NeumorphicButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.color,
    this.isGradient = false,
    this.gradientColors,
  }) : super(key: key);

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          height: widget.height ?? 56,
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: widget.isGradient
              ? NeumorphicTheme.gradientNeumorphicDecoration(
                  gradientColors: widget.gradientColors,
                  borderRadius: widget.borderRadius,
                )
              : NeumorphicTheme.neumorphicDecoration(
                  color: widget.color,
                  borderRadius: widget.borderRadius,
                  isPressed: _pressed,
                ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  const NeumorphicCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: NeumorphicTheme.cardDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool isConcave;

  const NeumorphicContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.color,
    this.isConcave = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: isConcave
          ? NeumorphicTheme.concaveNeumorphicDecoration(
              color: color,
              borderRadius: borderRadius,
            )
          : NeumorphicTheme.flatNeumorphicDecoration(
              color: color,
              borderRadius: borderRadius,
            ),
      child: child,
    );
  }
}
