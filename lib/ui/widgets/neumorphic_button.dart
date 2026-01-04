import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class SoftGlassButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double size;
  final Color baseColor;
  final Color glassColor;
  final String? semanticLabel;
  final bool enabled;
  final double borderRadius;
  final double blurIntensity;
  final Duration animationDuration;

  const SoftGlassButton({
    super.key,
    required this.onTap,
    required this.child,
    this.size = 70,
    this.baseColor = const Color(0xFF0A0A0B),
    this.glassColor = const Color(0x20FFFFFF),
    this.semanticLabel,
    this.enabled = true,
    this.borderRadius = 24,
    this.blurIntensity = 8.0,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<SoftGlassButton> createState() => _SoftGlassButtonState();
}

class _SoftGlassButtonState extends State<SoftGlassButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _depthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _depthAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    _resetState();
    widget.onTap();
  }

  void _handleTapCancel() => _resetState();

  void _resetState() {
    if (mounted) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleHoverEnter(PointerEnterEvent event) {
    setState(() => _isHovered = true);
  }

  void _handleHoverExit(PointerExitEvent event) {
    setState(() => _isHovered = false);
  }

  List<BoxShadow> _buildShadows() {
    if (!widget.enabled) {
      return [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.1),
          offset: const Offset(2, 2),
          blurRadius: 4,
        ),
      ];
    }

    final intensity = _depthAnimation.value;
    return [
      // Soft outer shadow (main depth)
      BoxShadow(
        color: const Color(0xFF000000).withOpacity(0.4 * intensity),
        offset: Offset(8 * intensity, 8 * intensity),
        blurRadius: 16 * intensity,
        spreadRadius: -2,
      ),
      // Inner highlight
      BoxShadow(
        color: const Color(0xFFFFFFFF).withOpacity(0.1 * intensity),
        offset: Offset(-4 * intensity, -4 * intensity),
        blurRadius: 12 * intensity,
        spreadRadius: -1,
      ),
      // Ambient shadow
      BoxShadow(
        color: const Color(0xFF000000).withOpacity(0.2 * intensity),
        offset: Offset(0, 4 * intensity),
        blurRadius: 20 * intensity,
        spreadRadius: -4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: widget.enabled,
      child: MouseRegion(
        onEnter: _handleHoverEnter,
        onExit: _handleHoverExit,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                child: Container(
                  height: widget.size,
                  width: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    boxShadow: _buildShadows(),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: widget.blurIntensity,
                        sigmaY: widget.blurIntensity,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.baseColor.withOpacity(0.8),
                              widget.baseColor.withOpacity(0.6),
                            ],
                          ),
                          border: Border.all(
                            color: widget.glassColor.withOpacity(
                              _isHovered ? 0.3 : 0.2,
                            ),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                        ),
                        child: Stack(
                          children: [
                            // Glassmorphic overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    widget.glassColor.withOpacity(0.15),
                                    widget.glassColor.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(widget.borderRadius),
                              ),
                            ),
                            // Glow effect when pressed
                            if (_glowAnimation.value > 0)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 1.0,
                                    colors: [
                                      const Color(0xFFFFFFFF).withOpacity(
                                        0.1 * _glowAnimation.value,
                                      ),
                                      const Color(0x00FFFFFF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(widget.borderRadius),
                                ),
                              ),
                            // Content
                            Center(
                              child: AnimatedOpacity(
                                opacity: widget.enabled ? 1.0 : 0.4,
                                duration: widget.animationDuration,
                                child: widget.child,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Music app specific buttons with soft UI design
class LugmaticOnboardingButtons extends StatelessWidget {
  const LugmaticOnboardingButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main play button - larger with music-focused styling
        SoftGlassButton(
          onTap: () => print('Start music journey'),
          semanticLabel: 'Start your music journey',
          size: 88,
          baseColor: const Color(0xFF0F0F23),
          glassColor: const Color(0xFF6366F1),
          borderRadius: 28,
          child: const Icon(
            CupertinoIcons.play_fill,
            color: Color(0xFF8B5CF6),
            size: 36,
          ),
        ),
        
        const SizedBox(height: 32),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Live feed button
            SoftGlassButton(
              onTap: () => print('View live artist feed'),
              semanticLabel: 'Live artist updates',
              size: 72,
              baseColor: const Color(0xFF1A0B2E),
              glassColor: const Color(0xFFEC4899),
              borderRadius: 22,
              child: const Icon(
                CupertinoIcons.dot_radiowaves_left_right,
                color: Color(0xFFF472B6),
                size: 28,
              ),
            ),
            
            // Discover button
            SoftGlassButton(
              onTap: () => print('Discover music'),
              semanticLabel: 'Discover new music',
              size: 72,
              baseColor: const Color(0xFF0B1A2E),
              glassColor: const Color(0xFF06B6D4),
              borderRadius: 22,
              child: const Icon(
                CupertinoIcons.music_note_2,
                color: Color(0xFF22D3EE),
                size: 28,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Continue button
        SoftGlassButton(
          onTap: () => print('Continue to app'),
          semanticLabel: 'Continue to main app',
          size: 64,
          baseColor: const Color(0xFF064E3B),
          glassColor: const Color(0xFF10B981),
          borderRadius: 20,
          child: const Icon(
            CupertinoIcons.arrow_right,
            color: Color(0xFF34D399),
            size: 24,
          ),
        ),
      ],
    );
  }
}