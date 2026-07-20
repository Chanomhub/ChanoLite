import 'package:flutter/services.dart';

class NativeExtractorService {
  static const _channel = MethodChannel('com.chanomhub.chanolite/native_extractor');

  /// Extract an archive (.zip, .7z, .rar) natively on Android
  static Future<bool> extractArchive(
    String archivePath,
    String destPath, {
    void Function(int progress, String fileName)? onProgress,
  }) async {
    if (onProgress != null) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onProgress') {
          final args = call.arguments as Map?;
          final progress = args?['progress'] as int? ?? 0;
          final fileName = args?['fileName'] as String? ?? '';
          onProgress(progress, fileName);
        }
      });
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>('extractArchive', {
        'archivePath': archivePath,
        'destPath': destPath,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      print('NativeExtractorService: Error extracting archive: ${e.message}');
      return false;
    } catch (e) {
      print('NativeExtractorService: General error extracting archive: $e');
      return false;
    } finally {
      if (onProgress != null) {
        _channel.setMethodCallHandler(null);
      }
    }
  }
}
