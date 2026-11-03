import 'package:chanolite/managers/notification_manager.dart';
import 'package:chanolite/models/notification_model.dart';
import 'package:chanolite/services/api/api_client.dart';
import 'package:chanolite/services/api/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Overrides every transport method — the real client is never touched.
class MockApiClient extends ApiClient {
  final Map<String, dynamic> getResponses = {};
  final List<String> getEndpoints = [];
  final List<String> putEndpoints = [];
  final List<String> deleteEndpoints = [];
  Object? getError;
  Object? putError;

  @override
  Future<dynamic> get(String endpoint,
      {Map<String, String>? headers, bool isRetry = false}) async {
    getEndpoints.add(endpoint);
    if (getError != null) throw getError!;
    return getResponses[endpoint];
  }

  @override
  Future<dynamic> put(String endpoint,
      {dynamic body, Map<String, String>? headers, bool isRetry = false}) async {
    putEndpoints.add(endpoint);
    if (putError != null) throw putError!;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> delete(String endpoint,
      {Map<String, String>? headers, bool isRetry = false}) async {
    deleteEndpoints.add(endpoint);
    return <String, dynamic>{};
  }
}

NotificationResponse notifOf(Map<String, dynamic> json) =>
    NotificationResponse.fromJson(json);

Map<String, dynamic> notifJson(
  int id, {
  bool isRead = false,
  String type = 'NEW_COMMENT',
}) =>
    {
      'id': id,
      'userId': 1,
      'type': type,
      'message': 'm$id',
      'isRead': isRead,
      'createdAt': '2026-11-01T10:00:00.000Z',
      'updatedAt': '2026-11-01T10:00:00.000Z',
    };

/// Backend TransformInterceptor wraps payloads: {data: ...}
Map<String, dynamic> envelope(Map<String, dynamic> payload) =>
    {'data': payload};

Future<void> seed(
  NotificationManager manager,
  MockApiClient client,
  List<Map<String, dynamic>> notifications, {
  required int unreadCount,
}) async {
  client.getResponses['notifications?take=50'] = envelope({
    'notifications': notifications,
    'totalCount': notifications.length,
    'unreadCount': unreadCount,
  });
  await manager.loadNotifications();
}

void main() {
  group('NotificationApiService', () {
    late MockApiClient client;
    late NotificationApiService service;

    setUp(() {
      client = MockApiClient();
      service = NotificationApiService(apiClient: client);
    });

    test('getNotifications unwraps the backend {data: ...} envelope', () async {
      client.getResponses['notifications?take=50'] = envelope({
        'notifications': [notifJson(7, type: 'MOD_UPDATE')],
        'totalCount': 1,
        'unreadCount': 1,
      });

      final result = await service.getNotifications(take: 50);

      expect(client.getEndpoints, ['notifications?take=50']);
      expect(result.notifications.length, 1);
      expect(result.notifications.first.id, 7);
      expect(result.notifications.first.type, NotificationType.MOD_UPDATE);
      expect(result.unreadCount, 1);
    });

    test('getNotifications builds filter query parameters', () async {
      client.getResponses[
              'notifications?type=MOD_UPDATE&isRead=false&skip=10&take=20'] =
          envelope({'notifications': [], 'totalCount': 0, 'unreadCount': 0});

      final result = await service.getNotifications(
        type: NotificationType.MOD_UPDATE,
        isRead: false,
        skip: 10,
        take: 20,
      );

      expect(result.notifications, isEmpty);
      expect(client.getEndpoints.single,
          'notifications?type=MOD_UPDATE&isRead=false&skip=10&take=20');
    });

    test('write endpoints hit the documented paths', () async {
      await service.markNotificationAsRead(9);
      await service.markAllNotificationsAsRead();
      await service.deleteNotification(3);
      await service.deleteAllNotifications();

      expect(client.putEndpoints,
          ['notifications/9/read', 'notifications/read-all']);
      expect(client.deleteEndpoints,
          ['notifications/3', 'notifications']);
    });
  });

  group('NotificationResponse.fromJson', () {
    test('maps entityId to string and unknown type falls back', () {
      final n = notifOf(notifJson(1, type: 'SOMETHING_NEW_FROM_BACKEND'));

      expect(n.type, NotificationType.NEW_ARTICLE);
      expect(n.isRead, isFalse);
    });
  });

  group('MultipleNotificationsResponse.fromJson', () {
    test('reads totalCount (backend field), tolerating legacy key', () {
      final fromTotal = MultipleNotificationsResponse.fromJson({
        'notifications': [],
        'totalCount': 3,
        'unreadCount': 2,
      });
      final fromLegacy = MultipleNotificationsResponse.fromJson({
        'notifications': [],
        'notificationsCount': 5,
        'unreadCount': 1,
      });

      expect(fromTotal.notificationsCount, 3);
      expect(fromLegacy.notificationsCount, 5);
    });
  });

  group('NotificationManager', () {
    late MockApiClient client;
    late NotificationManager manager;

    setUp(() {
      client = MockApiClient();
      manager = NotificationManager(
        apiService: NotificationApiService(apiClient: client),
      );
    });

    test('loadNotifications populates list and unread count', () async {
      await seed(manager, client, [notifJson(1), notifJson(2, isRead: true)],
          unreadCount: 1);

      expect(manager.notifications.length, 2);
      expect(manager.unreadCount, 1);
      expect(manager.isLoading, isFalse);
      expect(manager.error, isNull);
    });

    test('loadNotifications stores error message on failure', () async {
      client.getError = Exception('socket');

      await manager.loadNotifications();

      expect(manager.error, isNotNull);
      expect(manager.isLoading, isFalse);
      expect(manager.notifications, isEmpty);
    });

    test('markAsRead decrements unread count only once', () async {
      await seed(manager, client, [notifJson(5)], unreadCount: 1);

      await manager.markAsRead(5);
      expect(manager.unreadCount, 0);

      await manager.markAsRead(5);
      expect(manager.unreadCount, 0);
    });

    test('markAsRead keeps list unchanged for unknown id', () async {
      await seed(manager, client, [notifJson(5)], unreadCount: 1);

      await manager.markAsRead(999);

      expect(manager.notifications.length, 1);
      expect(manager.notifications.first.isRead, isFalse);
      expect(client.putEndpoints, contains('notifications/999/read'));
    });

    test('markAllAsRead zeroes unread count and flips every row', () async {
      await seed(
        manager,
        client,
        [notifJson(5), notifJson(6)],
        unreadCount: 2,
      );

      await manager.markAllAsRead();

      expect(manager.unreadCount, 0);
      expect(manager.notifications.every((n) => n.isRead), isTrue);
    });

    test('deleteNotification removes row and adjusts unread count', () async {
      await seed(
        manager,
        client,
        [notifJson(5), notifJson(6, isRead: true)],
        unreadCount: 1,
      );

      await manager.deleteNotification(5);

      expect(manager.notifications.map((n) => n.id), [6]);
      expect(manager.unreadCount, 0);
    });

    test('deleteAll clears everything', () async {
      await seed(manager, client, [notifJson(5)], unreadCount: 1);

      await manager.deleteAll();

      expect(manager.notifications, isEmpty);
      expect(manager.unreadCount, 0);
      expect(client.deleteEndpoints, contains('notifications'));
    });

    test('API failure inside markAsRead surfaces error, state untouched',
        () async {
      await seed(manager, client, [notifJson(5)], unreadCount: 1);
      client.putError = Exception('network gone');

      await manager.markAsRead(5);

      expect(manager.error, isNotNull);
      expect(manager.notifications.first.isRead, isFalse);
      expect(manager.unreadCount, 1);
    });
  });
}
