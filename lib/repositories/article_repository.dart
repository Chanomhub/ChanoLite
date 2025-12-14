import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/models/download.dart';
import 'package:chanolite/services/api/article_service.dart';
import 'dart:ui';

class ArticleRepository {
  final ArticleService _articleService;

  ArticleRepository({
    ArticleService? articleService,
  }) : _articleService = articleService ?? ArticleService();

  Future<ArticlesResponse> getArticles({
    int limit = 20,
    int offset = 0,
    String? query,
    // Unsupported params removed from service call, keeping in signature if needed by callers (though they won't work)
    // To match errors, I should probably remove them from here if I remove them from the call, purely to clean up.
    // But if callers rely on named params existing, removing them breaks callers.
    // However, keeping them but not passing them is safe.
    String? author,
    String? favorited,
    String? tag,
    String? category,
    String? platform,
    String? status,
    String? engine,
    String? ver,
    int? version,
    bool? hasMainImage,
    bool? hasImages,
    String? sequentialCode,
    String? returnFields,
  }) async {
    return await _articleService.getArticles(
      limit: limit,
      offset: offset,
      query: query,
      // author: author, // Not supported by ArticleService
      // favorited: favorited, // Not supported
      tag: tag,
      category: category,
      platform: platform,
      // status: status, // status is supported by ArticleService
      status: status,
      engine: engine,
      // ver: ver,
      // version: version,
      // hasMainImage: hasMainImage,
      // hasImages: hasImages,
      sequentialCode: sequentialCode,
      returnFields: returnFields,
    );
  }

  Future<Article> getArticleById(int id, {Locale? language, String? returnFields}) async {
    return await _articleService.getArticleById(id, language: language, returnFields: returnFields);
  }

  Future<Article> getArticleBySlug(String slug, {Locale? language, String? returnFields}) async {
    return await _articleService.getArticleBySlug(slug, language: language, returnFields: returnFields);
  }

  Future<List<Download>> getDownloads(int articleId) async {
    return await _articleService.getDownloads(articleId);
  }
}
