// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get helloWorld => '你好世界！';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get english => '英语';

  @override
  String get thai => '泰语';

  @override
  String get japanese => '日语';

  @override
  String get chinese => '中文';

  @override
  String get comments => '评论';

  @override
  String get noComments => '暂无评论';

  @override
  String get beTheFirstToComment => '来抢沙发吧！';

  @override
  String get writeComment => '写下你的评论...';

  @override
  String get reply => '回复';

  @override
  String replyingTo(String username) {
    return '回复 @$username';
  }

  @override
  String get cancelReply => '取消回复';

  @override
  String get send => '发送';

  @override
  String get deleteComment => '删除评论';

  @override
  String get deleteCommentConfirm => '确定要删除这条评论吗？';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get loginToComment => '登录后参与评论';

  @override
  String get login => '登录';

  @override
  String get commentPosted => '评论发表成功';

  @override
  String get commentDeleted => '评论已删除';

  @override
  String get failedToLoadComments => '加载评论失败';

  @override
  String get failedToPostComment => '发表评论失败';

  @override
  String get failedToDeleteComment => '删除评论失败';

  @override
  String get retry => '重试';
}
