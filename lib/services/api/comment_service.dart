import 'package:chanolite/models/comment_model.dart';
import 'package:chanolite/services/api/api_client.dart';

class CommentService {
  final ApiClient _apiClient;

  CommentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetch comments for a given article slug
  Future<CommentsResponse> getComments(
    String slug, {
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = 'page=$page&limit=$limit';
    final response = await _apiClient.get('articles/$slug/comments?$queryParams');

    if (response is Map<String, dynamic>) {
      return CommentsResponse.fromJson(response);
    } else if (response is Map) {
      return CommentsResponse.fromJson(Map<String, dynamic>.from(response));
    }
    return CommentsResponse(comments: [], commentsCount: 0);
  }

  /// Create a comment or reply for an article
  Future<Comment> createComment(
    String slug, {
    required String body,
    int? parentId,
  }) async {
    final payload = <String, dynamic>{
      'body': body,
      if (parentId != null) 'parentId': parentId,
    };

    final response = await _apiClient.post('articles/$slug/comments', body: payload);

    Map<String, dynamic> dataMap = <String, dynamic>{};
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        dataMap = response['data'] as Map<String, dynamic>;
      } else if (response['data'] is Map) {
        dataMap = Map<String, dynamic>.from(response['data'] as Map);
      } else {
        dataMap = response;
      }
    } else if (response is Map) {
      final converted = Map<String, dynamic>.from(response);
      if (converted['data'] is Map) {
        dataMap = Map<String, dynamic>.from(converted['data'] as Map);
      } else {
        dataMap = converted;
      }
    }

    return Comment.fromJson(dataMap);
  }

  /// Delete a comment by ID
  Future<Comment> deleteComment(String slug, int commentId) async {
    final response = await _apiClient.delete('articles/$slug/comments/$commentId');

    Map<String, dynamic> dataMap = <String, dynamic>{};
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        dataMap = response['data'] as Map<String, dynamic>;
      } else if (response['data'] is Map) {
        dataMap = Map<String, dynamic>.from(response['data'] as Map);
      } else {
        dataMap = response;
      }
    } else if (response is Map) {
      final converted = Map<String, dynamic>.from(response);
      if (converted['data'] is Map) {
        dataMap = Map<String, dynamic>.from(converted['data'] as Map);
      } else {
        dataMap = converted;
      }
    }

    return Comment.fromJson(dataMap);
  }
}
