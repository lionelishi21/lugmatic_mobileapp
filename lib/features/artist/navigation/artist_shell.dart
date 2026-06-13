import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/section_provider.dart';
import '../dashboard/artist_dashboard_screen.dart';
import '../tracks/artist_tracks_screen.dart';
import '../live/artist_live_screen.dart';
import '../clashes/artist_clashes_screen.dart';
import '../messages/artist_messages_screen.dart';
import '../account/artist_account_screen.dart';

/// Artist section shell — 6-tab bottom nav mirroring the retired lugmatic_artist_studio.
/// Tab order: Dashboard | Tracks | [LIVE centre] | Clashes | Messages | Account
class ArtistShell extends StatefulWidget {
  const ArtistShell({super.key});

  @override
  State<ArtistShell> createState() => _ArtistShellState();
}

class _ArtistShellState extends State<ArtistShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _liveGlowController;

  static const List<Widget> _screens = [
    ArtistDashboardScreen(),
    ArtistTracksScreen(),
    ArtistLiveScreen(),
    ArtistClashesScreen(),
    ArtistMessagesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _liveGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _liveGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionProvider = context.watch<SectionProvider>();
    final currentIndex =
        sectionProvider.artistTabIndex.clamp(0, _screens.length - 1);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFF0A0A12),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _ArtistBottomNav(
        currentIndex: currentIndex,
        glowController: _liveGlowController,
        onTap: (i) => sectionProvider.setArtistTab(i),
      ),
    );
  }
}

class _ArtistBottomNav extends StatelessWidget {
  final int currentIndex;
  final AnimationController glowController;
  final ValueChanged<int> onTap;

  const _ArtistBottomNav({
    required this.currentIndex,
    required this.glowController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottom + 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A12),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _NavItem(
              icon: FontAwesomeIcons.chartLine,
              label: 'Dashboard',
              index: 0,
              current: currentIndex,
              onTap: onTap),
          _NavItem(
              icon: FontAwesomeIcons.music,
              label: 'Tracks',
              index: 1,
              current: currentIndex,
              onTap: onTap),
          _LiveButton(
            isActive: currentIndex == 2,
            glowController: glowController,
            onTap: () => onTap(2),
          ),
          _NavItem(
              icon: FontAwesomeIcons.fire,
              label: 'Clashes',
              index: 3,
              current: currentIndex,
              onTap: onTap),
          _NavItem(
              icon: Icons.message_outlined,
              label: 'Messages',
              index: 4,
              current: currentIndex,
              onTap: onTap,
              useRegularIcon: true,
              activeIcon: Icons.message),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  final bool useRegularIcon;
  final IconData? activeIcon;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.useRegularIcon = false,
    this.activeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    final resolvedIcon = (active && activeIcon != null) ? activeIcon! : icon;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: useRegularIcon
                  ? Icon(resolvedIcon,
                      size: 20,
                      color: active
                          ? AppColors.primary
                          : const Color(0xFF5A5A6E))
                  : FaIcon(icon,
                      size: 18,
                      color: active
                          ? AppColors.primary
                          : const Color(0xFF5A5A6E)),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    active ? FontWeight.bold : FontWeight.normal,
                color:
                    active ? AppColors.primary : const Color(0xFF5A5A6E),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveButton extends StatelessWidget {
  final bool isActive;
  final AnimationController glowController;
  final VoidCallback onTap;

  const _LiveButton({
    required this.isActive,
    required this.glowController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: glowController,
              builder: (_, __) {
                final glow = isActive ? 12.0 : 0.0;
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDim],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: glow,
                        spreadRadius: glow / 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    FontAwesomeIcons.video,
                    color: Colors.black,
                    size: 22,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Go Live',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.primary : const Color(0xFF5A5A6E),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
