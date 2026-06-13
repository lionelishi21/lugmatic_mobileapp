import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../utils/onboarding_data.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _currentPage = i);
    _fadeCtrl.forward(from: 0);
  }

  void _next() {
    if (_currentPage < OnboardingData.items.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: _onPageChanged,
            itemCount: OnboardingData.items.length,
            itemBuilder: (_, i) => OnboardingPage(
              item: OnboardingData.items[i],
              animation: _fadeAnim,
            ),
          ),

          // Skip button
          Positioned(
            top: 0,
            right: 16,
            child: SafeArea(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Skip',
                    style: TextStyle(
                        color: AppColors.mutedForeground, fontSize: 16)),
              ),
            ),
          ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        OnboardingData.items.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == i
                                ? AppColors.primaryGreen
                                : AppColors.surface10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // CTA button
                    GestureDetector(
                      onTap: _next,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == OnboardingData.items.length - 1
                                  ? 'Get Started'
                                  : 'Continue',
                              style: const TextStyle(
                                color: AppColors.background,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward_rounded,
                                color: AppColors.background, size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Legal
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text('By continuing, you agree to our ',
                            style: TextStyle(
                                color: AppColors.greyLight.withOpacity(0.8),
                                fontSize: 12)),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/terms'),
                          child: const Text('Terms',
                              style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Text(' and ',
                            style: TextStyle(
                                color: AppColors.greyLight.withOpacity(0.8),
                                fontSize: 12)),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/privacy'),
                          child: const Text('Privacy Policy',
                              style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
