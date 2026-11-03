import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/notification_manager.dart';
import 'package:chanolite/models/notification_model.dart';
import 'package:chanolite/widgets/notification_bell_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeAuthManager extends ChangeNotifier implements AuthManager {
  FakeAuthManager({this.loggedIn = true});
  final bool loggedIn;

  @override
  bool get isAuthenticated => loggedIn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationManager extends ChangeNotifier
    implements NotificationManager {
  FakeNotificationManager({int unreadCount = 0}) : _unread = unreadCount;
  int _unread;

  @override
  int get unreadCount => _unread;
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  List<NotificationResponse> get notifications => const [];

  @override
  Future<void> loadNotifications() async {}

  void setUnread(int value) {
    _unread = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  FakeAuthManager auth,
  FakeNotificationManager notifications,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthManager>.value(value: auth),
        ChangeNotifierProvider<NotificationManager>.value(value: notifications),
      ],
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [NotificationBellButton()],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('hidden when logged out', (tester) async {
    await _pump(tester, FakeAuthManager(loggedIn: false), FakeNotificationManager());

    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    expect(find.byType(NotificationBellButton), findsOneWidget); // shrink widget still exists
  });

  testWidgets('shows unread badge count when logged in', (tester) async {
    await _pump(tester, FakeAuthManager(), FakeNotificationManager(unreadCount: 3));

    expect(find.byIcon(Icons.notifications), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('no badge when everything is read', (tester) async {
    await _pump(tester, FakeAuthManager(), FakeNotificationManager());

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('badge caps at 99+', (tester) async {
    await _pump(tester, FakeAuthManager(), FakeNotificationManager(unreadCount: 150));

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('tap opens the notifications screen', (tester) async {
    await _pump(tester, FakeAuthManager(), FakeNotificationManager());

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('การแจ้งเตือน'), findsOneWidget); // screen AppBar title
  });
}
