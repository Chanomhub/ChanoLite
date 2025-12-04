import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/models/download.dart';
import 'package:chanolite/services/api/article_service.dart';
import 'package:chanolite/services/api/article_detail_service.dart';
import 'dart:ui';

class ArticleRepository {
  final ArticleService _articleService;
  final ArticleDetailService _articleDetailService;

  ArticleRepository({
    ArticleService? articleService,
    ArticleDetailService? articleDetailService,
  })  : _articleService = articleService ?? ArticleService(),
        _articleDetailService = articleDetailService ?? ArticleDetailService();

  Future<ArticlesResponse> getArticles({
    int limit = 20,
    int offset = 0,
    String? query,
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
      author: author,
      favorited: favorited,
      tag: tag,
      category: category,
      platform: platform,
      status: status,
      engine: engine,
      ver: ver,
      version: version,
      hasMainImage: hasMainImage,
      hasImages: hasImages,
      sequentialCode: sequentialCode,
      returnFields: returnFields,
    );
  }

  Future<Article> getArticleById(int id, {Locale? language, String? returnFields}) async {
    return await _articleDetailService.getArticleById(id, language: language, returnFields: returnFields);
  }

  Future<Article> getArticleBySlug(String slug, {Locale? language, String? returnFields}) async {
    return await _articleDetailService.getArticleBySlug(slug, language: language, returnFields: returnFields);
  }

  Future<List<Download>> getDownloads(int articleId) async {
    return await _articleDetailService.getDownloads(articleId);
  }
}
