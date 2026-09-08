import 'package:chanolite/models/article_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Article Model Tests', () {
    final sampleArticleJson = {
      'id': 101,
      'title': 'Test Game Adventure',
      'slug': 'test-game-adventure',
      'description': 'A fantastic test adventure game',
      'body': '<p>Full body text here</p>',
      'ver': '1.0.0',
      'version': 1,
      'createdAt': '2023-05-10T12:00:00.000Z',
      'updatedAt': '2023-05-11T14:30:00.000Z',
      'status': 'PUBLISHED',
      'engine': {'id': 1, 'name': 'RPG Maker MV'},
      'mainImage': 'https://example.com/main.jpg',
      'images': [
        {'id': 1, 'url': 'https://example.com/img1.jpg'},
        {'id': 2, 'path': '/img2.jpg'},
        'https://example.com/img3.jpg',
      ],
      'backgroundImage': 'https://example.com/bg.jpg',
      'coverImage': 'https://example.com/cover.jpg',
      'tags': [
        {'id': 1, 'name': 'RPG'},
        {'id': 2, 'name': 'Anime'},
      ],
      'categories': [
        {'id': 1, 'name': 'Games'},
      ],
      'platforms': [
        {'id': 1, 'name': 'Android'},
        {'id': 2, 'name': 'PC'},
      ],
      'author': {
        'id': 'auth1',
        'name': 'ChanomDev',
        'image': 'https://example.com/avatar.png',
      },
      'favorited': true,
      'favoritesCount': 42,
      'sequentialCode': 'SEQ-101',
      'downloads': [
        {
          'id': 'dl1',
          'name': 'Game APK',
          'url': 'https://example.com/game.apk',
          'isActive': true,
          'vipOnly': false,
        }
      ]
    };

    test('Article.fromJson parses complete JSON correctly', () {
      final article = Article.fromJson(sampleArticleJson);

      expect(article.id, 101);
      expect(article.title, 'Test Game Adventure');
      expect(article.slug, 'test-game-adventure');
      expect(article.description, 'A fantastic test adventure game');
      expect(article.body, '<p>Full body text here</p>');
      expect(article.ver, '1.0.0');
      expect(article.version, 1);
      expect(article.createdAt, isNotNull);
      expect(article.updatedAt, isNotNull);
      expect(article.status, 'PUBLISHED');
      expect(article.engine, 'RPG Maker MV');
      expect(article.mainImage, 'https://example.com/main.jpg');
      expect(article.images.length, 3);
      expect(article.tagList, ['RPG', 'Anime']);
      expect(article.categoryList, ['Games']);
      expect(article.platformList, ['Android', 'PC']);
      expect(article.author?.name, 'ChanomDev');
      expect(article.favorited, isTrue);
      expect(article.favoritesCount, 42);
      expect(article.sequentialCode, 'SEQ-101');
      expect(article.downloads.length, 1);
      expect(article.downloads.first.name, 'Game APK');
    });

    test('Article.idOnly creates a valid placeholder instance', () {
      final article = Article.idOnly(999);
      expect(article.id, 999);
      expect(article.title, '');
      expect(article.tagList, isEmpty);
      expect(article.downloads, isEmpty);
      expect(article.favorited, isFalse);
    });

    test('Article.fromJson handles string and num ID correctly', () {
      final stringIdJson = Map<String, dynamic>.from(sampleArticleJson);
      stringIdJson['id'] = '102';
      stringIdJson['version'] = '2';
      stringIdJson['favoritesCount'] = '100';

      final article = Article.fromJson(stringIdJson);
      expect(article.id, 102);
      expect(article.version, 2);
      expect(article.favoritesCount, 100);
    });

    test('Article.toJson creates valid JSON map', () {
      final article = Article.fromJson(sampleArticleJson);
      final json = article.toJson();

      expect(json['id'], 101);
      expect(json['title'], 'Test Game Adventure');
      expect(json['tags'], ['RPG', 'Anime']);
      expect(json['categories'], ['Games']);
      expect(json['platforms'], ['Android', 'PC']);
      expect(json['favoritesCount'], 42);
    });

    test('ArticlesResponse fromJson and toJson works', () {
      final responseJson = {
        'articles': [sampleArticleJson],
        'articlesCount': 1,
      };

      final response = ArticlesResponse.fromJson(responseJson);
      expect(response.articles.length, 1);
      expect(response.articlesCount, 1);
      expect(response.articles.first.id, 101);

      final outJson = response.toJson();
      expect(outJson['articlesCount'], 1);
      expect((outJson['articles'] as List).length, 1);
    });

    test('Author fromJson and toJson works', () {
      final authorJson = {
        'id': 'auth1',
        'name': 'Dev',
        'image': 'https://example.com/dev.png',
      };
      final author = Author.fromJson(authorJson);
      expect(author.id, 'auth1');
      expect(author.name, 'Dev');
      expect(author.image, 'https://example.com/dev.png');

      final outJson = author.toJson();
      expect(outJson['name'], 'Dev');
    });
  });
}
