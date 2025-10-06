
enum NotificationType {
  NEW_ARTICLE,
  NEW_COMMENT,
  REPLY_COMMENT,
  PUBLISH_REQUEST_UPDATE,
  MOD_UPDATE,
  TRANSLATION_UPDATE,
  FAVORITE_ARTICLE,
  MODERATION_UPDATE,
  TRANSLATION_QUEUE_NEW,
  TRANSLATION_QUEUE_UPDATE,
  TRANSLATION_QUEUE_COMPLETED,
  TRANSLATION_QUEUE_FAILED
}

class NotificationResponse {
  final int id;
  final int userId;
  final NotificationType type;
  final String message;
  final bool isRead;
  final dynamic entityId;
  final dynamic entityType;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationResponse({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.isRead,
    this.entityId,
    this.entityType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      id: json['id'],
      userId: json['userId'],
      type: NotificationType.values.firstWhere((e) => e.toString() == 'NotificationType.${json['type']}'),
      message: json['message'],
      isRead: json['isRead'],
      entityId: json['entityId'],
      entityType: json['entityType'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class MultipleNotificationsResponse {
  final List<NotificationResponse> notifications;
  final int notificationsCount;
  final int unreadCount;

  MultipleNotificationsResponse({
    required this.notifications,
    required this.notificationsCount,
    required this.unreadCount,
  });

  factory MultipleNotificationsResponse.fromJson(Map<String, dynamic> json) {
    return MultipleNotificationsResponse(
      notifications: (json['notifications'] as List)
          .map((notification) => NotificationResponse.fromJson(notification))
          .toList(),
      notificationsCount: json['notificationsCount'],
      unreadCount: json['unreadCount'],
    );
  }
}

class SingleNotificationResponse {
  final NotificationResponse notification;

  SingleNotificationResponse({required this.notification});

  factory SingleNotificationResponse.fromJson(Map<String, dynamic> json) {
    return SingleNotificationResponse(
      notification: NotificationResponse.fromJson(json['notification']),
    );
  }
}
