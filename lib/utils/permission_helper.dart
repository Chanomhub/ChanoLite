import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      print('Android SDK: $sdkInt');
      
      if (sdkInt >= 33) {
        // Android 13+: ไม่ต้องขอ permission สำหรับ Downloads folder
        // แต่ถ้าต้องการเข้าถึงไฟล์ media ให้ขอแบบนี้
        print('Android 13+: No storage permission needed for Downloads');
        return true;
      } else if (sdkInt >= 30) {
        // Android 11-12: ใช้ scoped storage, ไม่ต้องขอ MANAGE_EXTERNAL_STORAGE
        print('Android 11-12: Using scoped storage');
        return true;
      } else if (sdkInt >= 29) {
        // Android 10: ใช้ scoped storage
        print('Android 10: Using scoped storage');
        return true;
      } else {
        // Android 9 and below
        print('Requesting storage permission');
        var status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        return status.isGranted;
      }
    }
    return true;
  }
}
