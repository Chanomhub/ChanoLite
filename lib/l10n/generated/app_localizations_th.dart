// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get helloWorld => 'สวัสดีชาวโลก!';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get language => 'ภาษา';

  @override
  String get english => 'อังกฤษ';

  @override
  String get thai => 'ไทย';

  @override
  String get japanese => 'ญี่ปุ่น';

  @override
  String get chinese => 'จีน';

  @override
  String get comments => 'ความคิดเห็น';

  @override
  String get noComments => 'ยังไม่มีความคิดเห็น';

  @override
  String get beTheFirstToComment => 'เป็นคนแรกที่แสดงความคิดเห็น!';

  @override
  String get writeComment => 'เขียนความคิดเห็น...';

  @override
  String get reply => 'ตอบกลับ';

  @override
  String replyingTo(String username) {
    return 'ตอบกลับ @$username';
  }

  @override
  String get cancelReply => 'ยกเลิกการตอบกลับ';

  @override
  String get send => 'ส่ง';

  @override
  String get deleteComment => 'ลบความคิดเห็น';

  @override
  String get deleteCommentConfirm =>
      'คุณแน่ใจหรือไม่ว่าต้องการลบความคิดเห็นนี้?';

  @override
  String get delete => 'ลบ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get loginToComment => 'เข้าสู่ระบบเพื่อแสดงความคิดเห็น';

  @override
  String get login => 'เข้าสู่ระบบ';

  @override
  String get commentPosted => 'ส่งความคิดเห็นสำเร็จ';

  @override
  String get commentDeleted => 'ลบความคิดเห็นแล้ว';

  @override
  String get failedToLoadComments => 'โหลดความคิดเห็นไม่สำเร็จ';

  @override
  String get failedToPostComment => 'ส่งความคิดเห็นไม่สำเร็จ';

  @override
  String get failedToDeleteComment => 'ลบความคิดเห็นไม่สำเร็จ';

  @override
  String get retry => 'ลองใหม่';
}
