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



  static const String downloadPathKey = 'download_path';
  static const String metadataKey = 'download_metadata';

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
    print('DownloadManager: Constructor called');
    _bindBackgroundIsolate();
    downloader.FlutterDownloader.registerCallback(downloadCallback);
    print('DownloadManager: Callback registered');
  }

  void _bindBackgroundIsolate() {
    print('DownloadManager: Binding background isolate...');
    final isSuccess = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );
    print('DownloadManager: Port registration success: $isSuccess');
    if (!isSuccess) {
      print('DownloadManager: Port already registered, rebinding...');
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      print('=== DownloadManager: RECEIVED MESSAGE FROM ISOLATE ===');
      print('Data: $data');
      final taskId = data[0] as String;
      final status = _intToStatus(data[1] as int);
      final progress = data[2] as int;
      print('TaskId: $taskId, Status: ${status.name}, Progress: $progress%');

      _updateTaskByTaskId(
        taskId,
        status: status,
        progress: status == DownloadTaskStatus.complete ? 1.0 : progress / 100.0,
      );
    });
    print('DownloadManager: Port listener attached');
  }

  void _unbindBackgroundIsolate() {
    print('DownloadManager: Unbinding background isolate');
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
    print('=== DownloadManager.downloadCallback CALLED (BACKGROUND ISOLATE) ===');
    print('TaskId: $id, Status: $status, Progress: $progress');
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    print('SendPort found: ${send != null}');
    if (send != null) {
      send.send([id, status, progress]);
      print('Message sent to main isolate');
    } else {
      print('ERROR: SendPort not found!');
    }
  }

  Future<void> loadTasks() async {
    final downloaderTasks = await downloader.FlutterDownloader.loadTasks();
    if (downloaderTasks == null) {
      return;
    }

    // Load metadata
    final prefs = await SharedPreferences.getInstance();
    final metadataString = prefs.getString(metadataKey);
    final Map<String, dynamic> metadataMap = metadataString != null
        ? json.decode(metadataString)
        : {};

    final List<DownloadTask> newTasks = [];
    final List<String> taskIdsToRemove = [];

    for (final task in downloaderTasks) {
      final fileName = task.filename;
      if (fileName == null) continue;

      final status = _intToStatus(task.status.index);

      // Skip enqueued tasks with 0 progress that are likely stale
      // (URL probably expired, never started)
      if (status == DownloadTaskStatus.enqueued && task.progress == 0) {
        print('DownloadManager: Removing stale enqueued task: ${task.url}');
        taskIdsToRemove.add(task.taskId);
        continue;
      }

      final type = _archiveExtensions.any(
            (ext) => fileName.toLowerCase().endsWith(ext),
      )
          ? DownloadType.archive
          : DownloadType.file;

      // Retrieve metadata using URL as key
      final metadata = metadataMap[task.url] as Map<String, dynamic>?;

      final localTask = DownloadTask(
        url: task.url,
        status: status,
        progress: task.progress / 100.0,
        filePath: task.savedDir + Platform.pathSeparator + fileName,
        fileName: fileName,
        type: type,
        taskId: task.taskId,
        imageUrl: metadata?['imageUrl'],
        version: metadata?['version'],
        engine: metadata?['engine'],
      );
      newTasks.add(localTask);
    }

    // Clean up stale tasks
    for (final taskId in taskIdsToRemove) {
      try {
        await downloader.FlutterDownloader.remove(taskId: taskId);
      } catch (e) {
        print('DownloadManager: Error removing stale task $taskId: $e');
      }
    }

    _tasks
      ..clear()
      ..addAll(newTasks);
    notifyListeners();
  }

  /// Clear all stuck/failed downloads
  Future<void> clearStuckDownloads() async {
    final tasksToRemove = _tasks.where((task) => 
      task.status == DownloadTaskStatus.enqueued ||
      task.status == DownloadTaskStatus.failed ||
      task.status == DownloadTaskStatus.canceled
    ).toList();

    for (final task in tasksToRemove) {
      await deleteTask(task);
    }
  }

  Future<void> startDownload(
      String url, {
        String? suggestedFilename,
        String? cookies,
        String? imageUrl,
        String? version,
        String? engine,
      }) async {
    print('=== DownloadManager.startDownload START ===');
    print('URL: $url');
    print('Filename: $suggestedFilename');
    print('Has cookies: ${cookies?.isNotEmpty ?? false}');
    
    if (_tasks.any((task) =>
    task.url == url &&
        (task.status == DownloadTaskStatus.running ||
            task.status == DownloadTaskStatus.enqueued))) {
      print('DownloadManager: Task already exists for this URL, skipping');
      return;
    }

    // Request storage permission
    print('DownloadManager: Requesting storage permission...');
    final hasPermission = await PermissionHelper.requestStoragePermission();
    print('DownloadManager: Permission granted: $hasPermission');
    if (!hasPermission) {
      print('Storage permission not granted. Cannot start download.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? savePath = prefs.getString(downloadPathKey);
    print('DownloadManager: Custom save path: $savePath');

    if (savePath == null) {
      if (Platform.isAndroid) {
        final directory = await getDownloadsDirectory();
        savePath = directory?.path;
        print('DownloadManager: Android downloads directory: $savePath');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        savePath = directory.path;
        print('DownloadManager: Documents directory: $savePath');
      }
    }

    if (savePath == null) {
      print('ERROR: Could not determine a save path. Cannot start download.');
      return;
    }

    final fileName = suggestedFilename ?? path.basename(url.split('?').first);
    print('DownloadManager: Final filename: $fileName');
    print('DownloadManager: Save path: $savePath');

    final type = _archiveExtensions.any(
          (ext) => fileName.toLowerCase().endsWith(ext),
    )
        ? DownloadType.archive
        : DownloadType.file;

    // Save metadata
    if (imageUrl != null || version != null || engine != null) {
      final metadataString = prefs.getString(metadataKey);
      final Map<String, dynamic> metadataMap = metadataString != null
          ? json.decode(metadataString)
          : {};
      
      metadataMap[url] = {
        'imageUrl': imageUrl,
        'version': version,
        'engine': engine,
      };
      
      await prefs.setString(metadataKey, json.encode(metadataMap));
      print('DownloadManager: Saved metadata');
    }

    try {
      // Build headers - use cookies from browser session if available
      final Map<String, String> headers = {};
      if (cookies != null && cookies.isNotEmpty) {
        headers['Cookie'] = cookies;
        print('DownloadManager: Using browser cookies: $cookies');
      }

      print('DownloadManager: Calling FlutterDownloader.enqueue...');
      print('  - url: $url');
      print('  - savedDir: $savePath');
      print('  - fileName: $fileName');
      print('  - headers: $headers');
      
      final taskId = await downloader.FlutterDownloader.enqueue(
        url: url,
        savedDir: savePath,
        fileName: fileName,
        headers: headers,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
      );

      print('DownloadManager: FlutterDownloader.enqueue returned taskId: $taskId');

      if (taskId != null) {
        final filePath = path.join(savePath, fileName);
        final task = DownloadTask(
          url: url,
          status: DownloadTaskStatus.enqueued,
          fileName: fileName,
          filePath: filePath,
          type: type,
          taskId: taskId,
          imageUrl: imageUrl,
          version: version,
          engine: engine,
        );
        _tasks.add(task);
        print('DownloadManager: Task added to list. Total tasks: ${_tasks.length}');
        notifyListeners();
        print('=== DownloadManager.startDownload SUCCESS ===');
      } else {
        print('ERROR: FlutterDownloader.enqueue returned null taskId!');
      }
    } catch (e, stackTrace) {
      print('ERROR starting download: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _updateTaskByTaskId(
      String taskId, {
        DownloadTaskStatus? status,
        double? progress,
      }) async {
    final index = _tasks.indexWhere((task) => task.taskId == taskId);
    if (index == -1) return;

    String? actualFilePath;
    String? actualFileName;

    // When download completes, find the actual saved file
    if (status == DownloadTaskStatus.complete) {
      try {
        final tasks = await downloader.FlutterDownloader.loadTasks();
        final downloaderTask = tasks?.firstWhere(
          (t) => t.taskId == taskId,
          orElse: () => throw Exception('Task not found'),
        );
        
        if (downloaderTask != null && downloaderTask.filename != null) {
          final baseFileName = downloaderTask.filename!;
          final baseName = path.basenameWithoutExtension(baseFileName);
          final extension = path.extension(baseFileName);
          
          // When saveInPublicStorage is true, file is saved to public Download folder
          const publicDownloadDir = '/storage/emulated/0/Download';
          
          final publicDir = Directory(publicDownloadDir);
          if (await publicDir.exists()) {
            DateTime? newestTime;
            
            // Find the newest file matching the pattern
            await for (final entity in publicDir.list()) {
              if (entity is File) {
                final fileName = path.basename(entity.path);
                // Match pattern: baseName.extension or baseName (N).extension
                if (fileName.startsWith(baseName) && fileName.endsWith(extension)) {
                  final fileStat = await entity.stat();
                  if (newestTime == null || fileStat.modified.isAfter(newestTime)) {
                    newestTime = fileStat.modified;
                    actualFilePath = entity.path;
                    actualFileName = fileName;
                  }
                }
              }
            }
          }
          
          print('DownloadManager: Actual saved file (newest): $actualFilePath');
        }
      } catch (e) {
        print('DownloadManager: Error getting actual file path: $e');
      }
    }

    _tasks[index] = _tasks[index].copyWith(
      status: status,
      progress: progress,
      filePath: actualFilePath,
      fileName: actualFileName,
    );
    notifyListeners();
  }

  void _updateTask(
      String url, {
        DownloadTaskStatus? status,
        double? progress,
        String? filePath,
        String? fileName,
        DownloadType? type,
        String? taskId,
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

    // Remove metadata
    final prefs = await SharedPreferences.getInstance();
    final metadataString = prefs.getString(metadataKey);
    if (metadataString != null) {
      final Map<String, dynamic> metadataMap = json.decode(metadataString);
      if (metadataMap.containsKey(task.url)) {
        metadataMap.remove(task.url);
        await prefs.setString(metadataKey, json.encode(metadataMap));
      }
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

  Future<void> cancelTask(DownloadTask task) async {
    if (task.taskId != null && 
        (task.status == DownloadTaskStatus.running || 
         task.status == DownloadTaskStatus.enqueued)) {
      await downloader.FlutterDownloader.cancel(taskId: task.taskId!);
      _updateTask(task.url, status: DownloadTaskStatus.canceled);
    }
  }

  Future<void> retryTask(DownloadTask task) async {
    if (task.status == DownloadTaskStatus.failed || 
        task.status == DownloadTaskStatus.canceled) {
      final fileName = task.fileName;
      final imageUrl = task.imageUrl;
      final version = task.version;
      final engine = task.engine;
      await deleteTask(task);
      await startDownload(
        task.url, 
        suggestedFilename: fileName,
        imageUrl: imageUrl,
        version: version,
        engine: engine,
      );
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


  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }
}