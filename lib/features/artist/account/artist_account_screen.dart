import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/neumorphic_theme.dart';
import '../../../data/providers/auth_provider.dart';
import 'profile_editor_screen.dart';
import 'payout_settings_screen.dart';
import 'support_screen.dart';
import '../../home/presentation/pages/notifications_page.dart';

class ArtistAccountScreen extends StatelessWidget {
  const ArtistAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          final displayName = user != null
              ? '${user.firstName} ${user.lastName}'.trim()
              : 'Artist';

          return Container(
            height: double.infinity,
            decoration: BoxDecoration(gradient: AppColors.screenGradient),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Profile card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: NeumorphicTheme.neumorphicDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.card,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        backgroundImage: user?.profilePicture != null
                            ? NetworkImage(user!.profilePicture!)
                            : null,
                        child: user?.profilePicture == null
                            ? const Icon(Icons.person, color: AppColors.primary, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName.isEmpty ? 'Artist' : displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 13,
                              ),
                            ),
                            if (user?.isArtist == true) ...[
                              const SizedBox(height: 6),
                              const Row(
                                children: [
                                  Icon(Icons.verified, color: AppColors.primary, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Artist',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                _buildMenuItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileEditorScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.payments_outlined,
                  label: 'Payout & Verification',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PayoutSettingsScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  ),
                ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.card,
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout',
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await context.read<AuthProvider>().logout();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.redAccent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Logout',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }



  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.card,
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.mutedForeground),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
