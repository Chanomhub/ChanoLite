import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:chanolite/models/mod_model.dart';
import 'package:chanolite/services/api/api_client.dart';
import 'package:chanolite/services/mod_patch_service.dart';
import 'package:chanolite/services/mod_service.dart';

/// Bottom sheet listing a game's mods from Chanomhub with install/uninstall.
///
/// Two mod kinds are supported:
/// - translation patches (`.patch.json[.gz]`) → ModPatchService rewrites
///   `data/*.json` in place with a rollback backup;
/// - zip archives → extracted over the game dir after a path-traversal check.
class ModListSheet extends StatefulWidget {
  final String gameDir;
  final String? articleSlug;
  final List<int>? thaiFontBytes;
  final ModService? modService;

  const ModListSheet({
    super.key,
    required this.gameDir,
    this.articleSlug,
    this.thaiFontBytes,
    this.modService,
  });

  static Future<void> show(
    BuildContext context, {
    required String gameDir,
    String? articleSlug,
    List<int>? thaiFontBytes,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ModListSheet(
        gameDir: gameDir,
        articleSlug: articleSlug,
        thaiFontBytes: thaiFontBytes,
      ),
    );
  }

  @override
  State<ModListSheet> createState() => _ModListSheetState();
}

class _ModListSheetState extends State<ModListSheet> {
  late final Future<List<GameMod>> _modsFuture;
  List<InstalledModRecord> _installed = [];
  int? _installingModId;
  String _status = '';

  @override
  void initState() {
    super.initState();
    final slug = widget.articleSlug;
    _modsFuture = (slug == null || slug.isEmpty)
        ? Future.value([])
        : (widget.modService ?? ModService()).getModsForArticle(slug);
    ModPatchService.loadInstalledMods(widget.gameDir).then((mods) {
      if (mounted) setState(() => _installed = mods);
    });
  }

  bool _isPatch(GameMod mod) =>
      (mod.downloadLink ?? '').toLowerCase().contains('.patch.json');

  bool _isZip(GameMod mod) =>
      (mod.downloadLink ?? '').toLowerCase().endsWith('.zip');

  bool _isInstalled(int modId) => _installed.any((m) => m.id == modId);

  Future<void> _install(GameMod mod) async {
    setState(() {
      _installingModId = mod.id;
      _status = 'Downloading ${mod.name ?? 'mod'}...';
    });
    try {
      final file = await _downloadModFile(mod);
      if (!mounted) return;
      setState(() => _status = 'Installing...');

      if (_isPatch(mod)) {
        final result = ModPatchService.applyPatchSync(
          gameDir: widget.gameDir,
          patchPath: file.path,
          modId: mod.id,
          thaiFontBytes: widget.thaiFontBytes,
        );
        await _rememberInstall(mod, result.backupId);
        if (mounted) {
          setState(() {
            _status =
                'Installed: ${result.totalPatchedEntries} strings in '
                '${result.filesModified} files'
                '${result.fontInjected ? ' + Thai font' : ''}';
          });
        }
      } else if (_isZip(mod)) {
        final count = await _extractZip(file.path);
        await _rememberInstall(mod, '');
        if (mounted) setState(() => _status = 'Installed: $count files');
      } else if (mounted) {
        setState(() => _status = 'Unsupported mod format for mobile install');
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _installingModId = null);
    }
  }

  Future<void> _rememberInstall(GameMod mod, String backupId) async {
    _installed = [
      ..._installed.where((m) => m.id != mod.id),
      InstalledModRecord(
        id: mod.id,
        name: mod.name ?? 'Mod ${mod.id}',
        version: mod.version ?? '',
        installedAt: DateTime.now().toIso8601String(),
        filename: mod.downloadLink?.split('/').last ?? '',
        backupId: backupId,
      ),
    ];
    await ModPatchService.saveInstalledMods(widget.gameDir, _installed);
  }

  /// Downloads the mod payload to a temp file. Auth token attached because
  /// storage links may require the owner session.
  /// ponytail: whole-file http.get — fine for patch.json.gz (~50KB), add a
  /// streamed download if big zip mods become common.
  Future<File> _downloadModFile(GameMod mod) async {
    final link = mod.downloadLink;
    if (link == null || link.isEmpty) {
      throw StateError('Mod has no download link');
    }
    final headers = <String, String>{};
    final token = ApiClient.authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(Uri.parse(link), headers: headers);
    if (response.statusCode != 200) {
      throw StateError('Download failed: HTTP ${response.statusCode}');
    }
    final dir = await getTemporaryDirectory();
    final fileName = link.split('/').last.split('?').first;
    final file = File('${dir.path}/mod_${mod.id}_$fileName');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  /// Extracts a zip over the game directory, rejecting entries that escape it.
  /// ponytail: zip mods get no backup/rollback (patches do); add a copied-tree
  /// snapshot if uninstalling zip mods becomes a real request.
  Future<int> _extractZip(String zipPath) async {
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    final gameRoot = p.normalize(widget.gameDir);
    var count = 0;
    for (final entry in archive) {
      final normalized =
          p.normalize(p.join(gameRoot, entry.name.replaceAll('\\', '/')));
      if (normalized != gameRoot && !p.isWithin(gameRoot, normalized)) {
        throw StateError('Blocked unsafe path in mod archive: ${entry.name}');
      }
      if (entry.isFile) {
        final outFile = File(normalized);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(entry.content as List<int>);
        count++;
      }
    }
    return count;
  }

  Future<void> _uninstall(InstalledModRecord record) async {
    setState(() => _status = 'Uninstalling ${record.name}...');
    try {
      if (record.backupId.isNotEmpty) {
        ModPatchService.rollback(widget.gameDir, record);
      }
      _installed = _installed.where((m) => m.id != record.id).toList();
      await ModPatchService.saveInstalledMods(widget.gameDir, _installed);
      if (mounted) setState(() => _status = 'Uninstalled ${record.name}');
    } catch (e) {
      if (mounted) setState(() => _status = 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.extension),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mods — ${p.basename(p.normalize(widget.gameDir))}',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (widget.articleSlug == null || widget.articleSlug!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'This game was not linked to a Chanomhub article, '
                  'so its mod list is unknown.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              Flexible(
                child: FutureBuilder<List<GameMod>>(
                  future: _modsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Failed to load mods: ${snapshot.error}',
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    }
                    final mods = snapshot.data ?? [];
                    if (mods.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No mods available for this game yet.',
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: mods.length,
                      itemBuilder: (context, index) {
                        final mod = mods[index];
                        final installed = _isInstalled(mod.id);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            _isPatch(mod) ? Icons.translate : Icons.folder_zip,
                            color: installed ? Colors.green : null,
                          ),
                          title: Text(
                            mod.name ?? 'Mod ${mod.id}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              if (mod.version != null) 'v${mod.version}',
                              if (mod.type != null) mod.type!,
                              if (mod.language != null) mod.language!,
                              if (installed) 'installed',
                            ].join(' · '),
                          ),
                          trailing: _installingModId == mod.id
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : TextButton(
                                  onPressed: () => _install(mod),
                                  child: Text(
                                      installed ? 'REINSTALL' : 'INSTALL'),
                                ),
                          onLongPress: installed
                              ? () => _uninstall(
                                  _installed.firstWhere((m) => m.id == mod.id))
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_status, style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}
