import 'package:chanolite/models/article_model.dart';
import 'api_client.dart';

class ArticleService {
  final ApiClient _apiClient;

  ArticleService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

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
  }) async {
    final queryParameters = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (query != null && query.isNotEmpty) 'q': query,
      if (author != null) 'author': author,
      if (favorited != null) 'favorited': favorited,
      if (tag != null) 'tag': tag,
      if (category != null) 'category': category,
      if (platform != null) 'platform': platform,
      if (status != null) 'status': status,
      if (engine != null) 'engine': engine,
      if (ver != null) 'ver': ver,
      if (version != null) 'version': version.toString(),
      if (hasMainImage != null) 'hasMainImage': hasMainImage.toString(),
      if (hasImages != null) 'hasImages': hasImages.toString(),
      if (sequentialCode != null) 'sequentialCode': sequentialCode,
    };

    final endpoint = 'articles?${Uri(queryParameters: queryParameters).query}';
    final data = await _apiClient.get(endpoint) as Map<String, dynamic>;
    return ArticlesResponse.fromJson(data);
  }

  Future<Article> getArticleBySlug(String slug) async {
    final data = await _apiClient.get('articles/$slug') as Map<String, dynamic>;
    return Article.fromJson(data['article']);
  }
}
