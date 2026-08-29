import 'package:chanolite/models/download.dart';
import 'package:chanolite/models/download_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Download & DownloadTask Model Tests', () {
    test('Download fromJson and toJson', () {
      final json = {
        'id': 'dl_123',
        'name': 'Game_v1.zip',
        'url': 'https://example.com/dl/Game_v1.zip',
        'isActive': true,
        'vipOnly': false,
      };

      final download = Download.fromJson(json);
      expect(download.id, 'dl_123');
      expect(download.name, 'Game_v1.zip');
      expect(download.url, 'https://example.com/dl/Game_v1.zip');
      expect(download.isActive, isTrue);
      expect(download.vipOnly, isFalse);

      final outJson = download.toJson();
      expect(outJson['id'], 'dl_123');
      expect(outJson['name'], 'Game_v1.zip');
      expect(outJson['url'], 'https://example.com/dl/Game_v1.zip');
    });

    test('Download fallback ID generation when id is null', () {
      final json = {
        'name': 'Game_v1.zip',
        'url': 'https://example.com/dl/Game_v1.zip',
      };
      final download = Download.fromJson(json);
      expect(download.id, isNotEmpty);
    });

    test('DownloadTask fromJson and toJson', () {
      final json = {
        'url': 'https://example.com/game.zip',
        'status': 'running',
        'progress': 0.65,
        'filePath': '/storage/emulated/0/Download/game.zip',
        'fileName': 'game.zip',
        'type': 'archive',
        'taskId': 'task_abc_123',
        'imageUrl': 'https://example.com/cover.png',
        'version': '1.0.2',
        'packageName': 'com.example.game',
        'engine': 'RPG Maker MV',
        'title': 'Test RPG',
      };

      final task = DownloadTask.fromJson(json);
      expect(task.url, 'https://example.com/game.zip');
      expect(task.status, DownloadTaskStatus.running);
      expect(task.progress, 0.65);
      expect(task.filePath, '/storage/emulated/0/Download/game.zip');
      expect(task.fileName, 'game.zip');
      expect(task.type, DownloadType.archive);
      expect(task.taskId, 'task_abc_123');
      expect(task.imageUrl, 'https://example.com/cover.png');
      expect(task.version, '1.0.2');
      expect(task.packageName, 'com.example.game');
      expect(task.engine, 'RPG Maker MV');
      expect(task.title, 'Test RPG');

      final outJson = task.toJson();
      expect(outJson['status'], 'running');
      expect(outJson['type'], 'archive');
      expect(outJson['taskId'], 'task_abc_123');
      expect(outJson['progress'], 0.65);
    });

    test('DownloadTask copyWith updates fields properly', () {
      final original = DownloadTask(
        url: 'https://example.com/test.apk',
        status: DownloadTaskStatus.enqueued,
        progress: 0.0,
        fileName: 'test.apk',
      );

      final updated = original.copyWith(
        status: DownloadTaskStatus.complete,
        progress: 1.0,
        filePath: '/downloads/test.apk',
      );

      expect(updated.url, original.url);
      expect(updated.status, DownloadTaskStatus.complete);
      expect(updated.progress, 1.0);
      expect(updated.filePath, '/downloads/test.apk');
      expect(updated.fileName, 'test.apk');
    });

    test('DownloadTask handles all DownloadTaskStatus values', () {
      for (final status in DownloadTaskStatus.values) {
        final task = DownloadTask.fromJson({
          'url': 'https://example.com/test',
          'status': status.name,
        });
        expect(task.status, status);
      }
    });

    test('DownloadTask handles all DownloadType values', () {
      for (final type in DownloadType.values) {
        final task = DownloadTask.fromJson({
          'url': 'https://example.com/test',
          'type': type.name,
        });
        expect(task.type, type);
      }
    });
  });
}
