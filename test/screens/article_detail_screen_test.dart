import 'dart:ui';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/models/download.dart';
import 'package:chanolite/models/download_task.dart';
import 'package:chanolite/repositories/article_repository.dart';
import 'package:chanolite/screens/article_detail_screen.dart';
import 'package:chanolite/services/cache_service.dart';
import 'package:chanolite/theme/locale_notifier.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide Article, Download, User, Profile, Author;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDetailArticleRepo extends Mock implements ArticleRepository {
  @override
  Future<Article> getArticleById(int id, {Locale? language}) async {
    return Article(
      id: id,
      title: 'Detailed RPG Adventure',
      description: 'An epic story-driven game',
      body: '<p>Complete storyline description</p>',
      updatedAt: DateTime.now(),
      images: [],
      tagList: ['RPG', 'Story'],
      categoryList: ['Game'],
      platformList: ['Android'],
      favorited: false,
      favoritesCount: 15,
      downloads: [
        Download(
          id: 'dl_1',
          name: 'Game v1.0.apk',
          url: 'https://example.com/dl/game.apk',
          isActive: true,
          vipOnly: false,
        )
      ],
    );
  }
}

class FakeDownloadManager extends ChangeNotifier implements DownloadManager {
  @override
  List<DownloadTask> get tasks => [];

  @override
  Map<String, DownloadTask> get downloads => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ArticleDetailScreen loads and renders article details and download buttons', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
    final authManager = AuthManager(sdk: sdk);
    final articleRepo = MockDetailArticleRepo();
    final cacheService = CacheService();
    final localeNotifier = LocaleNotifier(const Locale('en'));
    final downloadManager = FakeDownloadManager();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CacheService>.value(value: cacheService),
          Provider<ArticleRepository>.value(value: articleRepo),
          ChangeNotifierProvider<AuthManager>.value(value: authManager),
          ChangeNotifierProvider<LocaleNotifier>.value(value: localeNotifier),
          ChangeNotifierProvider<DownloadManager>.value(value: downloadManager),
        ],
        child: const MaterialApp(
          home: ArticleDetailScreen(articleId: 1),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Detailed RPG Adventure'), findsOneWidget);
    expect(find.text('Game v1.0.apk'), findsOneWidget);
  });
}
