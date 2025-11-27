import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/models/download.dart';
import 'package:chanolite/services/api/article_service.dart';

class ArticleRepository {
  final ArticleService _articleService;

  ArticleRepository({ArticleService? articleService})
      : _articleService = articleService ?? ArticleService();

  Future<Article> getArticleById(int id) async {
    return await _articleService.getArticleById(id);
  }

  Future<Article> getArticleBySlug(String slug) async {
    return await _articleService.getArticleBySlug(slug);
  }
  Future<List<Download>> getDownloads(int articleId) async {
    return await _articleService.getDownloads(articleId);
  }
}
