import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/services/api/api_client.dart';
import 'package:chanolite/services/api/article_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApiClient extends ApiClient {
  Map<String, dynamic>? lastVariables;
  String? lastQuery;

  @override
  Future<dynamic> query(String query, {Map<String, dynamic>? variables}) async {
    lastQuery = query;
    lastVariables = variables;
    return {
      'data': {
        'article': {
          'id': '1',
          'slug': 'test-article',
          'title': 'Test Article',
          'description': 'Test Description',
          'body': 'Test Body',
          'status': 'published',
          'createdAt': '2023-01-01T00:00:00Z',
          'updatedAt': '2023-01-01T00:00:00Z',
          'images': [],
          'author': {'name': 'Author', 'image': null},
          'creators': [],
          'categories': [],
          'tags': [],
          'platforms': [],
          'favoritesCount': 0,
          'downloads': []
        },
        'downloads': []
      }
    };
  }
}

void main() {
  group('ArticleService', () {
    late ArticleService articleService;
    late FakeApiClient fakeApiClient;

    setUp(() {
      fakeApiClient = FakeApiClient();
      articleService = ArticleService(apiClient: fakeApiClient);
    });

    test('getArticleBySlug passes language parameter', () async {
      await articleService.getArticleBySlug('test-article', language: 'jp');

      expect(fakeApiClient.lastVariables, isNotNull);
      expect(fakeApiClient.lastVariables!['slug'], 'test-article');
      expect(fakeApiClient.lastVariables!['language'], 'jp');
    });

    test('getArticleBySlug passes null language when not provided', () async {
      await articleService.getArticleBySlug('test-article');

      expect(fakeApiClient.lastVariables, isNotNull);
      expect(fakeApiClient.lastVariables!['slug'], 'test-article');
      expect(fakeApiClient.lastVariables!['language'], isNull);
    });

    test('getArticleById passes language parameter', () async {
      await articleService.getArticleById(1, language: 'th');

      expect(fakeApiClient.lastVariables, isNotNull);
      expect(fakeApiClient.lastVariables!['id'], 1);
      expect(fakeApiClient.lastVariables!['language'], 'th');
    });
  });
}
