// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:chanolite/main.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter/material.dart';
import 'mock.dart';

void main() {
  testWidgets('App loads home screen with title', (WidgetTester tester) async {
    final downloadManager = MockDownloadManager();

    // Mock the loadTasks method to avoid errors in the test environment
    when(downloadManager.loadTasks()).thenAnswer((_) async => {});

    await tester.pumpWidget(MyApp(
      downloadManager: downloadManager,
      initialLocale: const Locale('en'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('ChanoLite - Home'), findsOneWidget);
  });
}
