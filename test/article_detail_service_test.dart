import 'package:chanolite/services/api/api_client.dart';
import 'package:chanolite/services/api/article_detail_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';

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
  group('ArticleDetailService', () {
    late ArticleDetailService articleDetailService;
    late FakeApiClient fakeApiClient;

    setUp(() {
      fakeApiClient = FakeApiClient();
      articleDetailService = ArticleDetailService(apiClient: fakeApiClient);
    });

    test('getArticleBySlug passes language parameter and maps ja to jp', () async {
      await articleDetailService.getArticleBySlug('test-article', language: const Locale('ja'));

      expect(fakeApiClient.lastVariables, isNotNull);
      expect(fakeApiClient.lastVariables!['slug'], 'test-article');
      expect(fakeApiClient.lastVariables!['language'], 'jp');
    });

    test('getArticleBySlug passes null language when not provided', () async {
      await articleDetailService.getArticleBySlug('test-article');

      expect(fakeApiClient.lastVariables, isNotNull);
      expect(fakeApiClient.lastVariables!['slug'], 'test-article');
      expect(fakeApiClient.lastVariables!['language'], isNull);
    });

    test('getArticleById passes language parameter', () async {
      await articleDetailService.getArticleById(1, language: const Locale('th'));

      expect(fakeApiClient.lastVariables, isNotNull);
      expect(fakeApiClient.lastVariables!['id'], 1);
      expect(fakeApiClient.lastVariables!['language'], 'th');
    });
  });
}
