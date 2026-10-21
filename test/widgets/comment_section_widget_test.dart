import 'package:chanolite/l10n/generated/app_localizations.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/models/comment_model.dart';
import 'package:chanolite/models/user_model.dart';
import 'package:chanolite/services/api/comment_service.dart';
import 'package:chanolite/widgets/comment_section_widget.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart'
    hide User, Profile, Download, Article, Author;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeCommentService extends CommentService {
  List<Comment> mockComments = [];
  int mockCount = 0;
  bool shouldThrow = false;

  String? createdSlug;
  String? createdBody;
  int? createdParentId;
  int? deletedCommentId;

  @override
  Future<CommentsResponse> getComments(String slug, {int page = 1, int limit = 50}) async {
    if (shouldThrow) {
      throw Exception('Network error');
    }
    return CommentsResponse(comments: mockComments, commentsCount: mockCount);
  }

  @override
  Future<Comment> createComment(String slug, {required String body, int? parentId}) async {
    createdSlug = slug;
    createdBody = body;
    createdParentId = parentId;
    return Comment(
      id: 999,
      parentId: parentId,
      body: body,
      createdAt: DateTime.now(),
      author: CommentAuthor(username: 'active_user'),
    );
  }

  @override
  Future<Comment> deleteComment(String slug, int commentId) async {
    deletedCommentId = commentId;
    return Comment(
      id: commentId,
      body: 'Deleted',
      createdAt: DateTime.now(),
      author: CommentAuthor(username: 'active_user'),
    );
  }
}

class FakeAuthManager extends ChangeNotifier implements AuthManager {
  User? _active;
  bool _authenticated = false;

  @override
  User? get activeAccount => _active;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  List<User> get accounts => _active != null ? [_active!] : [];

  void setLoggedIn(User user) {
    _active = user;
    _authenticated = true;
    notifyListeners();
  }

  void setLoggedOut() {
    _active = null;
    _authenticated = false;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({
    required FakeCommentService commentService,
    required FakeAuthManager authManager,
    String slug = 'test-article-slug',
    String? articleAuthor = 'game_dev',
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthManager>.value(value: authManager),
        Provider<CommentService>.value(value: commentService),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ArticleCommentsSection(
              slug: slug,
              articleAuthor: articleAuthor,
              commentService: commentService,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Renders empty state when there are no comments', (tester) async {
    final commentService = FakeCommentService()..mockComments = []..mockCount = 0;
    final authManager = FakeAuthManager();

    await tester.pumpWidget(buildTestWidget(
      commentService: commentService,
      authManager: authManager,
    ));

    await tester.pumpAndSettle();

    expect(find.text('Comments'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('No comments yet'), findsOneWidget);
    expect(find.text('Log in to join the conversation'), findsOneWidget);
  });

  testWidgets('Renders comments and nested replies correctly', (tester) async {
    final commentService = FakeCommentService()
      ..mockComments = [
        Comment(
          id: 1,
          body: 'Great release!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          author: CommentAuthor(username: 'game_dev'),
          replies: [
            Comment(
              id: 2,
              parentId: 1,
              body: 'Thanks for playing!',
              createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
              author: CommentAuthor(username: 'fan_boy'),
              replies: [],
            )
          ],
        )
      ]
      ..mockCount = 2;

    final authManager = FakeAuthManager();

    await tester.pumpWidget(buildTestWidget(
      commentService: commentService,
      authManager: authManager,
    ));

    await tester.pumpAndSettle();

    expect(find.text('Great release!'), findsOneWidget);
    expect(find.text('game_dev'), findsOneWidget);
    expect(find.text('Author'), findsOneWidget); // OP / Author badge
    expect(find.text('Thanks for playing!'), findsOneWidget);
    expect(find.text('fan_boy'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // Count badge
  });

  testWidgets('Allows authenticated user to post a comment', (tester) async {
    final commentService = FakeCommentService()..mockComments = []..mockCount = 0;
    final authManager = FakeAuthManager()
      ..setLoggedIn(User(
        roles: ['user'],
        email: 'user@example.com',
        username: 'active_user',
        points: 0,
        token: 'token123',
        socialMediaLinks: [],
      ));

    await tester.pumpWidget(buildTestWidget(
      commentService: commentService,
      authManager: authManager,
    ));

    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hello world comment!');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(commentService.createdBody, 'Hello world comment!');
    expect(commentService.createdSlug, 'test-article-slug');
    expect(find.text('Hello world comment!'), findsOneWidget);
  });

  testWidgets('Allows replying to a comment', (tester) async {
    final commentService = FakeCommentService()
      ..mockComments = [
        Comment(
          id: 50,
          body: 'Original discussion',
          createdAt: DateTime.now(),
          author: CommentAuthor(username: 'bob'),
          replies: [],
        )
      ]
      ..mockCount = 1;

    final authManager = FakeAuthManager()
      ..setLoggedIn(User(
        roles: ['user'],
        email: 'user@example.com',
        username: 'active_user',
        points: 0,
        token: 'token123',
        socialMediaLinks: [],
      ));

    await tester.pumpWidget(buildTestWidget(
      commentService: commentService,
      authManager: authManager,
    ));

    await tester.pumpAndSettle();

    // Tap reply on bob's comment
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    // Verify reply banner
    expect(find.text('Replying to @bob'), findsWidgets);

    // Enter reply
    await tester.enterText(find.byType(TextField), 'My response to Bob');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(commentService.createdParentId, 50);
    expect(commentService.createdBody, 'My response to Bob');
    expect(find.text('My response to Bob'), findsOneWidget);
  });

  testWidgets('Allows deleting own comment with confirmation dialog', (tester) async {
    final commentService = FakeCommentService()
      ..mockComments = [
        Comment(
          id: 77,
          body: 'Comment to be deleted',
          createdAt: DateTime.now(),
          author: CommentAuthor(username: 'active_user'),
          replies: [],
        )
      ]
      ..mockCount = 1;

    final authManager = FakeAuthManager()
      ..setLoggedIn(User(
        roles: ['user'],
        email: 'user@example.com',
        username: 'active_user',
        points: 0,
        token: 'token123',
        socialMediaLinks: [],
      ));

    await tester.pumpWidget(buildTestWidget(
      commentService: commentService,
      authManager: authManager,
    ));

    await tester.pumpAndSettle();

    // The delete icon should be visible for active_user
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Delete comment'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this comment?'), findsOneWidget);

    // Confirm deletion
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(commentService.deletedCommentId, 77);
    expect(find.text('Comment to be deleted'), findsNothing);
  });
}
