// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:chanolite/main.dart';

import 'package:chanolite/constants/app_config.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter/material.dart';
import 'mock.dart';

void main() {
  testWidgets('App loads home screen with title', (WidgetTester tester) async {
    final downloadManager = MockDownloadManager();
    final sdk = ChanomhubClient(
      baseUrl: AppConfig.apiBaseUrl,
      cdnUrl: AppConfig.imgproxyBaseUrl,
    );



    final authManager = MockAuthManager();
    final articleRepository = MockArticleRepository();

    await tester.pumpWidget(MyApp(
      downloadManager: downloadManager,
      authManager: authManager,
      articleRepository: articleRepository,
      initialLocale: const Locale('en'),
      sdk: sdk,
    ));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
