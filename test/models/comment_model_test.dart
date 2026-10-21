import 'package:chanolite/models/comment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommentAuthor Model Tests', () {
    test('CommentAuthor parses fromJson correctly', () {
      final json = {
        'username': 'john_doe',
        'bio': 'Gamer and dev',
        'image': 'https://example.com/avatar.png',
        'following': true,
      };

      final author = CommentAuthor.fromJson(json);

      expect(author.username, 'john_doe');
      expect(author.bio, 'Gamer and dev');
      expect(author.image, 'https://example.com/avatar.png');
      expect(author.following, isTrue);
    });

    test('CommentAuthor handles fallback name and missing fields', () {
      final json = {
        'name': 'fallback_name',
      };

      final author = CommentAuthor.fromJson(json);

      expect(author.username, 'fallback_name');
      expect(author.bio, isNull);
      expect(author.image, isNull);
      expect(author.following, isFalse);
    });

    test('CommentAuthor toJson and copyWith', () {
      final author = CommentAuthor(
        username: 'alice',
        bio: 'Hello',
        image: 'https://example.com/a.png',
        following: false,
      );

      final json = author.toJson();
      expect(json['username'], 'alice');
      expect(json['bio'], 'Hello');
      expect(json['following'], isFalse);

      final updated = author.copyWith(following: true, bio: 'Updated');
      expect(updated.following, isTrue);
      expect(updated.bio, 'Updated');
      expect(updated.username, 'alice');
    });
  });

  group('Comment Model Tests', () {
    test('Comment parses root comment and nested replies', () {
      final json = {
        'id': 101,
        'parentId': null,
        'body': 'This is an awesome game!',
        'createdAt': '2026-10-21T10:00:00.000Z',
        'updatedAt': '2026-10-21T10:05:00.000Z',
        'author': {
          'username': 'gamer1',
          'image': 'https://example.com/p.png',
          'following': false,
        },
        'replies': [
          {
            'id': 102,
            'parentId': 101,
            'body': 'I agree with you!',
            'createdAt': '2026-10-21T10:10:00.000Z',
            'author': {
              'username': 'gamer2',
            },
            'replies': [],
          }
        ],
      };

      final comment = Comment.fromJson(json);

      expect(comment.id, 101);
      expect(comment.parentId, isNull);
      expect(comment.body, 'This is an awesome game!');
      expect(comment.author.username, 'gamer1');
      expect(comment.replies.length, 1);

      final reply = comment.replies.first;
      expect(reply.id, 102);
      expect(reply.parentId, 101);
      expect(reply.body, 'I agree with you!');
      expect(reply.author.username, 'gamer2');
      expect(reply.replies, isEmpty);
    });

    test('Comment toJson and copyWith', () {
      final comment = Comment(
        id: 1,
        body: 'Root comment',
        createdAt: DateTime.parse('2026-10-21T12:00:00Z'),
        author: CommentAuthor(username: 'tester'),
      );

      final json = comment.toJson();
      expect(json['id'], 1);
      expect(json['body'], 'Root comment');
      expect(json['author']['username'], 'tester');

      final updated = comment.copyWith(body: 'Modified body');
      expect(updated.body, 'Modified body');
      expect(updated.id, 1);
    });
  });

  group('CommentsResponse Model Tests', () {
    test('CommentsResponse parses direct format', () {
      final json = {
        'comments': [
          {
            'id': 1,
            'body': 'First',
            'createdAt': '2026-10-21T12:00:00Z',
            'author': {'username': 'u1'},
          }
        ],
        'commentsCount': 1,
      };

      final response = CommentsResponse.fromJson(json);

      expect(response.comments.length, 1);
      expect(response.commentsCount, 1);
      expect(response.comments.first.body, 'First');
    });

    test('CommentsResponse parses wrapped data format (TransformInterceptor)', () {
      final json = {
        'data': {
          'comments': [
            {
              'id': 2,
              'body': 'Wrapped comment',
              'createdAt': '2026-10-21T12:00:00Z',
              'author': {'username': 'u2'},
            }
          ],
          'commentsCount': 10,
        },
        'statusCode': 200,
        'timestamp': '2026-10-21T12:00:00Z',
      };

      final response = CommentsResponse.fromJson(json);

      expect(response.comments.length, 1);
      expect(response.commentsCount, 10);
      expect(response.comments.first.id, 2);
      expect(response.comments.first.body, 'Wrapped comment');
    });
  });
}
