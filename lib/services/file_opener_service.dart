import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class FileOpenerService {
  static Future<OpenResult> openFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      // Check public Downloads folder as fallback
      final fileName = filePath.split(Platform.pathSeparator).last;
      final publicDownloadPath = '/storage/emulated/0/Download/$fileName';
      if (await File(publicDownloadPath).exists()) {
        filePath = publicDownloadPath;
      }
    }

    if (filePath.toLowerCase().endsWith('.apk')) {
      final status = await Permission.requestInstallPackages.request();
      if (status.isGranted) {
        final result = await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
        return result;
      } else {
        openAppSettings();
        return OpenResult(type: ResultType.permissionDenied, message: 'Install permission denied');
      }
    } else {
      return await OpenFilex.open(filePath);
    }
  }
}