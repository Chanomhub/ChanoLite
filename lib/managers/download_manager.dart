
import 'dart:io';

import 'package:chanolite/models/download_task.dart';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';

import 'package:path/path.dart' as path;

import 'package:path_provider/path_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';



class DownloadManager extends ChangeNotifier {

  final Dio _dio = Dio();

  final List<DownloadTask> _tasks = [];

  static const String downloadPathKey = 'download_path';



  List<DownloadTask> get tasks => _tasks;



  // List of common archive file extensions

  static const List<String> _archiveExtensions = [

    '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'

  ];



  Future<void> startDownload(String url, {String? suggestedFilename}) async {

    // Prevent duplicate downloads

    if (_tasks.any((task) => task.url == url && (task.status == DownloadTaskStatus.running || task.status == DownloadTaskStatus.enqueued))) {

      return;

    }



    final prefs = await SharedPreferences.getInstance();

    String? savePath = prefs.getString(downloadPathKey);



    if (savePath == null) {

      final directory = await getApplicationDocumentsDirectory();

      savePath = directory.path;

    }



    // Create a new task

    final task = DownloadTask(url: url, status: DownloadTaskStatus.enqueued);

    _tasks.add(task);

    notifyListeners();



    // Get the file name from the URL or the suggested filename

    final fileName = suggestedFilename ?? path.basename(url.split('?').first);

    final filePath = path.join(savePath, fileName);



    // Determine the file type

    final type = _archiveExtensions.any((ext) => fileName.toLowerCase().endsWith(ext))

        ? DownloadType.archive

        : DownloadType.file;



    try {

      _updateTask(url, status: DownloadTaskStatus.running, fileName: fileName, filePath: filePath, type: type);



      await _dio.download(

        url,

        filePath,

        onReceiveProgress: (received, total) {

          if (total != -1) {

            final progress = received / total;

            _updateTask(url, progress: progress);

          }

        },

      );



      _updateTask(url, status: DownloadTaskStatus.complete, progress: 1.0);

    } catch (e) {

      _updateTask(url, status: DownloadTaskStatus.failed);

    }

  }



  void _updateTask(String url, {DownloadTaskStatus? status, double? progress, String? filePath, String? fileName, DownloadType? type}) {

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

    }

  }



  Future<void> deleteTask(DownloadTask task) async {

    if (task.filePath == null) {

      // If there's no file path, just remove it from the list

      _tasks.removeWhere((t) => t.url == task.url);

      notifyListeners();

      return;

    }



    try {

      final file = File(task.filePath!);

      if (await file.exists()) {

        await file.delete();

      }

      // Remove the task from the list regardless of whether the file existed

      _tasks.removeWhere((t) => t.url == task.url);

      notifyListeners();

    } catch (e) {

      // Handle or log the error

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



      // Update the task in the list

      _updateTask(task.url, fileName: newFile.path.split('/').last, filePath: newFile.path);

    } catch (e) {

      print('Error renaming file: $e');

    }

  }





}



