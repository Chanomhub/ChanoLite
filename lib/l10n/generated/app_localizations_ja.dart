// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get helloWorld => 'こんにちは世界！';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get english => '英語';

  @override
  String get thai => 'タイ語';

  @override
  String get japanese => '日本語';

  @override
  String get chinese => '中国語';

  @override
  String get comments => 'コメント';

  @override
  String get noComments => 'まだコメントはありません';

  @override
  String get beTheFirstToComment => '最初のコメントを投稿しましょう！';

  @override
  String get writeComment => 'コメントを入力...';

  @override
  String get reply => '返信';

  @override
  String replyingTo(String username) {
    return '@$username に返信中';
  }

  @override
  String get cancelReply => '返信をキャンセル';

  @override
  String get send => '送信';

  @override
  String get deleteComment => 'コメントを削除';

  @override
  String get deleteCommentConfirm => 'このコメントを削除してもよろしいですか？';

  @override
  String get delete => '削除';

  @override
  String get cancel => 'キャンセル';

  @override
  String get loginToComment => 'コメントを投稿するにはログインしてください';

  @override
  String get login => 'ログイン';

  @override
  String get commentPosted => 'コメントを投稿しました';

  @override
  String get commentDeleted => 'コメントを削除しました';

  @override
  String get failedToLoadComments => 'コメントの読み込みに失敗しました';

  @override
  String get failedToPostComment => 'コメントの投稿に失敗しました';

  @override
  String get failedToDeleteComment => 'コメントの削除に失敗しました';

  @override
  String get retry => '再試行';
}
