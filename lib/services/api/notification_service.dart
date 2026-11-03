
import 'package:chanolite/models/notification_model.dart';
import 'api_client.dart';

class NotificationApiService {
  final ApiClient _apiClient;

  NotificationApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<MultipleNotificationsResponse> getNotifications({
    NotificationType? type,
    bool? isRead,
    int? skip,
    int? take,
  }) async {
    final queryParameters = <String, String>{
      if (type != null) 'type': type.name,
      if (isRead != null) 'isRead': isRead.toString(),
      if (skip != null) 'skip': skip.toString(),
      if (take != null) 'take': take.toString(),
    };

    final endpoint = queryParameters.isEmpty
        ? 'notifications'
        : 'notifications?${Uri(queryParameters: queryParameters).query}';
    final response = await _apiClient.get(endpoint);
    // Backend wraps responses in {data: ...} — unwrap, tolerating bare payloads
    final data = response is Map<String, dynamic> && response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return MultipleNotificationsResponse.fromJson(data);
  }

  Future<void> deleteAllNotifications() async {
    await _apiClient.delete('notifications');
  }

  Future<SingleNotificationResponse> markNotificationAsRead(int id) async {
    final response = await _apiClient.put('notifications/$id/read');
    if (response is! Map<String, dynamic>) {
      return SingleNotificationResponse(notification: _syntheticRead(id));
    }
    // Backend wraps in {data:{notification:...}} — accept every historical
    // shape so a server change degrades to a synthetic row, not a crash.
    final inner = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    final notificationJson = inner['notification'];
    if (notificationJson is! Map<String, dynamic>) {
      return SingleNotificationResponse(notification: _syntheticRead(id));
    }
    return SingleNotificationResponse.fromJson(notificationJson);
  }

  NotificationResponse _syntheticRead(int id) {
    final now = DateTime.now().toUtc();
    return NotificationResponse(
      id: id,
      userId: 0,
      type: NotificationType.NEW_ARTICLE,
      message: '',
      isRead: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> markAllNotificationsAsRead() async {
    await _apiClient.put('notifications/read-all');
  }

  Future<void> deleteNotification(int id) async {
    await _apiClient.delete('notifications/$id');
  }

  Future<dynamic> checkQueueStatus() async {
    return await _apiClient.get('notifications/queue-status');
  }

  Future<void> clearQueue() async {
    await _apiClient.delete('notifications/queue');
  }
}
