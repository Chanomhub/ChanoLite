import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chanolite/models/download_task.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class DownloadManager extends ChangeNotifier {
  final Dio _dio = Dio();
  final List<DownloadTask> _tasks = [];
  static const MethodChannel _platformChannel = MethodChannel(
    'com.chanomhub.chanolite/download_notifications',
  );

  static const String downloadPathKey = 'download_path';
  static const String downloadTasksKey = 'download_tasks';

  List<DownloadTask> get tasks => _tasks;

  static const List<String> _archiveExtensions = [
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.gz',
    '.bz2',
  ];

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(downloadTasksKey);
    if (stored == null) {
      return;
    }

    final List<DownloadTask> restored = [];
    for (final entry in stored) {
      try {
        final Map<String, dynamic> jsonMap =
            json.decode(entry) as Map<String, dynamic>;
        var task = DownloadTask.fromJson(jsonMap);
        if (task.filePath != null) {
          final file = File(task.filePath!);
          final exists = await file.exists();
          if (!exists && task.status == DownloadTaskStatus.complete) {
            continue;
          }
        }
        if (task.status == DownloadTaskStatus.running ||
            task.status == DownloadTaskStatus.enqueued) {
          task = task.copyWith(
            status: DownloadTaskStatus.failed,
            progress: 0.0,
          );
        }
        restored.add(task);
      } catch (_) {
        continue;
      }
    }

    _tasks
      ..clear()
      ..addAll(restored);
    notifyListeners();
    await _persistTasks();
  }

  Future<void> startDownload(
    String url, {
    String? suggestedFilename,
    String? authToken,
  }) async {
    if (_tasks.any((task) =>
        task.url == url &&
        (task.status == DownloadTaskStatus.running ||
            task.status == DownloadTaskStatus.enqueued))) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? savePath = prefs.getString(downloadPathKey);

    if (savePath == null) {
      final directory = await getApplicationDocumentsDirectory();
      savePath = directory.path;
    }

    final task = DownloadTask(
      url: url,
      status: DownloadTaskStatus.enqueued,
    );
    _tasks.add(task);
    notifyListeners();
    _schedulePersist();

    final fileName =
        suggestedFilename ?? path.basename(url.split('?').first);
    final filePath = path.join(savePath, fileName);

    final type = _archiveExtensions.any(
      (ext) => fileName.toLowerCase().endsWith(ext),
    )
        ? DownloadType.archive
        : DownloadType.file;

    unawaited(_notifyDownloadStarted(fileName));

    try {
      _updateTask(
        url,
        status: DownloadTaskStatus.running,
        fileName: fileName,
        filePath: filePath,
        type: type,
      );

      await _dio.download(
        url,
        filePath,
        options: Options(
          headers: authToken != null && authToken.isNotEmpty
              ? {'Cookie': 'token=$authToken'}
              : null,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _updateTask(
              url,
              progress: progress,
              persist: false,
            );
          }
        },
      );

      _updateTask(
        url,
        status: DownloadTaskStatus.complete,
        progress: 1.0,
      );
    } catch (e) {
      _updateTask(url, status: DownloadTaskStatus.failed);
    }
  }

  void _updateTask(
    String url, {
    DownloadTaskStatus? status,
    double? progress,
    String? filePath,
    String? fileName,
    DownloadType? type,
    bool persist = true,
  }) {
    final index = _tasks.indexWhere((task) => task.url == url);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: status,
        progress: progress,
        filePath: filePath,
        fileName: fileName,
        type: type,
      );
      notifyListeners();
      if (persist) {
        _schedulePersist();
      }
    }
  }

  Future<void> deleteTask(DownloadTask task) async {
    if (task.filePath == null) {
      _tasks.removeWhere((t) => t.url == task.url);
      notifyListeners();
      _schedulePersist();
      return;
    }

    try {
      final file = File(task.filePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _tasks.removeWhere((t) => t.url == task.url);
      notifyListeners();
      _schedulePersist();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  Future<void> renameTask(DownloadTask task, String newFileName) async {
    if (task.filePath == null) {
      print('Cannot rename task: filePath is null');
      return;
    }

    try {
      final oldFile = File(task.filePath!);
      final newFilePath = path.join(path.dirname(task.filePath!), newFileName);
      final newFile = await oldFile.rename(newFilePath);

      _updateTask(
        task.url,
        fileName: path.basename(newFile.path),
        filePath: newFile.path,
      );
    } catch (e) {
      print('Error renaming file: $e');
    }
  }

  void _schedulePersist() {
    unawaited(_persistTasks());
  }

  Future<void> _notifyDownloadStarted(String fileName) async {
    try {
      await _platformChannel.invokeMethod(
        'notifyDownloadStarted',
        <String, dynamic>{'fileName': fileName},
      );
    } catch (_) {
      // Ignore errors from the native notification layer.
    }
  }

  Future<void> _persistTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        _tasks.map((task) => json.encode(task.toJson())).toList();
    await prefs.setStringList(downloadTasksKey, encoded);
  }
}
