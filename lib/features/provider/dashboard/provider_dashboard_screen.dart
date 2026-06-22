import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final name = auth.user?.fullName ?? 'Provider';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.background,
                pinned: true,
                elevation: 0,
                toolbarHeight: 70,
                automaticallyImplyLeading: false,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF6366F1),
                          ),
                          child: const Icon(Icons.business_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Provider',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats row
                    Row(
                      children: [
                        _StatCard(
                          icon: Icons.storefront_rounded,
                          label: 'Spaces',
                          value: '—',
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.calendar_today_rounded,
                          label: 'Bookings',
                          value: '—',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.attach_money_rounded,
                          label: 'Revenue',
                          value: '\$0',
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Coming soon banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded,
                                  color: Color(0xFF6366F1), size: 20),
                              const SizedBox(width: 10),
                              const Text(
                                'Provider Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Manage your studio spaces and bookings. '
                            'Full provider management is available on the web at '
                            'lugmaticmusic.com/studio/services.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
