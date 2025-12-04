import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/models/download.dart';
import 'package:chanolite/services/api/article_service.dart';

class ArticleRepository {
  final ArticleService _articleService;

  ArticleRepository({ArticleService? articleService})
      : _articleService = articleService ?? ArticleService();

  Future<Article> getArticleById(int id, {String? language}) async {
    return await _articleService.getArticleById(id, language: language);
  }

  Future<Article> getArticleBySlug(String slug, {String? language}) async {
    return await _articleService.getArticleBySlug(slug, language: language);
  }
  Future<List<Download>> getDownloads(int articleId) async {
    return await _articleService.getDownloads(articleId);
  }
}
