import 'dart:io';
import 'package:chanolite/managers/library_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LibraryManager Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('library_manager_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('resolveGamePath returns direct file path if file exists', () async {
      final file = File('${tempDir.path}/game.zip');
      await file.writeAsString('dummy content');

      final result = await LibraryManager.resolveGamePath(
        filePath: file.path,
        fileName: 'game.zip',
      );

      expect(result, file.path);
    });

    test('resolveGamePath cleans up duplicate filename counter like (1)', () async {
      // Original file doesn't exist, but cleaned file does
      final cleanFile = File('${tempDir.path}/game.zip');
      await cleanFile.writeAsString('dummy content');

      final result = await LibraryManager.resolveGamePath(
        filePath: '${tempDir.path}/game (1).zip',
        fileName: 'game (1).zip',
      );

      expect(result, cleanFile.path);
    });

    test('resolveGamePath finds existing extracted directory', () async {
      final extractedDir = Directory('${tempDir.path}/MyGame');
      await extractedDir.create();

      final result = await LibraryManager.resolveGamePath(
        filePath: '${tempDir.path}/MyGame.zip',
        fileName: 'MyGame.zip',
      );

      expect(result, extractedDir.path);
    });

    test('findRpgMakerIndexHtml finds index.html in nested folder', () async {
      final gameDir = Directory('${tempDir.path}/rpg_game');
      final wwwDir = Directory('${gameDir.path}/www');
      await wwwDir.create(recursive: true);
      final indexHtml = File('${wwwDir.path}/index.html');
      await indexHtml.writeAsString('<html></html>');

      final result = await LibraryManager.findRpgMakerIndexHtml(gameDir.path);
      expect(result, wwwDir.path);
    });

    test('findRpgMakerIndexHtml returns null if no index.html exists', () async {
      final gameDir = Directory('${tempDir.path}/empty_game');
      await gameDir.create();

      final result = await LibraryManager.findRpgMakerIndexHtml(gameDir.path);
      expect(result, isNull);
    });
  });
}
