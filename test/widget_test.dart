// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:chanolite/main.dart';
import 'package:chanolite/managers/ad_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads home screen with title', (WidgetTester tester) async {
    final adManager = AdManager(
      configProvider: () async => const AdManagerConfig(
        sdkKey: 'TUhw3IRaMf_oHlLrWZWVZJiI3oGT99RkAEIg7dei4iQ1l4l1EkeB_XDCs3HBfl2rkeeinVzx1MEwuBph1gT8u1',
        bannerAdUnitId: 'TEST_BANNER_ID',
      ),
    );

    await tester.pumpWidget(MyApp(adManager: adManager));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('ChanoLite - Home'), findsOneWidget);
  });
}
