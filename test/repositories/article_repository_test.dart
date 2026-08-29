import 'dart:ui';
import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/repositories/article_repository.dart';
import 'package:chanolite/services/api/api_client.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide Article, Download, User, Profile, Author;
import 'package:flutter_test/flutter_test.dart';

class FakeApiClient extends ApiClient {
  Map<String, dynamic>? lastVariables;
  String? lastQuery;

  @override
  Future<Map<String, dynamic>> query(
    String query, {
    bool isRetry = false,
    Map<String, dynamic>? variables,
  }) async {
    lastQuery = query;
    lastVariables = variables;

    if (query.contains('GetArticles')) {
      return {
        'data': {
          'public': {
            'articles': [
              {
                'id': 1,
                'title': 'Test Article 1',
                'description': 'Description 1',
                'body': 'Body 1',
                'updatedAt': '2023-01-01T00:00:00Z',
                'tags': [{'id': 1, 'name': 'RPG'}],
                'categories': [{'id': 1, 'name': 'Games'}],
                'platforms': [{'id': 1, 'name': 'Android'}],
                'favoritesCount': 10,
                'favorited': false,
                'downloads': [],
              }
            ],
            'articlesCount': 1,
          }
        }
      };
    }

    if (query.contains('GetArticleById')) {
      return {
        'data': {
          'public': {
            'article': {
              'id': 1,
              'title': 'Single Article Details',
              'description': 'Description Detail',
              'body': '<p>Full content</p>',
              'updatedAt': '2023-01-01T00:00:00Z',
              'tags': [],
              'categories': [],
              'platforms': [],
              'favoritesCount': 5,
              'favorited': true,
              'downloads': [
                {
                  'id': 'dl_1',
                  'name': 'Game Link',
                  'url': 'https://example.com/game.zip',
                  'isActive': true,
                  'vipOnly': false,
                }
              ],
            }
          }
        }
      };
    }

    if (query.contains('GetDownloads')) {
      return {
        'data': {
          'public': {
            'downloads': [
              {
                'id': 'dl_1',
                'name': 'Game Link',
                'url': 'https://example.com/game.zip',
                'isActive': true,
                'vipOnly': false,
              }
            ]
          }
        }
      };
    }

    return {'data': {}};
  }
}

void main() {
  group('ArticleRepository Tests', () {
    late FakeApiClient fakeApiClient;
    late ArticleRepository repository;
    late ChanomhubClient sdk;

    setUp(() {
      fakeApiClient = FakeApiClient();
      sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
      repository = ArticleRepository(apiClient: fakeApiClient, sdk: sdk);
    });

    test('getArticles retrieves and parses articles list', () async {
      final response = await repository.getArticles(
        limit: 10,
        offset: 0,
        query: 'RPG',
        category: 'Games',
      );

      expect(response.articles.length, 1);
      expect(response.articles.first.title, 'Test Article 1');
      expect(response.articlesCount, 1);
      expect(fakeApiClient.lastVariables?['limit'], 10);
      expect(fakeApiClient.lastVariables?['filter']['q'], 'RPG');
      expect(fakeApiClient.lastVariables?['filter']['category'], 'Games');
    });

    test('getArticleById retrieves single article with downloads', () async {
      final article = await repository.getArticleById(1, language: const Locale('en'));

      expect(article.id, 1);
      expect(article.title, 'Single Article Details');
      expect(article.favorited, isTrue);
      expect(article.downloads.length, 1);
      expect(article.downloads.first.name, 'Game Link');
      expect(fakeApiClient.lastVariables?['id'], 1);
      expect(fakeApiClient.lastVariables?['language'], 'en');
    });

    test('getDownloads retrieves download list', () async {
      final downloads = await repository.getDownloads(1);
      expect(downloads.length, 1);
      expect(downloads.first.id, 'dl_1');
      expect(fakeApiClient.lastVariables?['articleId'], 1);
    });
  });
}
