import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/repositories/article_repository.dart';
import 'package:chanolite/screens/search_screen.dart';
import 'package:chanolite/theme/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class MockSearchArticleRepo extends Mock implements ArticleRepository {
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
          title: 'Search Result Game',
          description: 'Search description',
          body: 'Content',
          updatedAt: DateTime.now(),
          images: [],
          tagList: ['Action'],
          categoryList: ['Game'],
          platformList: ['Android'],
          favorited: false,
          favoritesCount: 5,
          downloads: [],
        ),
      ],
      articlesCount: 1,
    );
  }
}

void main() {
  testWidgets('SearchScreen renders search bar and search results', (WidgetTester tester) async {
    final articleRepo = MockSearchArticleRepo();
    final themeNotifier = ThemeNotifier(ThemeMode.dark);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ArticleRepository>.value(value: articleRepo),
          ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
        ],
        child: const MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search), findsWidgets);
  });
}
