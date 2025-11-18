import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:chanolite/models/download_task.dart';
import 'package:chanolite/utils/permission_helper.dart'; // Import the new permission helper
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart' as downloader;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
class DownloadManager extends ChangeNotifier {
  final List<DownloadTask> _tasks = [];
  static const MethodChannel _platformChannel = MethodChannel(
    'com.chanomhub.chanolite/download_notifications',
  );

  static const String downloadPathKey = 'download_path';
  static const String downloadTasksKey = 'download_tasks';

  List<DownloadTask> get tasks => _tasks;

  final ReceivePort _port = ReceivePort();

  static const List<String> _archiveExtensions = [
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.gz',
    '.bz2',
  ];

  DownloadManager() {
    _bindBackgroundIsolate();
    downloader.FlutterDownloader.registerCallback(downloadCallback);
  }

  void _bindBackgroundIsolate() {
    final isSuccess = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      final taskId = data[0] as String;
      final status = _intToStatus(data[1] as int);
      final progress = data[2] as int;

      _updateTaskByTaskId(
        taskId,
        status: status,
        progress: status == DownloadTaskStatus.complete ? 1.0 : progress / 100.0,
        persist: status == DownloadTaskStatus.complete ||
            status == DownloadTaskStatus.failed,
      );
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  DownloadTaskStatus _intToStatus(int statusValue) {
    switch (statusValue) {
      case 0:
        return DownloadTaskStatus.paused;
      case 1:
        return DownloadTaskStatus.enqueued;
      case 2:
        return DownloadTaskStatus.running;
      case 3:
        return DownloadTaskStatus.complete;
      case 4:
        return DownloadTaskStatus.failed;
      case 5:
        return DownloadTaskStatus.canceled;
      case 6:
        return DownloadTaskStatus.paused;
      default:
        return DownloadTaskStatus.failed;
    }
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  Future<void> loadTasks() async {
    final downloaderTasks = await downloader.FlutterDownloader.loadTasks();
    if (downloaderTasks == null) {
      return;
    }

    final List<DownloadTask> newTasks = [];
    for (final task in downloaderTasks) {
      final fileName = task.filename;
      if (fileName == null) continue;

      final type = _archiveExtensions.any(
            (ext) => fileName.toLowerCase().endsWith(ext),
      )
          ? DownloadType.archive
          : DownloadType.file;

      final localTask = DownloadTask(
        url: task.url,
        status: _intToStatus(task.status.index),
        progress: task.progress / 100.0,
        filePath: task.savedDir + Platform.pathSeparator + fileName,
        fileName: fileName,
        type: type,
        taskId: task.taskId,
      );
      newTasks.add(localTask);
    }

    _tasks
      ..clear()
      ..addAll(newTasks);
    notifyListeners();
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

    // Request storage permission
    final hasPermission = await PermissionHelper.requestStoragePermission();
    if (!hasPermission) {
      print('Storage permission not granted. Cannot start download.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? savePath = prefs.getString(downloadPathKey);

    if (savePath == null) {
      if (Platform.isAndroid) {
        final directory = await getDownloadsDirectory(); // Use getDownloadsDirectory for Android
        savePath = directory?.path;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        savePath = directory.path;
      }
    }

    if (savePath == null) {
      print('Could not determine a save path. Cannot start download.');
      return;
    }

    final fileName = suggestedFilename ?? path.basename(url.split('?').first);

    final type = _archiveExtensions.any(
          (ext) => fileName.toLowerCase().endsWith(ext),
    )
        ? DownloadType.archive
        : DownloadType.file;

    // unawaited(_notifyDownloadStarted(fileName));

    try {
      final taskId = await downloader.FlutterDownloader.enqueue(
        url: url,
        savedDir: savePath,
        fileName: fileName,
        headers: authToken != null && authToken.isNotEmpty
            ? {'Cookie': 'token=$authToken'}
            : {},
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true, // Important for public access on newer Android versions
      );

      if (taskId != null) {
        final filePath = path.join(savePath, fileName);
        final task = DownloadTask(
          url: url,
          status: DownloadTaskStatus.enqueued,
          fileName: fileName,
          filePath: filePath,
          type: type,
          taskId: taskId,
        );
        _tasks.add(task);
        notifyListeners();
      }
    } catch (e) {
      print('Error starting download: $e');
    }
  }

  void _updateTaskByTaskId(
      String taskId, {
        DownloadTaskStatus? status,
        double? progress,
        bool persist = true,
      }) {
    final index = _tasks.indexWhere((task) => task.taskId == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: status,
        progress: progress,
      );
      notifyListeners();
    }
  }

  void _updateTask(
      String url, {
        DownloadTaskStatus? status,
        double? progress,
        String? filePath,
        String? fileName,
        DownloadType? type,
        String? taskId,
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
        taskId: taskId,
      );
      notifyListeners();
    }
  }

  Future<void> deleteTask(DownloadTask task) async {
    // Cancel download if still running
    if (task.taskId != null &&
        (task.status == DownloadTaskStatus.running ||
            task.status == DownloadTaskStatus.enqueued)) {
      await downloader.FlutterDownloader.cancel(taskId: task.taskId!);
    }

    if (task.filePath == null) {
      _tasks.removeWhere((t) => t.url == task.url);
      notifyListeners();
      return;
    }

    try {
      final file = File(task.filePath!);
      if (await file.exists()) {
        await file.delete();
      }
      if (task.taskId != null) {
        await downloader.FlutterDownloader.remove(taskId: task.taskId!);
      }
      _tasks.removeWhere((t) => t.url == task.url);
      notifyListeners();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  Future<void> pauseTask(DownloadTask task) async {
    if (task.taskId != null && task.status == DownloadTaskStatus.running) {
      await downloader.FlutterDownloader.pause(taskId: task.taskId!);
    }
  }

  Future<void> resumeTask(DownloadTask task) async {
    if (task.taskId != null && task.status == DownloadTaskStatus.paused) {
      final newTaskId = await downloader.FlutterDownloader.resume(taskId: task.taskId!);
      if (newTaskId != null) {
        _updateTask(task.url, taskId: newTaskId);
      }
    }
  }

  Future<void> retryTask(DownloadTask task) async {
    if (task.status == DownloadTaskStatus.failed) {
      await deleteTask(task);
      await startDownload(task.url, suggestedFilename: task.fileName);
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

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }
}