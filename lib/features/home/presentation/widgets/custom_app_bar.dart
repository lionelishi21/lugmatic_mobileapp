import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onStoreTap;
  final VoidCallback? onLibraryTap;
  final VoidCallback? onExploreTap;
  final int unreadCount;
  final int unreadMessageCount;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onProfileTap,
    this.onNotificationTap,
    this.onMessageTap,
    this.onStoreTap,
    this.onLibraryTap,
    this.onExploreTap,
    this.unreadCount = 0,
    this.unreadMessageCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  if (onExploreTap != null || onStoreTap != null || onLibraryTap != null) ...[
                    _OverflowMenu(
                      onExploreTap: onExploreTap,
                      onStoreTap: onStoreTap,
                      onLibraryTap: onLibraryTap,
                    ),
                    const SizedBox(width: 12),
                  ],
                  GestureDetector(
                    onTap: onNotificationTap,
                    child: Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onMessageTap,
                    child: Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mail_outline,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        if (unreadMessageCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                unreadMessageCount > 9 ? '9+' : '$unreadMessageCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(4, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

/// Collapses the lower-frequency actions (Explore, Store, Library) behind a
/// single overflow icon, instead of showing every action inline — the app
/// bar was showing up to 6 icons at once (crowded on narrower phones).
/// Notifications/Messages/Profile stay directly visible since they carry
/// unread badges and are tapped far more often.
class _OverflowMenu extends StatelessWidget {
  final VoidCallback? onExploreTap;
  final VoidCallback? onStoreTap;
  final VoidCallback? onLibraryTap;

  const _OverflowMenu({this.onExploreTap, this.onStoreTap, this.onLibraryTap});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (callback) => callback(),
      itemBuilder: (context) => [
        if (onExploreTap != null)
          PopupMenuItem(
            value: onExploreTap,
            child: const Row(children: [
              Icon(Icons.explore_outlined, color: Colors.white70, size: 18),
              SizedBox(width: 12),
              Text('Explore', style: TextStyle(color: Colors.white)),
            ]),
          ),
        if (onStoreTap != null)
          PopupMenuItem(
            value: onStoreTap,
            child: const Row(children: [
              Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
              SizedBox(width: 12),
              Text('Get Coins', style: TextStyle(color: Colors.white)),
            ]),
          ),
        if (onLibraryTap != null)
          PopupMenuItem(
            value: onLibraryTap,
            child: const Row(children: [
              Icon(Icons.library_music_outlined, color: Colors.white70, size: 18),
              SizedBox(width: 12),
              Text('Library', style: TextStyle(color: Colors.white)),
            ]),
          ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
      ),
    );
  }
}