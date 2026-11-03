import 'package:chanolite/managers/notification_manager.dart';
import 'package:chanolite/models/notification_model.dart';
import 'package:chanolite/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

NotificationResponse _notif(
  int id, {
  bool isRead = false,
  String type = 'NEW_COMMENT',
  String? entityType,
  String? entityId,
}) =>
    NotificationResponse(
      id: id,
      userId: 1,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.$type',
      ),
      message: 'm$id',
      isRead: isRead,
      entityId: entityId,
      entityType: entityType,
      createdAt: DateTime.parse('2026-11-01T10:00:00.000Z'),
      updatedAt: DateTime.parse('2026-11-01T10:00:00.000Z'),
    );

/// Records calls only — the screen under test owns no state transitions.
class FakeNotificationManager extends ChangeNotifier
    implements NotificationManager {
  FakeNotificationManager({
    List<NotificationResponse> notifications = const [],
    int unreadCount = 0,
    bool isLoading = false,
    this.error,
  })  : _items = List.of(notifications),
        _unread = unreadCount,
        _loading = isLoading;

  final List<NotificationResponse> _items;
  final int _unread;
  final bool _loading;

  @override
  final String? error;

  int loadCalls = 0;
  int markAllCalls = 0;
  int deleteAllCalls = 0;
  final List<int> markedRead = [];
  final List<int> deleted = [];

  @override
  List<NotificationResponse> get notifications => List.unmodifiable(_items);
  @override
  int get unreadCount => _unread;
  @override
  bool get isLoading => _loading;

  @override
  Future<void> loadNotifications() async {
    loadCalls++;
    notifyListeners();
  }

  @override
  Future<void> markAsRead(int id) async {
    markedRead.add(id);
    notifyListeners();
  }

  @override
  Future<void> markAllAsRead() async {
    markAllCalls++;
    notifyListeners();
  }

  @override
  Future<void> deleteNotification(int id) async {
    deleted.add(id);
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  @override
  Future<void> deleteAll() async {
    deleteAllCalls++;
    _items.clear();
    notifyListeners();
  }
}

Widget _wrap(FakeNotificationManager manager) => ChangeNotifierProvider<
        NotificationManager>.value(
      value: manager,
      child: const MaterialApp(home: NotificationsScreen()),
    );

void main() {
  testWidgets('shows loading skeleton while fetching', (tester) async {
    await tester.pumpWidget(_wrap(FakeNotificationManager(isLoading: true)));

    expect(find.byWidgetPredicate((w) => w is Skeletonizer), findsOneWidget);
  });

  testWidgets('shows error state with a working retry button', (tester) async {
    final manager = FakeNotificationManager(error: 'boom');
    await tester.pumpWidget(_wrap(manager));
    await tester.pumpAndSettle();

    expect(find.textContaining('เกิดข้อผิดพลาด'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    expect(manager.loadCalls, 1); // auto-load on open

    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(manager.loadCalls, 2);
  });

  testWidgets('shows empty state when there are no notifications',
      (tester) async {
    final manager = FakeNotificationManager();
    await tester.pumpWidget(_wrap(manager));
    await tester.pumpAndSettle();

    expect(find.text('ไม่มีการแจ้งเตือน'), findsOneWidget);
    // Nothing to act on: both AppBar actions stay disabled.
    await tester.tap(find.byIcon(Icons.done_all));
    await tester.tap(find.byIcon(Icons.delete_sweep));
    await tester.pumpAndSettle();

    expect(manager.markAllCalls, 0);
    expect(manager.deleteAllCalls, 0);
  });

  testWidgets('renders rows with type icons and marks-all works',
      (tester) async {
    final manager = FakeNotificationManager(notifications: [
      _notif(1, type: 'NEW_COMMENT'),
      _notif(2, type: 'MOD_UPDATE', isRead: true),
    ], unreadCount: 1);
    await tester.pumpWidget(_wrap(manager));
    await tester.pumpAndSettle();

    expect(find.text('m1'), findsOneWidget);
    expect(find.text('m2'), findsOneWidget);
    expect(find.byIcon(Icons.comment), findsOneWidget);
    expect(find.byIcon(Icons.update), findsOneWidget);

    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pumpAndSettle();

    expect(manager.markAllCalls, 1);
  });

  testWidgets('delete-all asks for confirmation before deleting',
      (tester) async {
    final manager = FakeNotificationManager(notifications: [_notif(1)]);
    await tester.pumpWidget(_wrap(manager));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_sweep));
    await tester.pumpAndSettle();
    expect(manager.deleteAllCalls, 0); // dialog, not deleted yet

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    expect(manager.deleteAllCalls, 0);

    await tester.tap(find.byIcon(Icons.delete_sweep));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();
    expect(manager.deleteAllCalls, 1);
  });

  testWidgets('tapping an unread row marks it as read', (tester) async {
    final manager = FakeNotificationManager(notifications: [_notif(5)]);
    await tester.pumpWidget(_wrap(manager));
    await tester.pumpAndSettle();

    await tester.tap(find.text('m5'));
    await tester.pumpAndSettle();

    expect(manager.markedRead, [5]);
  });

  testWidgets('tapping an already-read row does not call markAsRead again',
      (tester) async {
    final manager =
        FakeNotificationManager(notifications: [_notif(6, isRead: true)]);
    await tester.pumpWidget(_wrap(manager));
    await tester.pumpAndSettle();

    await tester.tap(find.text('m6'));
    await tester.pumpAndSettle();

    expect(manager.markedRead, isEmpty);
  });

  testWidgets('swiping a row away deletes it', (tester) async {
    final manager = FakeNotificationManager(notifications: [_notif(7)]);
    await tester.pumpWidget(_wrap(manager));
    await tester.pumpAndSettle();

    await tester.drag(find.text('m7'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(manager.deleted, [7]);
  });
}
