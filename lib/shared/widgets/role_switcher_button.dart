import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/section_provider.dart';
import '../../features/artist/navigation/artist_shell.dart';

/// Floating chip shown when the user has multiple roles.
/// Tapping it pushes ArtistShell as a full-screen route.
/// Place this in the fan HomePage scaffold (e.g. floating near the bottom).
class RoleSwitcherButton extends StatelessWidget {
  const RoleSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) return const SizedBox.shrink();

    final hasArtist = auth.hasArtistRole;
    final hasContributor = auth.hasContributorRole;
    if (!hasArtist && !hasContributor) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasArtist)
            _RoleChip(
              label: 'Artist Mode',
              icon: Icons.mic_rounded,
              color: AppColors.primary,
              onTap: () {
                context.read<SectionProvider>().switchTo(AppSection.artist);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: false,
                    builder: (_) => const ArtistShell(),
                  ),
                );
              },
            ),
          if (hasArtist && hasContributor) const SizedBox(width: 8),
          if (hasContributor)
            _RoleChip(
              label: 'Contributor',
              icon: Icons.piano_rounded,
              color: AppColors.secondary,
              onTap: () {
                // Contributor shell — to be wired up when implemented
              },
            ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
