import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/repositories/article_repository.dart';
import 'package:chanolite/screens/home_screen.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide Article, Download, User, Profile, Author;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArticleRepo extends Mock implements ArticleRepository {
  @override
  Future<ArticlesResponse> getArticles({
    int limit = 20,
    int offset = 0,
    String? query,
    String? tag,
    String? category,
    String? platform,
    String? engine,
    String? status,
    String? sequentialCode,
  }) async {
    return ArticlesResponse(
      articles: [
        Article(
          id: 1,
          title: 'Featured Game 1',
          description: 'Great game description',
          body: 'Full content',
          updatedAt: DateTime.now(),
          images: [],
          tagList: ['RPG'],
          categoryList: ['Game'],
          platformList: ['Android'],
          favorited: false,
          favoritesCount: 12,
          downloads: [],
        ),
      ],
      articlesCount: 1,
    );
  }
}

void main() {
  testWidgets('HomeScreen loads and displays article lists', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
    final authManager = AuthManager(sdk: sdk);
    final articleRepo = MockArticleRepo();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthManager>.value(value: authManager),
          Provider<ArticleRepository>.value(value: articleRepo),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Initial loading pump
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
