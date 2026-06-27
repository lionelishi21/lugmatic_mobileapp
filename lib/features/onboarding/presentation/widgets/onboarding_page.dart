import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/onboarding_item.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final Animation<double> animation;

  const OnboardingPage({
    Key? key,
    required this.item,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildIcon(),
            const SizedBox(height: 28),
            _buildEyebrow(),
            const SizedBox(height: 12),
            _buildTitle(),
            const SizedBox(height: 14),
            _buildDescription(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        item.icon,
        size: 38,
        color: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildEyebrow() {
    return Text(
      item.eyebrow,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      item.title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      item.description,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
