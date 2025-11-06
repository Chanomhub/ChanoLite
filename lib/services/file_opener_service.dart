import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class FileOpenerService {
  static Future<void> openFile(String filePath) async {
    if (filePath.toLowerCase().endsWith('.apk')) {
      final status = await Permission.requestInstallPackages.request();
      if (status.isGranted) {
        // Permission granted, proceed to open the APK
        final result = await OpenFile.open(filePath);
        _handleOpenResult(result, filePath);
      } else {
        // Permission denied, handle accordingly
        print('Permission to install packages denied.');
        // Optionally, open app settings to allow the user to grant permission manually
        openAppSettings();
      }
    } else {
      // Not an APK, open directly
      final result = await OpenFile.open(filePath);
      _handleOpenResult(result, filePath);
    }
  }

  static void _handleOpenResult(dynamic result, String filePath) {
    switch (result.type) {
      case ResultType.done:
        print('File opened successfully.');
        break;
      case ResultType.error:
        print('Error opening file: ${result.message}');
        break;
      case ResultType.fileNotFound:
        print('File not found at path: $filePath');
        break;
      case ResultType.noAppToOpen:
        print('No app found to open the file.');
        break;
      case ResultType.permissionDenied:
        print('Permission denied to open the file.');
        break;
    }
  }
}