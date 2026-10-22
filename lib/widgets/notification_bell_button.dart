import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/notification_manager.dart';
import 'package:chanolite/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// AppBar action widget that shows a notification bell icon with an unread
/// badge count. Navigates to [NotificationsScreen] on tap.
///
/// Only renders if the current user is authenticated.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthManager>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const SizedBox.shrink();
        }

        return Consumer<NotificationManager>(
          builder: (context, notificationManager, _) {
            final unreadCount = notificationManager.unreadCount;
            final hasUnread = unreadCount > 0;

            return IconButton(
              tooltip: 'การแจ้งเตือน',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    hasUnread
                        ? Icons.notifications
                        : Icons.notifications_outlined,
                  ),
                  if (hasUnread)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
