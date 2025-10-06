
import 'package:chanolite/models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService({ApiClient? apiClient})
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
    final data = await _apiClient.get(endpoint) as Map<String, dynamic>;
    return MultipleNotificationsResponse.fromJson(data);
  }

  Future<void> deleteAllNotifications() async {
    await _apiClient.delete('notifications');
  }

  Future<SingleNotificationResponse> markNotificationAsRead(int id) async {
    final data = await _apiClient.put('notifications/$id/read') as Map<String, dynamic>;
    return SingleNotificationResponse.fromJson(data);
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
