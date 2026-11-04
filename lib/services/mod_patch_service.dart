import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:chanolite/models/mod_model.dart';
import 'package:crypto/crypto.dart';

/// Result of applying a patch.
class PatchResult {
  final String backupId;
  final int totalPatchedEntries;
  final int totalUnappliedEntries;
  final int filesModified;
  final bool fontInjected;

  PatchResult({
    required this.backupId,
    required this.totalPatchedEntries,
    required this.totalUnappliedEntries,
    required this.filesModified,
    required this.fontInjected,
  });
}

/// Installs Chanomhub translation patches (.patch.json / .patch.json.gz)
/// into an extracted RPG Maker game directory.
///
/// Port of ChanoX2's PatcherService: exact key-path pass first, then a
/// dictionary fallback walk for shifted lines, with per-file backups so
/// [rollback] restores the originals.
class ModPatchService {
  ModPatchService._();

  /// RPG Maker keys that hold asset filenames — translating them breaks the game.
  static const Set<String> _blacklistedKeys = {
    'se', 'bgm', 'bgs', 'me',
    'animation1Name', 'animation2Name', 'battlerName',
    'characterName', 'faceName', 'motion',
    'overlay1Name', 'overlay2Name', 'tileset',
    'parallaxName', 'battleback1Name', 'battleback2Name',
    'script', 'url',
  };

  /// Parses "events[15].pages[0].list[2].parameters[0]" into tokens.
  static List<dynamic> parsePath(String pathStr) {
    final tokens = <dynamic>[];
    final re = RegExp(r'([^\.\[\]]+)|\[(\d+)\]');
    for (final match in re.allMatches(pathStr)) {
      final index = match.group(2);
      if (index != null) {
        tokens.add(int.parse(index));
      } else if (match.group(1) != null) {
        tokens.add(match.group(1)!);
      }
    }
    return tokens;
  }

  /// Sets [value] at [tokens] when the current value equals [expectedSource];
  /// returns false when the path no longer matches (shifted data).
  static bool setPathValue(
    dynamic obj,
    List<dynamic> tokens,
    String value,
    String expectedSource,
  ) {
    dynamic curr = obj;
    for (var i = 0; i < tokens.length - 1; i++) {
      curr = _child(curr, tokens[i]);
      if (curr is! Map && curr is! List) return false;
    }
    final last = tokens.last;
    if (_child(curr, last) == expectedSource) {
      _setChild(curr, last, value);
      return true;
    }
    return false;
  }

  static dynamic _child(dynamic node, dynamic token) {
    if (node is Map) return node[token.toString()];
    if (node is List) {
      return token is int && token >= 0 && token < node.length
          ? node[token]
          : null;
    }
    return null;
  }

  static void _setChild(dynamic node, dynamic token, String value) {
    if (node is Map) {
      node[token.toString()] = value;
    } else if (node is List && token is int && token < node.length) {
      node[token] = value;
    }
  }

  /// Loads a patch package from disk, transparently gunzipping gzip magic.
  static Map<String, dynamic> loadPatch(String patchPath) {
    final bytes = File(patchPath).readAsBytesSync();
    var jsonStr = utf8.decode(bytes, allowMalformed: true);
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      jsonStr = utf8.decode(GZipDecoder().decodeBytes(bytes));
    }
    return json.decode(jsonStr) as Map<String, dynamic>;
  }

  /// Finds the game's data directory (RPG Maker MV/MZ: `data/` or `www/data/`,
  /// optionally one level deep), plus the fonts directory when present.
  static Map<String, String?> findGameDirs(String gameDir) {
    String? dataDir;
    String? fontsDir;
    for (final candidate in ['www/data', 'data']) {
      if (Directory('$gameDir/$candidate').existsSync()) {
        dataDir = '$gameDir/$candidate';
        break;
      }
    }
    if (dataDir == null) {
      for (final entity in Directory(gameDir).listSync()) {
        if (entity is! Directory) continue;
        for (final sub in ['www/data', 'data']) {
          final p = '${entity.path}/$sub';
          if (Directory(p).existsSync()) {
            dataDir = p;
            break;
          }
        }
        if (dataDir != null) break;
      }
    }
    for (final candidate in ['www/fonts', 'fonts']) {
      if (Directory('$gameDir/$candidate').existsSync()) {
        fontsDir = '$gameDir/$candidate';
        break;
      }
    }
    return {'dataDir': dataDir, 'fontsDir': fontsDir};
  }

  /// Walks a parsed JSON tree replacing any string matched by [dict],
  /// skipping RPG Maker asset-name keys and translating event commands.
  static int applyDictionaryWalk(dynamic node, Map<String, String> dict) {
    if (node is Map) {
      if (node['code'] != null && node['parameters'] is List) {
        final code = (node['code'] as num).toInt();
        final params = node['parameters'] as List;
        var count = 0;
        if (code == 401 || code == 105 || code == 405) {
          if (params.isNotEmpty && dict[params[0]] != null) {
            params[0] = dict[params[0]]!;
            count++;
          }
        } else if (code == 102 && params.isNotEmpty && params[0] is List) {
          final choices = params[0] as List;
          for (var i = 0; i < choices.length; i++) {
            if (dict[choices[i]] != null) {
              choices[i] = dict[choices[i]]!;
              count++;
            }
          }
        } else if (code == 101 &&
            params.length > 4 &&
            dict[params[4]] != null) {
          params[4] = dict[params[4]]!;
          count++;
        } else if ((code == 320 || code == 324) &&
            params.length > 1 &&
            dict[params[1]] != null) {
          params[1] = dict[params[1]]!;
          count++;
        }
        return count;
      }
      var count = 0;
      for (final key in node.keys.toList()) {
        if (_blacklistedKeys.contains(key)) continue;
        final val = node[key];
        if (val is String) {
          if (dict[val] != null) {
            node[key] = dict[val]!;
            count++;
          }
        } else if (val is Map || val is List) {
          count += applyDictionaryWalk(val, dict);
        }
      }
      return count;
    }
    if (node is List) {
      var count = 0;
      for (var i = 0; i < node.length; i++) {
        final val = node[i];
        if (val is String) {
          if (dict[val] != null) {
            node[i] = dict[val]!;
            count++;
          }
        } else if (val is Map || val is List) {
          count += applyDictionaryWalk(val, dict);
        }
      }
      return count;
    }
    return 0;
  }

  /// Applies the patch at [patchPath] into the game at [gameDir].
  ///
  /// Backs up every touched file (plus gamefont.css when [thaiFontBytes] is
  /// injected) under `<gameDir>/.chanolite/backups/<backupId>/` and writes a
  /// `backup-manifest.json` so [rollback] can restore them.
  static PatchResult applyPatchSync({
    required String gameDir,
    required String patchPath,
    required int modId,
    List<int>? thaiFontBytes,
  }) {
    final pkg = loadPatch(patchPath);
    final rawEntries = pkg['entries'];
    if (rawEntries is! List) {
      throw const FormatException('Invalid patch package: missing entries');
    }

    final dirs = findGameDirs(gameDir);
    final dataDir = dirs['dataDir'];
    if (dataDir == null) {
      throw FileSystemException(
          'Could not locate game data directory', gameDir);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupId = 'mod_${modId}_$timestamp';
    final backupDir = '$gameDir/.chanolite/backups/$backupId';
    Directory(backupDir).createSync(recursive: true);

    // Group entries per data file; dictionaries drive the fallback pass.
    final entriesByFile = <String, List<Map<String, dynamic>>>{};
    for (final raw in rawEntries) {
      if (raw is! Map<String, dynamic>) continue;
      final tgt = raw['tgt'];
      if (tgt is! String || tgt.isEmpty || tgt == raw['src']) continue;
      final file = raw['file']?.toString() ?? '';
      final fileName = file.split('/').last.split('\\').last;
      if (fileName.isEmpty) continue;
      entriesByFile.putIfAbsent(fileName, () => []).add(raw);
    }

    final backedUpFiles = <Map<String, String>>[];
    final patchedFiles = <String>[];
    var totalPatchedEntries = 0;
    var totalUnapplied = 0;

    for (final entry in entriesByFile.entries) {
      final targetFilePath = '$dataDir/${entry.key}';
      final targetFile = File(targetFilePath);
      if (!targetFile.existsSync()) continue;

      final backupFilePath = '$backupDir/${entry.key}';
      targetFile.copySync(backupFilePath);
      backedUpFiles.add({
        'originalPath': targetFilePath,
        'backupPath': backupFilePath,
        'fileName': entry.key,
      });

      dynamic jsonRoot;
      try {
        jsonRoot = json.decode(targetFile.readAsStringSync());
      } catch (_) {
        continue;
      }

      var filePatchedCount = 0;
      final unapplied = <Map<String, dynamic>>[];

      // Pass 1: exact key-path match with source verification.
      for (final e in entry.value) {
        final tokens = parsePath(e['key'].toString());
        if (setPathValue(
            jsonRoot, tokens, e['tgt'] as String, e['src'].toString())) {
          filePatchedCount++;
        } else {
          unapplied.add(e);
        }
      }

      // Pass 2: dictionary fallback for shifted lines/events.
      if (unapplied.isNotEmpty) {
        final fallbackDict = <String, String>{
          for (final e in unapplied) e['src'].toString(): e['tgt'] as String,
        };
        filePatchedCount += applyDictionaryWalk(jsonRoot, fallbackDict);
      }
      totalUnapplied += unapplied.length;

      targetFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(jsonRoot),
      );
      patchedFiles.add(entry.key);
      totalPatchedEntries += filePatchedCount;
    }

    var fontInjected = false;
    final fontsDir = dirs['fontsDir'];
    if (fontsDir != null && thaiFontBytes != null && thaiFontBytes.isNotEmpty) {
      try {
        final targetFontPath = '$fontsDir/NotoSansThai-Regular.ttf';
        File(targetFontPath).writeAsBytesSync(thaiFontBytes);
        final cssFile = File('$fontsDir/gamefont.css');
        if (cssFile.existsSync()) {
          cssFile.copySync('$backupDir/gamefont.css');
          backedUpFiles.add({
            'originalPath': cssFile.path,
            'backupPath': '$backupDir/gamefont.css',
            'fileName': 'gamefont.css',
          });
          var cssContent = cssFile.readAsStringSync();
          if (!cssContent.contains('NotoSansThai-Regular.ttf')) {
            cssContent = cssContent.replaceFirstMapped(
              RegExp(
                  r'''src:\s*url\(["']?([^"')]+)["']?\);?''',
                  caseSensitive: false),
              (m) =>
                  'src: url("NotoSansThai-Regular.ttf"), url("${m.group(1)}");',
            );
            cssFile.writeAsStringSync(cssContent);
          }
        }
        fontInjected = true;
      } catch (_) {
        // Font injection is best-effort; the patch itself already succeeded.
      }
    }

    final manifest = {
      'modId': modId,
      'backupId': backupId,
      'timestamp': timestamp,
      'gamePath': gameDir,
      'patchPath': patchPath,
      'backedUpFiles': backedUpFiles,
      'patchedFiles': patchedFiles,
      'totalPatchedEntries': totalPatchedEntries,
      'totalUnappliedEntries': totalUnapplied,
      'fontInjected': fontInjected,
    };
    File('$backupDir/backup-manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    return PatchResult(
      backupId: backupId,
      totalPatchedEntries: totalPatchedEntries,
      totalUnappliedEntries: totalUnapplied,
      filesModified: patchedFiles.length,
      fontInjected: fontInjected,
    );
  }

  /// Restores every file recorded in the manifest for [record].
  static void rollback(String gameDir, InstalledModRecord record) {
    final manifestPath =
        '$gameDir/.chanolite/backups/${record.backupId}/backup-manifest.json';
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) return;
    final manifest =
        json.decode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    for (final item in (manifest['backedUpFiles'] as List? ?? [])) {
      final backupPath = item['backupPath'] as String?;
      final originalPath = item['originalPath'] as String?;
      if (backupPath != null &&
          originalPath != null &&
          File(backupPath).existsSync()) {
        File(backupPath).copySync(originalPath);
      }
    }
    if (manifest['fontInjected'] == true) {
      final fontsDir = findGameDirs(gameDir)['fontsDir'];
      if (fontsDir != null) {
        final injected = File('$fontsDir/NotoSansThai-Regular.ttf');
        if (injected.existsSync()) injected.deleteSync();
      }
    }
    manifestFile.renameSync('$manifestPath.rolledback');
  }

  /// Reads installed_mods.json for a game directory.
  static Future<List<InstalledModRecord>> loadInstalledMods(
      String gameDir) async {
    final file = File('$gameDir/installed_mods.json');
    if (!file.existsSync()) return [];
    try {
      final list = json.decode(file.readAsStringSync()) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(InstalledModRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists installed_mods.json for a game directory.
  static Future<void> saveInstalledMods(
    String gameDir,
    List<InstalledModRecord> mods,
  ) async {
    final encoder = const JsonEncoder.withIndent('  ');
    File('$gameDir/installed_mods.json').writeAsStringSync(
      encoder.convert(mods.map((m) => m.toJson()).toList()),
    );
  }

  /// SHA-256 of a downloaded file, for verifying a mod's published checksum.
  static Future<String> sha256OfFile(String filePath) async {
    final digest = await sha256.bind(File(filePath).openRead()).first;
    return digest.toString();
  }
}
