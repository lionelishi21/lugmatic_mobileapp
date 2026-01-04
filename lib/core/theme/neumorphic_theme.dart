import 'package:flutter/material.dart';

class NeumorphicTheme {
  // Base colors for dark neumorphic theme
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color surfaceColor = Color(0xFF16213E);
  static const Color cardColor = Color(0xFF0F3460);
  
  // Accent colors
  static const Color primaryAccent = Color(0xFF10B981);
  static const Color secondaryAccent = Color(0xFF00F5FF);
  static const Color accentGradientStart = Color(0xFF10B981);
  static const Color accentGradientEnd = Color(0xFF059669);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8D1);
  static const Color textTertiary = Color(0xFF78789D);
  
  // Shadow colors
  static const Color lightShadow = Color(0xFF2A2A3E);
  static const Color darkShadow = Color(0xFF0A0A1E);
  
  // Standard neumorphic decoration for raised elements
  static BoxDecoration neumorphicDecoration({
    Color? color,
    BorderRadius? borderRadius,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      boxShadow: isPressed
          ? [
              // Pressed state - smaller shadows
              BoxShadow(
                color: darkShadow.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: lightShadow.withOpacity(0.02),
                offset: const Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ]
          : [
              // Outer shadows for raised state
              BoxShadow(
                color: darkShadow.withOpacity(0.5),
                offset: const Offset(8, 8),
                blurRadius: 16,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: lightShadow.withOpacity(0.05),
                offset: const Offset(-8, -8),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
    );
  }
  
  // Flat neumorphic decoration
  static BoxDecoration flatNeumorphicDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: darkShadow.withOpacity(0.3),
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: lightShadow.withOpacity(0.05),
          offset: const Offset(-4, -4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ],
    );
  }
  
  // Concave/inset neumorphic decoration
  static BoxDecoration concaveNeumorphicDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? backgroundColor,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: lightShadow.withOpacity(0.1),
          offset: const Offset(-4, -4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: darkShadow.withOpacity(0.5),
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ],
    );
  }
  
  // Gradient neumorphic decoration
  static BoxDecoration gradientNeumorphicDecoration({
    List<Color>? gradientColors,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors ?? [accentGradientStart, accentGradientEnd],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: (gradientColors?.first ?? accentGradientStart).withOpacity(0.5),
          offset: const Offset(8, 8),
          blurRadius: 24,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: lightShadow.withOpacity(0.05),
          offset: const Offset(-4, -4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ],
    );
  }
  
  // Input field neumorphic decoration
  static InputDecoration neumorphicInputDecoration({
    required String label,
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: textTertiary.withOpacity(0.5),
        fontSize: 14,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: primaryAccent, size: 20)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: surfaceColor.withOpacity(0.5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryAccent.withOpacity(0.5), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.red.withOpacity(0.5), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}

// Neumorphic Button Widget
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
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height ?? 56,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: widget.isGradient
            ? NeumorphicTheme.gradientNeumorphicDecoration(
                gradientColors: widget.gradientColors,
                borderRadius: widget.borderRadius,
              )
            : NeumorphicTheme.neumorphicDecoration(
                color: widget.color,
                borderRadius: widget.borderRadius,
                isPressed: _isPressed,
              ),
        child: Center(child: widget.child),
      ),
    );
  }
}

// Neumorphic Card Widget
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
        decoration: NeumorphicTheme.flatNeumorphicDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

// Neumorphic Container Widget
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

