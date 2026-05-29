import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../dashboard/contributor_dashboard_screen.dart';
import '../payout/contributor_payout_screen.dart';
import '../terms/contributor_terms_screen.dart';

class ContributorShell extends StatefulWidget {
  const ContributorShell({super.key});

  @override
  State<ContributorShell> createState() => _ContributorShellState();
}

class _ContributorShellState extends State<ContributorShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ContributorDashboardScreen(),
    const ContributorPayoutScreen(),
    const ContributorTermsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A12),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: FontAwesomeIcons.chartPie,
                  label: 'Dashboard',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.payments_outlined,
                  label: 'Payouts',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.description_outlined,
                  label: 'Terms',
                  index: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final active = _currentIndex == index;
    final color = active ? AppColors.secondary : const Color(0xFF5A5A6E);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.secondary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
