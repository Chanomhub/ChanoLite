import 'dart:convert';
import 'dart:io';

class PatchResult {
  final bool success;
  final String? backupId;
  final int totalPatchedEntries;
  final int filesModified;
  final String? error;

  PatchResult({
    required this.success,
    this.backupId,
    this.totalPatchedEntries = 0,
    this.filesModified = 0,
    this.error,
  });
}

class PatcherService {
  static const Set<String> blacklistedKeys = {
    'se', 'bgm', 'bgs', 'me',
    'animation1Name', 'animation2Name', 'battlerName',
    'characterName', 'faceName', 'motion',
    'overlay1Name', 'overlay2Name', 'tileset',
    'parallaxName', 'battleback1Name', 'battleback2Name',
    'script', 'url'
  };

  /// Parses token path like "events[15].pages[0].list[2].parameters[0]" or "[10].name"
  static List<dynamic> parsePath(String pathStr) {
    final tokens = <dynamic>[];
    final regExp = RegExp(r'([^.\[\]]+)|\[(\d+)\]');
    final matches = regExp.allMatches(pathStr);

    for (final m in matches) {
      if (m.group(2) != null) {
        tokens.add(int.parse(m.group(2)!));
      } else if (m.group(1) != null) {
        tokens.add(m.group(1)!);
      }
    }
    return tokens;
  }

  /// Mutates node at tokens path safely
  static bool setPathValue(dynamic obj, List<dynamic> tokens, dynamic value, {dynamic expectedSource}) {
    if (obj == null || tokens.isEmpty) return false;
    dynamic curr = obj;

    for (int i = 0; i < tokens.length - 1; i++) {
      final token = tokens[i];
      if (curr == null) return false;

      if (token is int) {
        if (curr is! List || token >= curr.length) return false;
        curr = curr[token];
      } else if (token is String) {
        if (curr is! Map || !curr.containsKey(token)) return false;
        curr = curr[token];
      } else {
        return false;
      }
    }

    if (curr == null) return false;
    final lastToken = tokens.last;

    if (lastToken is int && curr is List && lastToken < curr.length) {
      if (expectedSource != null && curr[lastToken] != expectedSource) {
        return false;
      }
      curr[lastToken] = value;
      return true;
    } else if (lastToken is String && curr is Map) {
      if (expectedSource != null && curr[lastToken] != expectedSource) {
        return false;
      }
      curr[lastToken] = value;
      return true;
    }

    return false;
  }

  /// Reads and decompresses patch package
  static Map<String, dynamic> loadPatch(String patchPath) {
    final file = File(patchPath);
    if (!file.existsSync()) {
      throw Exception('Patch file not found: $patchPath');
    }

    final bytes = file.readAsBytesSync();
    String jsonStr;

    // Check gzip magic bytes (0x1f 0x8b)
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      final decompressed = gzip.decode(bytes);
      jsonStr = utf8.decode(decompressed);
    } else {
      jsonStr = utf8.decode(bytes);
    }

    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  /// Locates data directory in game path
  static Directory? findDataDir(Directory gameDir) {
    final sep = Platform.pathSeparator;
    final wwwData = Directory('${gameDir.path}${sep}www${sep}data');
    if (wwwData.existsSync()) return wwwData;

    final data = Directory('${gameDir.path}${sep}data');
    if (data.existsSync()) return data;

    try {
      for (final entity in gameDir.listSync()) {
        if (entity is Directory) {
          final subWwwData = Directory('${entity.path}${sep}www${sep}data');
          if (subWwwData.existsSync()) return subWwwData;

          final subData = Directory('${entity.path}${sep}data');
          if (subData.existsSync()) return subData;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Dictionary walk for shifted/reordered dialogues across game versions
  static int applyDictionaryWalk(dynamic node, Map<String, String> dict) {
    if (node == null) return 0;
    int count = 0;

    if (node is Map) {
      // Check Event command
      if (node.containsKey('code') && node['parameters'] is List) {
        final code = node['code'];
        final params = node['parameters'] as List;

        if (code == 401 || code == 105 || code == 405) {
          if (params.isNotEmpty && params[0] is String && dict.containsKey(params[0])) {
            params[0] = dict[params[0]];
            count++;
          }
        } else if (code == 102 && params.isNotEmpty && params[0] is List) {
          final choices = params[0] as List;
          for (int i = 0; i < choices.length; i++) {
            if (choices[i] is String && dict.containsKey(choices[i])) {
              choices[i] = dict[choices[i]];
              count++;
            }
          }
        } else if (code == 101 && params.length > 4 && params[4] is String && dict.containsKey(params[4])) {
          params[4] = dict[params[4]];
          count++;
        } else if ((code == 320 || code == 324) && params.length > 1 && params[1] is String && dict.containsKey(params[1])) {
          params[1] = dict[params[1]];
          count++;
        }
        return count;
      }

      for (final entry in node.entries) {
        if (blacklistedKeys.contains(entry.key)) continue;
        final val = entry.value;
        if (val is String && dict.containsKey(val)) {
          node[entry.key] = dict[val];
          count++;
        } else if (val is Map || val is List) {
          count += applyDictionaryWalk(val, dict);
        }
      }
    } else if (node is List) {
      for (int i = 0; i < node.length; i++) {
        final val = node[i];
        if (val is String && dict.containsKey(val)) {
          node[i] = dict[val];
          count++;
        } else if (val is Map || val is List) {
          count += applyDictionaryWalk(val, dict);
        }
      }
    }

    return count;
  }

  /// Extract base file name from path
  static String getBaseName(String fullPath) {
    final sep = fullPath.contains('/') ? '/' : '\\';
    return fullPath.split(sep).last;
  }

  /// Apply translation patch directly to game folder
  static Future<PatchResult> applyPatch({
    required String gamePath,
    required String patchPath,
    required int modId,
  }) async {
    try {
      final pkg = loadPatch(patchPath);
      final entries = pkg['entries'] as List<dynamic>?;
      if (entries == null) {
        return PatchResult(success: false, error: 'Invalid patch format: missing entries');
      }

      final gameDir = Directory(gamePath);
      final dataDir = findDataDir(gameDir);
      if (dataDir == null) {
        return PatchResult(success: false, error: 'Game data directory not found in $gamePath');
      }

      final sep = Platform.pathSeparator;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupId = 'mod_${modId}_$timestamp';
      final backupDir = Directory('$gamePath$sep.chanolite$sep' 'backups$sep$backupId');
      backupDir.createSync(recursive: true);

      final entriesByFile = <String, List<Map<String, dynamic>>>{};
      for (final rawEntry in entries) {
        final entry = rawEntry as Map<String, dynamic>;
        final tgt = entry['tgt']?.toString() ?? '';
        final src = entry['src']?.toString() ?? '';
        if (tgt.isEmpty || tgt == src) continue;

        final fileName = getBaseName(entry['file']?.toString() ?? '');
        entriesByFile.putIfAbsent(fileName, () => []).add(entry);
      }

      final backedUpFiles = <Map<String, String>>[];
      final patchedFiles = <String>[];
      int totalPatchedEntries = 0;

      for (final fileEntry in entriesByFile.entries) {
        final fileName = fileEntry.key;
        final targetFile = File('${dataDir.path}$sep$fileName');
        if (!targetFile.existsSync()) continue;

        final backupFile = File('${backupDir.path}$sep$fileName');
        targetFile.copySync(backupFile.path);
        backedUpFiles.add({
          'originalPath': targetFile.path,
          'backupPath': backupFile.path,
          'fileName': fileName,
        });

        dynamic jsonRoot;
        try {
          final content = targetFile.readAsStringSync();
          jsonRoot = jsonDecode(content);
        } catch (_) {
          continue;
        }

        int filePatchedCount = 0;
        final unappliedEntries = <Map<String, dynamic>>[];

        for (final entry in fileEntry.value) {
          final tokens = parsePath(entry['key']?.toString() ?? '');
          final ok = setPathValue(jsonRoot, tokens, entry['tgt'], expectedSource: entry['src']);
          if (ok) {
            filePatchedCount++;
          } else {
            unappliedEntries.add(entry);
          }
        }

        if (unappliedEntries.isNotEmpty) {
          final fallbackDict = <String, String>{};
          for (final unapplied in unappliedEntries) {
            final s = unapplied['src']?.toString() ?? '';
            final t = unapplied['tgt']?.toString() ?? '';
            if (s.isNotEmpty && t.isNotEmpty) {
              fallbackDict[s] = t;
            }
          }
          filePatchedCount += applyDictionaryWalk(jsonRoot, fallbackDict);
        }

        targetFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonRoot));
        patchedFiles.add(fileName);
        totalPatchedEntries += filePatchedCount;
      }

      final manifest = {
        'modId': modId,
        'backupId': backupId,
        'timestamp': timestamp,
        'gamePath': gamePath,
        'patchPath': patchPath,
        'backedUpFiles': backedUpFiles,
        'patchedFiles': patchedFiles,
        'totalPatchedEntries': totalPatchedEntries,
      };

      File('${backupDir.path}${sep}backup-manifest.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));

      return PatchResult(
        success: true,
        backupId: backupId,
        totalPatchedEntries: totalPatchedEntries,
        filesModified: patchedFiles.length,
      );
    } catch (e) {
      return PatchResult(success: false, error: e.toString());
    }
  }

  /// Rollback patch
  static Future<bool> rollbackPatch({
    required String gamePath,
    required String backupId,
  }) async {
    try {
      final sep = Platform.pathSeparator;
      final backupDir = Directory('$gamePath$sep.chanolite$sep' 'backups$sep$backupId');
      final manifestFile = File('${backupDir.path}${sep}backup-manifest.json');
      if (!manifestFile.existsSync()) return false;

      final manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final backedUpFiles = manifest['backedUpFiles'] as List<dynamic>? ?? [];

      for (final item in backedUpFiles) {
        final backupPath = item['backupPath']?.toString();
        final originalPath = item['originalPath']?.toString();
        if (backupPath != null && originalPath != null) {
          final bFile = File(backupPath);
          if (bFile.existsSync()) {
            bFile.copySync(originalPath);
          }
        }
      }

      manifestFile.renameSync('${manifestFile.path}.rolledback');
      return true;
    } catch (_) {
      return false;
    }
  }
}
