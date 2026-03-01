import 'dart:ui';
import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/models/download.dart';
import 'package:chanolite/services/api/api_client.dart';
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
    // Use SDK for fetching articles
    final response = await sdk.articles.getAllPaginated(
      options: sdk_models.ArticleListOptions(
        limit: limit,
        offset: offset,
        status: status ?? 'PUBLISHED',
        filter: sdk_models.ArticleFilter(
          q: query,
          tag: tag,
          category: category,
          platform: platform,
          engine: engine,
          sequentialCode: sequentialCode,
        ),
      ),
    );

    return ArticlesResponse(
      articles: response.items.map((item) => Article(
        id: item.id,
        title: item.title,
        slug: item.slug,
        description: item.description,
        body: '',
        ver: item.ver,
        version: null,
        createdAt: DateTime.tryParse(item.createdAt ?? ''),
        updatedAt: DateTime.tryParse(item.updatedAt ?? '') ?? DateTime.now(),
        status: item.status,
        engine: item.engine?.name,
        mainImage: item.mainImage,
        images: item.images?.map((e) => e.url).toList() ?? [],
        backgroundImage: null,
        coverImage: item.coverImage,
        tagList: item.tags?.map((e) => e.name).toList() ?? [],
        categoryList: item.categories?.map((e) => e.name).toList() ?? [],
        platformList: item.platforms?.map((e) => e.name).toList() ?? [],
        author: Author(id: item.author.id?.toString(), name: item.author.name, image: item.author.image),
        favorited: item.favorited ?? false,
        favoritesCount: item.favoritesCount,
        sequentialCode: item.sequentialCode,
        downloads: [],
      )).toList(),
      articlesCount: response.total,
    );
  }

  Future<Article> getArticleBySlug(String slug, {Locale? language, String? returnFields}) async {
    final result = await sdk.articles.getBySlug(
      slug,
      options: sdk_models.ArticleQueryOptions(
        language: language?.languageCode,
      ),
    );
    if (result == null) throw Exception('Article not found');
    return Article(
        id: result.id,
        title: result.title,
        slug: result.slug,
        description: result.description,
        body: result.body,
        ver: result.ver,
        version: int.tryParse(result.version ?? ''),
        createdAt: DateTime.tryParse(result.createdAt),
        updatedAt: DateTime.tryParse(result.updatedAt) ?? DateTime.now(),
        status: result.status,
        engine: result.engine.name,
        mainImage: result.mainImage,
        images: result.images.map((e) => e.url).toList(),
        backgroundImage: result.backgroundImage,
        coverImage: result.coverImage,
        tagList: result.tags.map((e) => e.name).toList(),
        categoryList: result.categories.map((e) => e.name).toList(),
        platformList: result.platforms.map((e) => e.name).toList(),
        author: Author(id: result.author.id?.toString(), name: result.author.name, image: result.author.image),
        favorited: result.favorited,
        favoritesCount: result.favoritesCount,
        sequentialCode: result.sequentialCode,
        downloads: result.downloads?.map((e) => Download(id: e.id.toString(), name: e.name, url: e.url, isActive: e.isActive, vipOnly: e.vipOnly)).toList() ?? [],
    );
  }

  Future<Article> getArticleById(int id, {Locale? language, String? returnFields}) async {
    // SDK 1.0.1 doesn't have getById, fallback to manual query
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
      tags { name }
      categories { name }
      platforms { name }
      author { name image }
      downloads { name url }
    ''';

    final String fields = returnFields ?? defaultFields;
    final String graphqlQuery = '''
      query GetArticle(\$id: Int, \$language: String) {
        public {
          article(id: \$id, language: \$language) { $fields }
        }
      }
    ''';

    final data = await _apiClient.query(graphqlQuery, variables: {
      'id': id,
      'language': language?.languageCode,
    });

    if (data['data'] != null && data['data']['public'] != null && data['data']['public']['article'] != null) {
      return Article.fromJson(data['data']['public']['article']);
    } else {
      throw Exception('Failed to load article by ID');
    }
  }

  Future<List<Download>> getDownloads(int articleId) async {
    final result = await sdk.downloads.getByArticle(articleId);
    return result.map((e) => Download(
      id: e.id.toString(),
      name: e.name ?? 'Official Download',
      url: e.url,
      isActive: e.isActive,
      vipOnly: e.vipOnly,
    )).toList();
  }
}

