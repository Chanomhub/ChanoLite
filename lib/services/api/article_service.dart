import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/models/download.dart';
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

  Future<Article> getArticleBySlug(String? slug, {String? language}) async {
    if (slug == null || slug.isEmpty) {
      throw Exception('Slug cannot be null or empty');
    }

    const String articleQueryString = r'''
      query ArticleQuery($slug: String, $language: String) {
        article(slug: $slug, language: $language) {
          id
          slug
          sequentialCode
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
          engine {
            name
          }
          favoritesCount
          createdAt
          updatedAt
        }
      }
    ''';

    const String articleOnlyQuery = r'''
      query ArticleQuery($slug: String) {
        article(slug: $slug) {
          id
        }
      }
    ''';
    final articleResponse = await _apiClient.query(articleOnlyQuery, variables: {'slug': slug}) as Map<String, dynamic>;
    final articleId = int.parse(articleResponse['data']['article']['id']);

    // Now, query both article details and downloads in a single request using the obtained articleId.
    // This reduces the total API calls from three (article by slug, downloads by ID, article by ID)
    // to two (article by slug to get ID, then combined article+downloads by ID).
    // The ideal solution would be for the backend to allow querying downloads by slug directly,
    // or to include downloads as a subfield of the article query.
    const String combinedQueryString = r'''
      query ArticleWithDownloads($id: Int!, $slug: String, $language: String) {
        article(id: $id, slug: $slug, language: $language) {
          id
          slug
          sequentialCode
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
          engine {
            name
          }
          favoritesCount
          createdAt
          updatedAt
        }
        downloads(articleId: $id) {
          id
          name
          url
          isActive
          vipOnly
        }
      }
    ''';

    final response = await _apiClient.query(
      combinedQueryString,
      variables: {
        'id': articleId,
        'slug': slug, // Pass slug as well, in case the backend uses it for article details even with ID
        'language': language,
      },
    ) as Map<String, dynamic>;

    final articleJson = response['data']['article'] as Map<String, dynamic>;
    final downloadsJson = response['data']['downloads'];

    articleJson['downloads'] = downloadsJson;

    return Article.fromJson(articleJson);
  }

  Future<Article> getArticleById(int id, {String? language}) async {
    const String combinedQueryString = r'''
      query ArticleWithDownloads($id: Int!, $language: String) {
        article(id: $id, language: $language) {
          id
          slug
          sequentialCode
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
          engine {
            name
          }
          favoritesCount
          createdAt
          updatedAt
        }
        downloads(articleId: $id) {
          id
          name
          url
          isActive
          vipOnly
        }
      }
    ''';

    final response = await _apiClient.query(
      combinedQueryString,
      variables: {
        'id': id,
        'language': language,
      },
    ) as Map<String, dynamic>;

    final articleJson = response['data']['article'] as Map<String, dynamic>;
    final downloadsJson = response['data']['downloads'];

    articleJson['downloads'] = downloadsJson;

    return Article.fromJson(articleJson);
  }

  Future<List<Download>> getDownloads(int articleId) async {
    const String query = r'''
      query GetDownloads($articleId: Int!) {
        downloads(articleId: $articleId) {
          id
          name
          url
          isActive
          vipOnly
        }
      }
    ''';

    final response = await _apiClient.query(
      query,
      variables: {'articleId': articleId},
    ) as Map<String, dynamic>;

    final downloadsJson = response['data']['downloads'] as List;
    return downloadsJson.map((e) => Download.fromJson(e)).toList();
  }
}