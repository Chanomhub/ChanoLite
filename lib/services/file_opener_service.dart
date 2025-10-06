import 'package:open_file/open_file.dart';

class FileOpenerService {
  static Future<void> openFile(String filePath) async {
    final result = await OpenFile.open(filePath);

    // You can check the result for different outcomes
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
