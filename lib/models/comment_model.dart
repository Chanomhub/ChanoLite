import 'package:chanolite/utils/image_url_helper.dart';

class CommentAuthor {
  final String username;
  final String? bio;
  final String? image;
  final bool following;

  CommentAuthor({
    required this.username,
    this.bio,
    this.image,
    this.following = false,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    return CommentAuthor(
      username: json['username']?.toString() ?? json['name']?.toString() ?? 'Anonymous',
      bio: json['bio']?.toString(),
      image: ImageUrlHelper.resolve(json['image']?.toString()),
      following: json['following'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'bio': bio,
      'image': image,
      'following': following,
    };
  }

  CommentAuthor copyWith({
    String? username,
    String? bio,
    String? image,
    bool? following,
  }) {
    return CommentAuthor(
      username: username ?? this.username,
      bio: bio ?? this.bio,
      image: image ?? this.image,
      following: following ?? this.following,
    );
  }
}

class Comment {
  final int id;
  final int? parentId;
  final String body;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final CommentAuthor author;
  final List<Comment> replies;

  Comment({
    required this.id,
    this.parentId,
    required this.body,
    required this.createdAt,
    this.updatedAt,
    required this.author,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    int? parseOptionalId(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final rawReplies = json['replies'];
    List<Comment> repliesList = [];
    if (rawReplies is List) {
      for (final item in rawReplies) {
        if (item is Map<String, dynamic>) {
          repliesList.add(Comment.fromJson(item));
        } else if (item is Map) {
          repliesList.add(Comment.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    Map<String, dynamic>? authorMap;
    if (json['author'] is Map<String, dynamic>) {
      authorMap = json['author'] as Map<String, dynamic>;
    } else if (json['author'] is Map) {
      authorMap = Map<String, dynamic>.from(json['author'] as Map);
    }

    return Comment(
      id: parseId(json['id']),
      parentId: parseOptionalId(json['parentId']),
      body: json['body']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? parseDate(json['updatedAt']) : null,
      author: authorMap != null ? CommentAuthor.fromJson(authorMap) : CommentAuthor(username: 'Anonymous'),
      replies: repliesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'author': author.toJson(),
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }

  Comment copyWith({
    int? id,
    int? parentId,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    CommentAuthor? author,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      replies: replies ?? this.replies,
    );
  }
}

class CommentsResponse {
  final List<Comment> comments;
  final int commentsCount;

  CommentsResponse({
    required this.comments,
    required this.commentsCount,
  });

  factory CommentsResponse.fromJson(Map<String, dynamic> json) {
    // Note: TransformInterceptor wraps response in { data: { comments: [...], commentsCount: ... } }
    Map<String, dynamic> payload = json;
    if (json['data'] is Map<String, dynamic>) {
      payload = json['data'] as Map<String, dynamic>;
    } else if (json['data'] is Map) {
      payload = Map<String, dynamic>.from(json['data'] as Map);
    }

    final rawComments = payload['comments'];
    List<Comment> commentsList = [];
    if (rawComments is List) {
      for (final item in rawComments) {
        if (item is Map<String, dynamic>) {
          commentsList.add(Comment.fromJson(item));
        } else if (item is Map) {
          commentsList.add(Comment.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final count = payload['commentsCount'];
    final commentsCount = (count is num)
        ? count.toInt()
        : (count is String ? int.tryParse(count) ?? commentsList.length : commentsList.length);

    return CommentsResponse(
      comments: commentsList,
      commentsCount: commentsCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comments': comments.map((c) => c.toJson()).toList(),
      'commentsCount': commentsCount,
    };
  }
}
