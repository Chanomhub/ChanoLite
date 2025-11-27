import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/repositories/article_repository.dart';
import 'package:chanolite/services/cache_service.dart';
import 'package:flutter/foundation.dart';

class ArticleDetailManager extends ChangeNotifier {
  final ArticleRepository _repository;
  final CacheService _cacheService;

  Article? _article;
  bool _isLoading = false;
  String? _error;

  Article? get article => _article;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ArticleDetailManager({
    required ArticleRepository repository,
    required CacheService cacheService,
  })  : _repository = repository,
        _cacheService = cacheService;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadArticle(Article initialArticle) async {
    _article = initialArticle;
    _isLoading = true;
    _error = null;
    
    // Notify immediately to show initial data
    if (!_isDisposed) notifyListeners();

    final cacheKey = 'article_${initialArticle.id}';

    // Try to get from cache first if not fully loaded or just to be sure
    final cachedArticle = _cacheService.get(cacheKey);
    if (cachedArticle != null && cachedArticle is Article) {
      _article = cachedArticle;
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return;
    }

    try {
      // Smart loading: If we already have details (e.g. from Home Screen), only fetch downloads
      if (initialArticle.title.isNotEmpty && initialArticle.body.isNotEmpty) {
        final downloads = await _repository.getDownloads(initialArticle.id);
        if (_isDisposed) return;

        _article = initialArticle.copyWith(downloads: downloads);
      } else {
        // Otherwise, fetch full article
        Article fetchedArticle;
        if (initialArticle.slug != null && initialArticle.slug!.isNotEmpty) {
          fetchedArticle = await _repository.getArticleBySlug(initialArticle.slug!);
        } else {
          fetchedArticle = await _repository.getArticleById(initialArticle.id);
        }
        if (_isDisposed) return;
        _article = fetchedArticle;
      }

      _cacheService.set(cacheKey, _article);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_isDisposed) return;
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
