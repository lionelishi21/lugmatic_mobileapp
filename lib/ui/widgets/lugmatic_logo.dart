import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LogoVariant { full, icon, stacked }

class LugmaticLogo extends StatefulWidget {
  final LogoVariant variant;
  final bool hideSubtitle;
  final double scale;
  final bool isLight;

  const LugmaticLogo({
    Key? key,
    this.variant = LogoVariant.full,
    this.hideSubtitle = false,
    this.scale = 1.0,
    this.isLight = false,
  }) : super(key: key);

  @override
  State<LugmaticLogo> createState() => _LugmaticLogoState();
}

class _LugmaticLogoState extends State<LugmaticLogo> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  final List<double> _barHeights = [18.0, 34.0, 26.0, 14.0, 30.0, 20.0, 10.0];
  final List<Duration> _durations = [
    const Duration(milliseconds: 550),
    const Duration(milliseconds: 450),
    const Duration(milliseconds: 650),
    const Duration(milliseconds: 400),
    const Duration(milliseconds: 600),
    const Duration(milliseconds: 500),
    const Duration(milliseconds: 700),
  ];

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(7, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: _durations[index],
      );
      // add a small random delay before repeating
      Future.delayed(Duration(milliseconds: Random().nextInt(500)), () {
        if (mounted) controller.repeat(reverse: true);
      });
      return controller;
    });

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _floatController.dispose();
    super.dispose();
  }

  Widget _buildIcon(double size) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            width: size,
            height: size,
            decoration: widget.isLight
                ? null
                : BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6EC820).withOpacity(0.8),
                        blurRadius: 12,
                        spreadRadius: 0,
                      )
                    ],
                    shape: BoxShape.circle,
                  ),
            child: Image.asset(
              'assets/images/iriewave.png',
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBars({int count = 7, double maxHeightScale = 1.0}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              final minHeight = _barHeights[index] * 0.3;
              final height = minHeight + (_controllers[index].value * (_barHeights[index] - minHeight));
              return Container(
                width: 4.0,
                height: height * maxHeightScale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.0),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.isLight
                        ? [const Color(0xFF3D8000), const Color(0xFF6EC800)]
                        : [const Color(0xFFB8FF47), const Color(0xFF6EC800)],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildTextPart({bool stacked = false}) {
    final textColor = widget.isLight ? const Color(0xFF0d1f04) : Colors.white;
    return Column(
      crossAxisAlignment: stacked ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stacked)
          Text(
            'LUGMATIC',
            style: GoogleFonts.unbounded(
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1.0,
              letterSpacing: -0.02 * 26,
              color: textColor,
            ),
          ),
        if (stacked)
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6EC800), Color(0xFFB8FF47)],
            ).createShader(bounds),
            child: Text(
              'MUSIC',
              style: GoogleFonts.unbounded(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.4 * 11,
                color: Colors.white,
              ),
            ),
          ),
        if (!stacked)
          RichText(
            text: TextSpan(
              style: GoogleFonts.unbounded(
                fontWeight: FontWeight.w800,
                fontSize: 38,
                height: 1.0,
                letterSpacing: -0.02 * 38,
                color: textColor,
              ),
              children: [
                const TextSpan(text: 'Lugmatic'),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: widget.isLight
                          ? [const Color(0xFF3D8000), const Color(0xFF6EC800)]
                          : [const Color(0xFF6EC800), const Color(0xFFB8FF47)],
                    ).createShader(bounds),
                    child: Text(
                      'Music',
                      style: GoogleFonts.unbounded(
                        fontWeight: FontWeight.w800,
                        fontSize: 38,
                        height: 1.0,
                        letterSpacing: -0.02 * 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!widget.hideSubtitle && !stacked)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(
              'STREAM EVERY FREQUENCY',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w300,
                fontSize: 10,
                letterSpacing: 0.28 * 10,
                color: widget.isLight ? const Color(0x550d1f04) : Colors.white.withOpacity(0.4),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.variant == LogoVariant.icon) {
      content = _buildIcon(64);
    } else if (widget.variant == LogoVariant.stacked) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(80),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: _buildBars(count: 5, maxHeightScale: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextPart(stacked: true),
        ],
      );
    } else {
      // Full
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(64),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: _buildBars(count: 7),
              ),
            ],
          ),
          const SizedBox(width: 20),
          _buildTextPart(stacked: false),
        ],
      );
    }

    if (widget.scale != 1.0) {
      return Transform.scale(
        scale: widget.scale,
        alignment: Alignment.centerLeft,
        child: content,
      );
    }
    return content;
  }
}
