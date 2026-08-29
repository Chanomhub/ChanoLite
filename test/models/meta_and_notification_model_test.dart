import 'package:chanolite/models/meta_model.dart';
import 'package:chanolite/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Meta & Notification Models Tests', () {
    test('TagsResponse, CategoriesResponse, PlatformsResponse fromJson', () {
      final tagsResp = TagsResponse.fromJson({'tags': ['RPG', 'Action']});
      expect(tagsResp.tags, ['RPG', 'Action']);

      final catResp = CategoriesResponse.fromJson({'categories': ['Games', 'Mods']});
      expect(catResp.categories, ['Games', 'Mods']);

      final platResp = PlatformsResponse.fromJson({'platforms': ['Android', 'PC']});
      expect(platResp.platforms, ['Android', 'PC']);
    });

    test('EngineDto fromJson', () {
      final json = {
        'id': 1,
        'name': 'RPG Maker MZ',
        'status': 'active',
        'createdAt': '2023-01-01T00:00:00Z',
        'updatedAt': '2023-01-02T00:00:00Z',
      };
      final engine = EngineDto.fromJson(json);
      expect(engine.id, 1);
      expect(engine.name, 'RPG Maker MZ');
      expect(engine.status, 'active');
      expect(engine.createdAt, isNotNull);
      expect(engine.updatedAt, isNotNull);
    });

    test('NotificationResponse fromJson and MultipleNotificationsResponse', () {
      final notifJson = {
        'id': 10,
        'userId': 5,
        'type': 'NEW_ARTICLE',
        'message': 'New game released: Epic Quest!',
        'isRead': false,
        'entityId': '101',
        'entityType': 'article',
        'createdAt': '2023-08-01T12:00:00Z',
        'updatedAt': '2023-08-01T12:00:00Z',
      };

      final notif = NotificationResponse.fromJson(notifJson);
      expect(notif.id, 10);
      expect(notif.userId, 5);
      expect(notif.type, NotificationType.NEW_ARTICLE);
      expect(notif.message, 'New game released: Epic Quest!');
      expect(notif.isRead, isFalse);
      expect(notif.entityId, '101');

      final multiple = MultipleNotificationsResponse.fromJson({
        'notifications': [notifJson],
        'notificationsCount': 1,
        'unreadCount': 1,
      });
      expect(multiple.notifications.length, 1);
      expect(multiple.notificationsCount, 1);
      expect(multiple.unreadCount, 1);

      final single = SingleNotificationResponse.fromJson({
        'notification': notifJson,
      });
      expect(single.notification.id, 10);
    });
  });
}
