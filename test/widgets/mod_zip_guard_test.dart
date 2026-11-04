import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  // Mirrors _extractZip's guard: entries must stay inside the game root.
  bool isSafe(String gameRoot, String entryName) {
    final normalized =
        p.normalize(p.join(gameRoot, entryName.replaceAll('\\', '/')));
    return normalized == gameRoot || p.isWithin(gameRoot, normalized);
  }

  test('normal entries stay inside the game root', () {
    expect(isSafe('/games/noko', 'js/plugins.js'), isTrue);
    expect(isSafe('/games/noko', 'img/characters/hero.png'), isTrue);
    expect(isSafe('/games/noko', 'data/Actors.json'), isTrue);
  });

  test('traversal and absolute entries are rejected', () {
    expect(isSafe('/games/noko', '../evil.txt'), isFalse);
    expect(isSafe('/games/noko', 'a/../../evil.txt'), isFalse);
    expect(isSafe('/games/noko', '/etc/passwd'), isFalse);
    expect(isSafe('/games/noko', '..'), isFalse);
  });

  test('a hostile archive throws before writing outside the game dir', () async {
    final tmp = Directory.systemTemp.createTempSync('chanolite_zip_test');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final gameDir = Directory('${tmp.path}/game')
      ..createSync(recursive: true);
    final outside = File('${tmp.path}/pwned.txt');

    final archive = Archive()
      ..addFile(ArchiveFile('../pwned.txt', 5, 'hax!'.codeUnits));
    final zipPath = '${tmp.path}/mod.zip';
    File(zipPath).writeAsBytesSync(ZipEncoder().encode(archive)!);

    // Same walk as ModListSheet._extractZip.
    final decoded = ZipDecoder().decodeBytes(File(zipPath).readAsBytesSync());
    expect(
      () => decoded.where((e) => e.isFile).forEach((entry) {
        final normalized =
            p.normalize(p.join(gameDir.path, entry.name.replaceAll('\\', '/')));
        if (normalized != gameDir.path &&
            !p.isWithin(gameDir.path, normalized)) {
          throw StateError('Blocked unsafe path in mod archive: ${entry.name}');
        }
        File(normalized).writeAsBytesSync(entry.content as List<int>);
      }),
      throwsA(isA<StateError>()),
    );
    expect(outside.existsSync(), isFalse);
  });
}
