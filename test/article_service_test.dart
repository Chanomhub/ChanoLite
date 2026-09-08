import 'package:chanolite/repositories/article_repository.dart';
import 'package:chanolite/services/api/api_client.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide Article, Download, User, Profile, Author;
import 'package:flutter_test/flutter_test.dart';

class FakeApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> query(String query, {bool isRetry = false, Map<String, dynamic>? variables}) async {
    return {
      'data': {
        'public': {
          'article': {
            'id': 1,
            'slug': 'test-article',
            'title': 'Test Article',
            'description': 'Test Description',
            'body': 'Test Body',
            'status': 'published',
            'createdAt': '2023-01-01T00:00:00Z',
            'updatedAt': '2023-01-01T00:00:00Z',
            'images': [],
            'author': {'id': '1', 'name': 'Author', 'image': null},
            'categories': [],
            'tags': [],
            'platforms': [],
            'favoritesCount': 0,
            'favorited': false,
            'downloads': []
          },
          'articles': [],
          'articlesCount': 0,
        }
      }
    };
  }
}

void main() {
  group('ArticleService Legacy / Repository Integration', () {
    test('Queries article successfully via repository', () async {
      final fakeApiClient = FakeApiClient();
      final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
      final repo = ArticleRepository(apiClient: fakeApiClient, sdk: sdk);

      final article = await repo.getArticleById(1);
      expect(article.id, 1);
      expect(article.title, 'Test Article');
    });
  });
}
