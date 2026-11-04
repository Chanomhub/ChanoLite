import 'dart:io';

import 'package:chanolite/services/game_tools_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveNekoTarget — mirrors net.kernys.rgss v2.01 parseGameInfo', () {
    test('MV layout (package.json + www/index.html) → MVGameActivity', () {
      final t = GameToolsService.resolveNekoTarget(
        hasPackageJson: true,
        hasWwwIndexHtml: true,
        hasGameIni: false,
        hasGameExe: false,
      );
      expect(t.action, 'net.kernys.rgss.RUN_GAME_MV');
      expect(t.componentName, 'net.kernys.rgss.MVGameActivity');
      expect(t.isOpenApp, isFalse);
    });

    test('Legacy RGSS layout (Game.ini + Game.exe) → SDLActivity', () {
      final t = GameToolsService.resolveNekoTarget(
        hasPackageJson: false,
        hasWwwIndexHtml: false,
        hasGameIni: true,
        hasGameExe: true,
      );
      expect(t.action, 'net.kernys.rgss.RUN_GAME');
      expect(t.componentName, 'net.kernys.rgss.SDLActivity');
    });

    test('Unknown layout falls back to opening the app', () {
      final t = GameToolsService.resolveNekoTarget(
        hasPackageJson: false,
        hasWwwIndexHtml: true,
        hasGameIni: false,
        hasGameExe: false,
      );
      expect(t.isOpenApp, isTrue);
    });

    test('package.json without www/index.html is not MV (real MV games '
        'always ship both)', () {
      final t = GameToolsService.resolveNekoTarget(
        hasPackageJson: true,
        hasWwwIndexHtml: false,
        hasGameIni: false,
        hasGameExe: false,
      );
      expect(t.isOpenApp, isTrue);
    });

    test('resolves against a real directory layout', () {
      final tmp = Directory.systemTemp.createTempSync('neko_target');
      addTearDown(() => tmp.deleteSync(recursive: true));
      Directory('${tmp.path}/www').createSync();
      File('${tmp.path}/package.json').writeAsStringSync('{"name":"x"}');
      File('${tmp.path}/www/index.html').writeAsStringSync('<html></html>');

      final t = GameToolsService.resolveNekoTarget(
        hasPackageJson: File('${tmp.path}/package.json').existsSync(),
        hasWwwIndexHtml: File('${tmp.path}/www/index.html').existsSync(),
        hasGameIni: File('${tmp.path}/Game.ini').existsSync(),
        hasGameExe: File('${tmp.path}/Game.exe').existsSync(),
      );
      expect(t.componentName, 'net.kernys.rgss.MVGameActivity');
    });
  });
}
