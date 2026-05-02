import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _scaleCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  int _currentPage = 0;

  final List<_Step> _steps = [
    _Step(
      emoji: '🎵',
      title: 'WELCOME TO\nLUGMATIC',
      subtitle: 'Your ultimate music experience',
      description:
          'Discover, stream, and connect with your favourite artists — all in one place.',
      accentColor: AppColors.primary,
    ),
    _Step(
      emoji: '📡',
      title: 'LIVE STREAMS\n& ARTISTS',
      subtitle: 'Watch artists perform live',
      description:
          'Experience real-time performances and connect directly with the musicians you love.',
      accentColor: AppColors.primary,
    ),
    _Step(
      emoji: '🎁',
      title: 'SEND GIFTS\n& SUPPORT',
      subtitle: 'Back your favourite artists',
      description:
          'Show your love by sending gifts and supporting the artists who move you.',
      accentColor: AppColors.primary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _fadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _scaleCtrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut));
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut));
    _fadeCtrl.forward();
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _steps.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentPage];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(gradient: AppColors.screenGradient),
          ),

          // Purple radial glow at top
          Positioned(
            top: -160,
            left: -80,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.secondary.withOpacity(0.20),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Green glow bottom right
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Page view
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              _fadeCtrl.forward(from: 0);
              _scaleCtrl.forward(from: 0);
            },
            itemCount: _steps.length,
            itemBuilder: (ctx, i) => _buildPage(_steps[i]),
          ),

          // Skip
          Positioned(
            top: 56,
            right: 24,
            child: SafeArea(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                      color: AppColors.mutedForeground, fontSize: 14),
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.surface10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CTA button
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _steps.length - 1
                                ? 'Get Started'
                                : 'Continue',
                            style: const TextStyle(
                              color: AppColors.background,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.background,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'By continuing, you agree to our ',
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/terms'),
                        child: Text(
                          'Terms',
                          style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        ' and ',
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/privacy'),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_Step step) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Illustration — glass circle with glow
            FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.primary.withOpacity(0.12),
                      AppColors.secondary.withOpacity(0.08),
                      Colors.transparent,
                    ]),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Main image
                          Image.asset(
                            'assets/images/onboarding_guy.png',
                            fit: BoxFit.cover,
                            width: 260,
                            height: 260,
                            errorBuilder: (ctx, e, st) => Center(
                              child: Text(
                                step.emoji,
                                style:
                                    const TextStyle(fontSize: 80),
                              ),
                            ),
                          ),

                          // Bottom gradient overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 80,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.background
                                        .withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 1),

            // Text content
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // Display title — Bebas Neue style (all caps, heavy)
                  Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle in brand green
                  Text(
                    step.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    step.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

class _Step {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final Color accentColor;

  const _Step({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
  });
}
