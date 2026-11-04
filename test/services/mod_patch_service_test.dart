import 'dart:convert';
import 'dart:io';

import 'package:chanolite/models/mod_model.dart';
import 'package:chanolite/services/mod_patch_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Copies a directory tree recursively (tests run from the package root).
void copyTree(Directory src, Directory dst) {
  for (final entity in src.listSync(recursive: true)) {
    final rel = entity.path.substring(src.path.length);
    final target = '${dst.path}$rel';
    if (entity is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (entity is File) {
      File(target).parent.createSync(recursive: true);
      entity.copySync(target);
    }
  }
}

void main() {
  group('parsePath', () {
    test('splits dot and bracket segments', () {
      expect(
        ModPatchService.parsePath('events[15].pages[0].list[2].parameters[0]'),
        ['events', 15, 'pages', 0, 'list', 2, 'parameters', 0],
      );
      expect(ModPatchService.parsePath('[10].name'), [10, 'name']);
    });
  });

  group('setPathValue', () {
    test('sets when source matches, refuses otherwise', () {
      final root = <String, dynamic>{
        'events': <dynamic>[
          null,
          <String, dynamic>{'name': 'EV001'},
        ],
      };
      expect(
        ModPatchService.setPathValue(root, ['events', 1, 'name'], 'ใหม่', 'EV001'),
        isTrue,
      );
      expect(root['events'][1]['name'], 'ใหม่');
      // Shifted data: expected source no longer there.
      expect(
        ModPatchService.setPathValue(root, ['events', 1, 'name'], 'อื่น', 'EV002'),
        isFalse,
      );
    });

    test('out-of-range index is a no-op', () {
      expect(ModPatchService.setPathValue(['a'], [5], 'x', 'a'), isFalse);
    });
  });

  group('applyDictionaryWalk', () {
    test('replaces plain values but skips blacklisted keys', () {
      final node = <String, dynamic>{
        'characterName': 'Actor1',
        'note': 'Actor1',
        'profile': <String, dynamic>{'text': 'Actor1'},
      };
      final count =
          ModPatchService.applyDictionaryWalk(node, {'Actor1': 'นักแสดง'});
      // note + profile.text only; characterName is an asset name.
      expect(count, 2);
      expect(node['characterName'], 'Actor1');
      expect(node['note'], 'นักแสดง');
      expect(node['profile']['text'], 'นักแสดง');
    });

    test('translates RPG Maker event command parameters', () {
      // Real MV/MZ shape: commands are siblings inside an event's list.
      final listNode = <dynamic>[
        <String, dynamic>{
          'code': 102,
          'parameters': <dynamic>[
            ['はい', 'いいえ'],
          ],
        },
        <String, dynamic>{
          'code': 101,
          'parameters': <dynamic>['Actor1', 0, 0, 0, '王様'],
        },
        <String, dynamic>{
          'code': 401,
          'parameters': <dynamic>['こんにちは'],
        },
      ];
      final count = ModPatchService.applyDictionaryWalk(listNode, {
        'こんにちは': 'สวัสดี',
        'はい': 'ใช่',
        'いいえ': 'ไม่ใช่',
        '王様': 'กษัตริย์',
      });
      expect(listNode[0]['parameters'][0][0], 'ใช่');
      expect(listNode[1]['parameters'][4], 'กษัตริย์');
      expect(listNode[2]['parameters'][0], 'สวัสดี');
      expect(count, 4);
    });
  });

  group('real Noko patch E2E', () {
    late Directory tmp;

    setUp(() {
      // Not Directory.systemTemp: it can be aggressively pruned mid-test.
      tmp = Directory('${Directory.current.path}/.test_tmp/${DateTime.now().microsecondsSinceEpoch}')
        ..createSync(recursive: true);
      copyTree(Directory('test/fixtures/noko_game'), tmp);
    });

    tearDown(() {
      tmp.parent.deleteSync(recursive: true);
    });

    test('applies the real patch then rolls it back', () async {
      final gameDir = tmp.path;
      final result = ModPatchService.applyPatchSync(
        gameDir: gameDir,
        patchPath: 'test/fixtures/noko_real.patch.json.gz',
        modId: 6,
      );

      expect(result.filesModified, greaterThan(0));
      expect(result.totalPatchedEntries, greaterThan(1000));
      // Thai text actually landed in the patched data (real pair from the
      // patch's first entry: Armors.json [100].description).
      final armors =
          json.decode(File('$gameDir/data/Armors.json').readAsStringSync());
      expect(
        json.encode(armors).contains('เครื่องประดับที่เพิ่มความแม่นยำ'),
        isTrue,
      );

      // Backup + manifest exist.
      final backupsDir = Directory('$gameDir/.chanolite/backups');
      expect(backupsDir.existsSync(), isTrue);
      final manifest =
          File('${backupsDir.listSync().first.path}/backup-manifest.json');
      expect(manifest.existsSync(), isTrue);

      // installed_mods round trip + rollback restores the original bytes.
      final originalArmors =
          File('test/fixtures/noko_game/data/Armors.json').readAsBytesSync();
      final record = InstalledModRecord(
        id: 6,
        name: 'RPGM Translation (Thai)',
        version: '1.0',
        installedAt: DateTime.now().toIso8601String(),
        filename: 'chanomhub_patch.patch.json.gz',
        backupId: result.backupId,
      );
      ModPatchService.saveInstalledMods(gameDir, [record]);
      expect(await ModPatchService.loadInstalledMods(gameDir), hasLength(1));

      ModPatchService.rollback(gameDir, record);
      expect(
        File('$gameDir/data/Armors.json').readAsBytesSync(),
        originalArmors,
      );
    });
  });
}
