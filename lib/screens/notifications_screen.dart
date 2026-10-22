import 'package:chanolite/managers/notification_manager.dart';
import 'package:chanolite/models/notification_model.dart';
import 'package:chanolite/screens/article_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Full-page notifications screen that lists all user notifications with
/// support for marking as read, deleting (individually or all), and
/// navigating to related content.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Reload notifications whenever the screen is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationManager>().loadNotifications();
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns a relative time string in Thai (e.g. "2 ชั่วโมงที่แล้ว").
  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'เมื่อกี้';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} วันที่แล้ว';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks สัปดาห์ที่แล้ว';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months เดือนที่แล้ว';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years ปีที่แล้ว';
    }
  }

  /// Returns an appropriate icon for a given [NotificationType].
  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.NEW_ARTICLE:
        return Icons.article;
      case NotificationType.NEW_COMMENT:
        return Icons.comment;
      case NotificationType.REPLY_COMMENT:
        return Icons.reply;
      case NotificationType.PUBLISH_REQUEST_UPDATE:
        return Icons.approval;
      case NotificationType.MOD_UPDATE:
        return Icons.update;
      case NotificationType.MODERATION_UPDATE:
        return Icons.gavel;
      case NotificationType.FAVORITE_ARTICLE:
        return Icons.favorite;
      case NotificationType.TRANSLATION_UPDATE:
      case NotificationType.TRANSLATION_QUEUE_NEW:
      case NotificationType.TRANSLATION_QUEUE_UPDATE:
      case NotificationType.TRANSLATION_QUEUE_COMPLETED:
      case NotificationType.TRANSLATION_QUEUE_FAILED:
        return Icons.translate;
    }
  }

  /// Navigates to the relevant screen based on notification entity data.
  void _handleNotificationTap(
    BuildContext context,
    NotificationResponse notification,
    NotificationManager manager,
  ) {
    if (!notification.isRead) {
      manager.markAsRead(notification.id);
    }

    final entityType = notification.entityType;
    final entityId = notification.entityId;

    if (entityType == 'article' && entityId != null) {
      final id = int.tryParse(entityId);
      if (id != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(articleId: id),
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          // Mark all as read
          Consumer<NotificationManager>(
            builder: (context, manager, _) => IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'อ่านทั้งหมด',
              onPressed: manager.notifications.isEmpty
                  ? null
                  : () => manager.markAllAsRead(),
            ),
          ),
          // Delete all
          Consumer<NotificationManager>(
            builder: (context, manager, _) => IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'ลบทั้งหมด',
              onPressed: manager.notifications.isEmpty
                  ? null
                  : () => _confirmDeleteAll(context, manager),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationManager>(
        builder: (context, manager, _) {
          if (manager.isLoading) {
            return _buildSkeleton(context);
          }

          if (manager.error != null && manager.notifications.isEmpty) {
            return _buildError(context, manager);
          }

          if (manager.notifications.isEmpty) {
            return _buildEmpty(context);
          }

          return _buildList(context, manager);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading skeleton
  // ---------------------------------------------------------------------------

  Widget _buildSkeleton(BuildContext context) {
    final dummyItems = List.generate(
      8,
      (i) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.notifications)),
        title: const Text('กำลังโหลดการแจ้งเตือน...'),
        subtitle: const Text('2 ชั่วโมงที่แล้ว'),
      ),
    );

    return Skeletonizer(
      enabled: true,
      child: ListView(
        children: dummyItems,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, NotificationManager manager) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'เกิดข้อผิดพลาด: ${manager.error}',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: manager.loadNotifications,
            child: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 72,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือน',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'การแจ้งเตือนของคุณจะปรากฏที่นี่',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification list
  // ---------------------------------------------------------------------------

  Widget _buildList(BuildContext context, NotificationManager manager) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: manager.loadNotifications,
      child: ListView.builder(
        itemCount: manager.notifications.length,
        itemBuilder: (context, index) {
          final notification = manager.notifications[index];
          final isUnread = !notification.isRead;

          return Dismissible(
            key: ValueKey(notification.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => manager.deleteNotification(notification.id),
            child: ListTile(
              tileColor: isUnread
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : null,
              leading: CircleAvatar(
                backgroundColor: isUnread
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: isUnread
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                child: Icon(_iconForType(notification.type)),
              ),
              title: Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight:
                      isUnread ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: Text(_relativeTime(notification.createdAt)),
              trailing: isUnread
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              onTap: () =>
                  _handleNotificationTap(context, notification, manager),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Confirmation dialog for delete all
  // ---------------------------------------------------------------------------

  Future<void> _confirmDeleteAll(
    BuildContext context,
    NotificationManager manager,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบการแจ้งเตือนทั้งหมด?'),
        content: const Text('การกระทำนี้ไม่สามารถยกเลิกได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await manager.deleteAll();
    }
  }
}
