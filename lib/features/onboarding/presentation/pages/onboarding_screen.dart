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
        vsync: this, duration: const Duration(milliseconds: 500));

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
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == OnboardingData.items.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — wordmark, segmented progress, skip
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'lugmatic',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: Text('Skip',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(OnboardingData.items.length, (i) {
                      final active = i <= _currentPage;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                              right: i == OnboardingData.items.length - 1 ? 0 : 6),
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: active
                                ? AppColors.primaryGreen
                                : Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Pages — PageView's native horizontal slide is the "Glide" transition
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: _onPageChanged,
                itemCount: OnboardingData.items.length,
                itemBuilder: (_, i) => OnboardingPage(
                  item: OnboardingData.items[i],
                  animation: _fadeAnim,
                ),
              ),
            ),

            // Bottom bar — back chevron + Next/Get Started
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: _back,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.chevron_left_rounded,
                            color: Colors.white, size: 26),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _next,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: isLastPage ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                          border: isLastPage
                              ? null
                              : Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.5)),
                          boxShadow: isLastPage
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryGreen.withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastPage ? 'Get Started' : 'Next',
                              style: TextStyle(
                                color: isLastPage ? AppColors.background : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: isLastPage ? AppColors.background : Colors.white,
                                size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Legal
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text('By continuing, you agree to our ',
                      style: TextStyle(
                          color: AppColors.greyLight.withValues(alpha: 0.8),
                          fontSize: 12)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/terms'),
                    child: const Text('Terms',
                        style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  Text(' and ',
                      style: TextStyle(
                          color: AppColors.greyLight.withValues(alpha: 0.8),
                          fontSize: 12)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/privacy'),
                    child: const Text('Privacy Policy',
                        style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
