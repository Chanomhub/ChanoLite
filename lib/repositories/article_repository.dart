import 'dart:ui';
import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/models/download.dart';
import 'package:chanolite/services/api/api_client.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' as sdk_models;
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide Article, Download, User, Profile, Author;

class ArticleRepository {
  final ApiClient _apiClient;
  final ChanomhubClient sdk;

  ArticleRepository({ApiClient? apiClient, required this.sdk})
      : _apiClient = apiClient ?? ApiClient();

  /// Constants for GraphQL fields to avoid duplication and manual errors
  static const String _articleBaseFields = '''
    id
    title
    slug
    description
    ver
    coverImage
    mainImage
    backgroundImage
    favoritesCount
    favorited
    createdAt
    updatedAt
    status
    sequentialCode
    tags { id name }
    categories { id name }
    platforms { id name }
    engine { id name }
    author { id name image }
  ''';

  static const String _articleDetailFields = '''
    $_articleBaseFields
    body
    images { id url }
    downloads { id name url isActive vipOnly }
  ''';

  /// Fetch a list of articles with pagination and filtering
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
    final String graphqlQuery = '''
      query GetArticles(\$limit: Int!, \$offset: Int!, \$status: ArticleStatus, \$filter: ArticleFilterInput) {
        articles(limit: \$limit, offset: \$offset, status: \$status, filter: \$filter) {
          $_articleBaseFields
        }
        articlesCount(status: \$status, filter: \$filter)
      }
    ''';

    final Map<String, dynamic> filter = {
      if (query != null) 'q': query,
      if (tag != null) 'tag': tag,
      if (category != null) 'category': category,
      if (platform != null) 'platform': platform,
      if (engine != null) 'engine': engine,
      if (sequentialCode != null) 'sequentialCode': sequentialCode,
    };

    final data = await _apiClient.query(graphqlQuery, variables: {
      'limit': limit,
      'offset': offset,
      'status': status ?? 'PUBLISHED',
      'filter': filter.isEmpty ? null : filter,
    });

    final List? items = data['data']?['articles'];
    if (items == null) return ArticlesResponse(articles: [], articlesCount: 0);

    return ArticlesResponse(
      articles: items.map((json) => Article.fromJson(json)).toList(),
      articlesCount: data['data']?['articlesCount'] ?? items.length,
    );
  }

  /// Fetch a single article by ID, including all details and downloads
  Future<Article> getArticleById(int id, {Locale? language}) async {
    final String graphqlQuery = '''
      query GetArticleById(\$id: Int!, \$language: String) {
        article(id: \$id, language: \$language) { $_articleDetailFields }
      }
    ''';

    final data = await _apiClient.query(graphqlQuery, variables: {
      'id': id,
      'language': language?.languageCode,
    });

    final articleData = data['data']?['article'];
    if (articleData == null) throw Exception('Article not found');

    return Article.fromJson(articleData);
  }

  /// Fetch a single article by Slug
  Future<Article> getArticleBySlug(String slug, {Locale? language}) async {
    final String graphqlQuery = '''
      query GetArticleBySlug(\$slug: String!, \$language: String) {
        article(slug: \$slug, language: \$language) { $_articleDetailFields }
      }
    ''';

    final data = await _apiClient.query(graphqlQuery, variables: {
      'slug': slug,
      'language': language?.languageCode,
    });

    final articleData = data['data']?['article'];
    if (articleData == null) throw Exception('Article not found');

    return Article.fromJson(articleData);
  }

  /// Legacy helper for separate downloads fetch if needed
  Future<List<Download>> getDownloads(int articleId) async {
    final String graphqlQuery = '''
      query GetDownloads(\$articleId: Int!) {
        downloads(articleId: \$articleId) { id name url isActive vipOnly }
      }
    ''';

    final data = await _apiClient.query(graphqlQuery, variables: {
      'articleId': articleId,
    });

    final List downloadsData = data['data']?['downloads'] ?? [];
    return downloadsData.map((e) => Download.fromJson(e)).toList();
  }
}
