import 'package:chanolite/services/api/api_client.dart';
import 'package:chanolite/services/api/comment_service.dart';
import 'package:flutter_test/flutter_test.dart';

class MockApiClient extends ApiClient {
  String? lastGetEndpoint;
  String? lastPostEndpoint;
  dynamic lastPostBody;
  String? lastDeleteEndpoint;

  dynamic mockGetResponse;
  dynamic mockPostResponse;
  dynamic mockDeleteResponse;

  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? headers, bool isRetry = false}) async {
    lastGetEndpoint = endpoint;
    return mockGetResponse;
  }

  @override
  Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers, bool isRetry = false}) async {
    lastPostEndpoint = endpoint;
    lastPostBody = body;
    return mockPostResponse;
  }

  @override
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers, bool isRetry = false}) async {
    lastDeleteEndpoint = endpoint;
    return mockDeleteResponse;
  }
}

void main() {
  group('CommentService Tests', () {
    late MockApiClient mockApiClient;
    late CommentService commentService;

    setUp(() {
      mockApiClient = MockApiClient();
      commentService = CommentService(apiClient: mockApiClient);
    });

    test('getComments fetches comments correctly', () async {
      mockApiClient.mockGetResponse = {
        'data': {
          'comments': [
            {
              'id': 1,
              'parentId': null,
              'body': 'First comment',
              'createdAt': '2026-10-21T10:00:00Z',
              'author': {'username': 'user1'},
              'replies': [],
            }
          ],
          'commentsCount': 1,
        }
      };

      final result = await commentService.getComments('my-test-slug', page: 1, limit: 20);

      expect(mockApiClient.lastGetEndpoint, 'articles/my-test-slug/comments?page=1&limit=20');
      expect(result.comments.length, 1);
      expect(result.comments.first.body, 'First comment');
      expect(result.commentsCount, 1);
    });

    test('createComment posts root comment correctly', () async {
      mockApiClient.mockPostResponse = {
        'data': {
          'id': 10,
          'parentId': null,
          'body': 'New comment body',
          'createdAt': '2026-10-21T12:00:00Z',
          'author': {'username': 'commenter'},
          'replies': [],
        }
      };

      final created = await commentService.createComment('test-game', body: 'New comment body');

      expect(mockApiClient.lastPostEndpoint, 'articles/test-game/comments');
      expect(mockApiClient.lastPostBody, {'body': 'New comment body'});
      expect(created.id, 10);
      expect(created.body, 'New comment body');
    });

    test('createComment posts reply comment correctly', () async {
      mockApiClient.mockPostResponse = {
        'data': {
          'id': 11,
          'parentId': 10,
          'body': 'Reply body',
          'createdAt': '2026-10-21T12:05:00Z',
          'author': {'username': 'replier'},
          'replies': [],
        }
      };

      final created = await commentService.createComment(
        'test-game',
        body: 'Reply body',
        parentId: 10,
      );

      expect(mockApiClient.lastPostEndpoint, 'articles/test-game/comments');
      expect(mockApiClient.lastPostBody, {'body': 'Reply body', 'parentId': 10});
      expect(created.id, 11);
      expect(created.parentId, 10);
    });

    test('deleteComment calls delete endpoint correctly', () async {
      mockApiClient.mockDeleteResponse = {
        'data': {
          'id': 10,
          'body': 'Deleted',
          'createdAt': '2026-10-21T12:00:00Z',
          'author': {'username': 'commenter'},
        }
      };

      final deleted = await commentService.deleteComment('test-game', 10);

      expect(mockApiClient.lastDeleteEndpoint, 'articles/test-game/comments/10');
      expect(deleted.id, 10);
    });
  });
}
