import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class FileOpenerService {
  static Future<void> openFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      print('FileOpenerService: File does not exist at path (dart:io): $filePath');
      
      // List files in the directory to help debugging
      try {
        final parentDir = file.parent;
        if (await parentDir.exists()) {
          print('FileOpenerService: Listing files in ${parentDir.path}:');
          await for (final entity in parentDir.list()) {
            print(' - ${entity.path}');
          }
        } else {
          print('FileOpenerService: Parent directory does not exist: ${parentDir.path}');
        }
      } catch (e) {
        print('FileOpenerService: Error listing files: $e');
      }

      // Check public Downloads folder
      final fileName = filePath.split(Platform.pathSeparator).last;
      final publicDownloadPath = '/storage/emulated/0/Download/$fileName';
      print('FileOpenerService: Checking public download path: $publicDownloadPath');
      if (await File(publicDownloadPath).exists()) {
        print('FileOpenerService: Found file at public path: $publicDownloadPath');
        filePath = publicDownloadPath;
      } else {
        // List public downloads to see if it's there with a different name
        try {
          final publicDir = Directory('/storage/emulated/0/Download');
          if (await publicDir.exists()) {
             print('FileOpenerService: Listing public downloads:');
             await for (final entity in publicDir.list()) {
               if (entity.path.contains(fileName)) {
                 print(' - MATCH: ${entity.path}');
               }
             }
          }
        } catch (e) {
          print('FileOpenerService: Error listing public downloads: $e');
        }
      }
    } else {
      print('FileOpenerService: File exists at path: $filePath');
    }

    // Proceed to try opening the file anyway, as open_filex might handle it.
    if (filePath.toLowerCase().endsWith('.apk')) {
      final status = await Permission.requestInstallPackages.request();
      if (status.isGranted) {
        // Permission granted, proceed to open the APK with explicit MIME type
        final result = await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
        _handleOpenResult(result, filePath);
      } else {
        // Permission denied, handle accordingly
        print('Permission to install packages denied.');
        // Optionally, open app settings to allow the user to grant permission manually
        openAppSettings();
      }
    } else {
      // Not an APK, open directly
      final result = await OpenFilex.open(filePath);
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