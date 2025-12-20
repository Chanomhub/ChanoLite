import 'dart:ui';
import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/models/download.dart';
import 'package:chanolite/services/api/api_client.dart';

class ArticleRepository {
  final ApiClient _apiClient;

  ArticleRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

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
    String? returnFields,
  }) async {
    const String defaultFields = '''
      id
      title
      slug
      description
      coverImage
      mainImage
      backgroundImage
      favoritesCount
      updatedAt
      tags {
        name
      }
      platforms {
        name
      }
    ''';

    final String fields = returnFields ?? defaultFields;

    final String graphqlQuery = '''
      query GetArticles(
        \$limit: Int
        \$offset: Int
        \$filter: ArticleFilterInput
        \$status: ArticleStatus
      ) {
        articles(
          limit: \$limit
          offset: \$offset
          filter: \$filter
          status: \$status
        ) {
          $fields
        }
      }
    ''';

    final Map<String, dynamic> filter = {
      'q': query,
      'tag': tag,
      'category': category,
      'platform': platform,
      'engine': engine,
      'sequentialCode': sequentialCode,
    };
    filter.removeWhere((key, value) => value == null || value.toString().isEmpty);

    final variables = {
      'limit': limit,
      'offset': offset,
      'filter': filter.isNotEmpty ? filter : null,
      'status': status,
    };

    // Remove null values from variables
    variables.removeWhere((key, value) => value == null);

    final data = await _apiClient.query(graphqlQuery, variables: variables);

    if (data['data'] != null && data['data']['articles'] != null) {
      final List<dynamic> articlesData = data['data']['articles'];
      return ArticlesResponse(
        articles: articlesData.map((json) => Article.fromJson(json)).toList(),
        articlesCount: null, // Count not available in this query
      );
    } else {
      throw Exception('Failed to load articles');
    }
  }

  Future<Article> getArticleBySlug(String slug, {Locale? language, String? returnFields}) async {
    return _getArticle(slug: slug, language: language, returnFields: returnFields);
  }

  Future<Article> getArticleById(int id, {Locale? language, String? returnFields}) async {
    return _getArticle(id: id, language: language, returnFields: returnFields);
  }

  Future<Article> _getArticle({int? id, String? slug, Locale? language, String? returnFields}) async {
    const String defaultFields = '''
      id
      title
      slug
      description
      body
      coverImage
      mainImage
      backgroundImage
      favoritesCount
      createdAt
      updatedAt
      tags {
        name
      }
      categories {
        name
      }
      platforms {
        name
      }
      author {
        name
        image
      }
      downloads {
        name
        url
      }
    ''';

    final String fields = returnFields ?? defaultFields;

    final String graphqlQuery = '''
      query GetArticle(\$id: Int, \$slug: String, \$language: String) {
        article(id: \$id, slug: \$slug, language: \$language) {
          $fields
        }
      }
    ''';

    final variables = {
      'id': id,
      'slug': slug,
      'language': language?.languageCode,
    };
    variables.removeWhere((key, value) => value == null);

    final data = await _apiClient.query(graphqlQuery, variables: variables);

    if (data['data'] != null && data['data']['article'] != null) {
      return Article.fromJson(data['data']['article']);
    } else {
      throw Exception('Failed to load article');
    }
  }

  Future<List<Download>> getDownloads(int articleId) async {
    const String graphqlQuery = '''
      query GetDownloads(\$articleId: Int!) {
        downloads(articleId: \$articleId) {
          name
          url
        }
      }
    ''';

    final variables = {'articleId': articleId};

    final data = await _apiClient.query(graphqlQuery, variables: variables);

    if (data['data'] != null && data['data']['downloads'] != null) {
      final downloadsData = data['data']['downloads'] as List;
      return downloadsData.map((e) => Download.fromJson(e)).toList();
    } else {
      return [];
    }
  }
}

