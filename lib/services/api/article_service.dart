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
    const String queryString = r"""
      query MyQuery(
        $limit: Int,
        $offset: Int,
        $status: ArticleStatus,
        $filter: ArticleFilterInput
      ) {
        articles(
          limit: $limit,
          offset: $offset,
          status: $status,
          filter: $filter
        ) {
          author {
            name
            image
          }
          categories {
            name
          }
          coverImage
          createdAt
          creators {
            name
          }
          description
          favorited
          favoritesCount
          id
          slug
          images {
            url
          }
          mainImage
          platforms {
            name
          }
          tags {
            name
          }
          title
          updatedAt
          ver
          body
          status
          backgroundImage
        }
      }
    """;

    final filter = {
      'q': query ?? "",
      'author': author ?? "",
      'favorited': favorited ?? "",
      'category': category ?? "",
      'platform': platform ?? "",
      'engine': engine ?? "",
      'sequentialCode': sequentialCode ?? "",
    };

    final variables = {
      'limit': limit,
      'offset': offset,
      'status': status,
      'filter': filter,
    };

    final data = await _apiClient.query(queryString, variables: variables) as Map<String, dynamic>;
    final articlesData = data['data'];
    if (articlesData == null || articlesData['articles'] == null) {
      return ArticlesResponse(articles: [], articlesCount: 0);
    }
    return ArticlesResponse.fromJson(articlesData);
  }

  Future<Article> getArticleBySlug(String? slug) async {
    if (slug == null || slug.isEmpty) {
      throw Exception('Slug cannot be null or empty');
    }

    const String articleQueryString = r'''
      query ArticleQuery($slug: String) {
        article(slug: $slug) {
          id
          slug
          title
          description
          body
          status
          ver
          coverImage
          backgroundImage
          images {
            url
          }
          author {
            name
            image
          }
          creators {
            name
          }
          categories {
            name
          }
          tags {
            name
          }
          platforms {
            name
          }
          favoritesCount
          createdAt
          updatedAt
        }
      }
    ''';

    final articleResponse = await _apiClient.query(articleQueryString, variables: {'slug': slug}) as Map<String, dynamic>;
    final articleJson = articleResponse['data']['article'] as Map<String, dynamic>;
    final articleId = int.parse(articleJson['id']);

    const String downloadsQueryString = r'''
      query DownloadsQuery($articleId: Int!) {
        downloads(articleId: $articleId) {
          id
          name
          url
          isActive
          vipOnly
        }
      }
    ''';

    final downloadsResponse = await _apiClient.query(downloadsQueryString, variables: {'articleId': articleId}) as Map<String, dynamic>;
    final downloadsJson = downloadsResponse['data']['downloads'];

    articleJson['downloads'] = downloadsJson;

    return Article.fromJson(articleJson);
  }

  Future<Article> getArticleById(int id) async {
    const String articleQueryString = r'''
      query ArticleQuery($id: Int!) {
        article(id: $id) {
          id
          slug
          title
          description
          body
          status
          ver
          coverImage
          backgroundImage
          images {
            url
          }
          author {
            name
            image
          }
          creators {
            name
          }
          categories {
            name
          }
          tags {
            name
          }
          platforms {
            name
          }
          favoritesCount
          createdAt
          updatedAt
        }
      }
    ''';

    final articleResponse = await _apiClient.query(articleQueryString, variables: {'id': id}) as Map<String, dynamic>;
    final articleJson = articleResponse['data']['article'] as Map<String, dynamic>;

    const String downloadsQueryString = r'''
      query DownloadsQuery($articleId: Int!) {
        downloads(articleId: $articleId) {
          name
          url
          isActive
          vipOnly
        }
      }
    ''';

    final downloadsResponse = await _apiClient.query(downloadsQueryString, variables: {'articleId': id}) as Map<String, dynamic>;
    final downloadsJson = downloadsResponse['data']['downloads'];

    articleJson['downloads'] = downloadsJson;

    return Article.fromJson(articleJson);
  }
}