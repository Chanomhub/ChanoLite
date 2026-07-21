import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/models/download_task.dart';
import 'package:chanolite/services/native_extractor_service.dart';

/// Helper manager for game library file resolution and extraction tasks
class LibraryManager {
  /// Resolves the actual file or directory path for a game,
  /// cleaning up duplicate copy counter names like "(1)" if necessary.
  static Future<String?> resolveGamePath({
    required String filePath,
    required String? fileName,
  }) async {
    var file = File(filePath);
    if (await file.exists()) {
      return file.path;
    }

    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      return null;
    }

    // Try clean filename without copy counters like (1), (2)
    final cleanFileName = fileName?.replaceAll(RegExp(r'\s\(\d+\)'), '') ?? '';
    final cleanFile = File('${parentDir.path}/$cleanFileName');

    if (cleanFileName.isNotEmpty && await cleanFile.exists()) {
      return cleanFile.path;
    }

    // Check if an extracted directory already exists
    final baseName = cleanFileName.isEmpty
        ? (fileName ?? '').replaceAll(RegExp(r'\s\(\d+\)'), '')
        : cleanFileName;
    final cleanDirName = baseName
        .replaceAll('.zip', '')
        .replaceAll('.7z', '')
        .replaceAll('.rar', '');
    final potentialDir = Directory('${parentDir.path}/$cleanDirName');

    if (cleanDirName.isNotEmpty && await potentialDir.exists()) {
      return potentialDir.path;
    }

    return null;
  }

  /// Extracts game archive if needed, reporting progress via [onProgress] callback.
  /// Returns the target extracted directory path on success, or null on failure.
  static Future<String?> extractGameArchive({
    required String filePath,
    required String? fileName,
    required void Function(int progress, String currentFile) onProgress,
  }) async {
    final file = File(filePath);
    final isZip = filePath.toLowerCase().endsWith('.zip');
    final is7z = filePath.toLowerCase().endsWith('.7z');
    final isRar = filePath.toLowerCase().endsWith('.rar');
    final isArchive = isZip || is7z || isRar;

    if (!isArchive) {
      return filePath;
    }

    final cleanName = fileName
        ?.replaceAll('.zip', '')
        .replaceAll('.7z', '')
        .replaceAll('.rar', '') ?? 'extracted_game';

    final parentDir = file.parent.path;
    final targetPath = '$parentDir/$cleanName';
    final potentialDir = Directory(targetPath);

    if (await potentialDir.exists()) {
      return potentialDir.path;
    }

    final success = await NativeExtractorService.extractArchive(
      filePath,
      targetPath,
      onProgress: onProgress,
    );

    if (success) {
      return targetPath;
    }
    return null;
  }

  /// Scans the directory recursively to find the folder containing index.html for RPG Maker HTML5 games.
  static Future<String?> findRpgMakerIndexHtml(String gameDir) async {
    final dir = Directory(gameDir);
    if (!await dir.exists()) return null;

    final List<FileSystemEntity> entities = await dir.list(recursive: true).toList();
    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('index.html')) {
        return entity.parent.path;
      }
    }
    return null;
  }
}
