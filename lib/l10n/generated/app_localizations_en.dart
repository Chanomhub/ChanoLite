// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get thai => 'Thai';

  @override
  String get japanese => 'Japanese';

  @override
  String get chinese => 'Chinese';

  @override
  String get comments => 'Comments';

  @override
  String get noComments => 'No comments yet';

  @override
  String get beTheFirstToComment => 'Be the first to share your thoughts!';

  @override
  String get writeComment => 'Write a comment...';

  @override
  String get reply => 'Reply';

  @override
  String replyingTo(String username) {
    return 'Replying to @$username';
  }

  @override
  String get cancelReply => 'Cancel reply';

  @override
  String get send => 'Send';

  @override
  String get deleteComment => 'Delete comment';

  @override
  String get deleteCommentConfirm =>
      'Are you sure you want to delete this comment?';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get loginToComment => 'Log in to join the conversation';

  @override
  String get login => 'Log In';

  @override
  String get commentPosted => 'Comment posted successfully';

  @override
  String get commentDeleted => 'Comment deleted successfully';

  @override
  String get failedToLoadComments => 'Failed to load comments';

  @override
  String get failedToPostComment => 'Failed to post comment';

  @override
  String get failedToDeleteComment => 'Failed to delete comment';

  @override
  String get retry => 'Retry';
}
