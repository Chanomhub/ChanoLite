
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/models/download_task.dart';
import 'package:chanolite/screens/account_switcher_sheet.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:chanolite/services/file_opener_service.dart';
import 'package:chanolite/services/installed_apps_service.dart';
import 'package:chanolite/services/game_tools_service.dart';
import 'package:chanolite/widgets/tool_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameLibraryScreen extends StatefulWidget {
  const GameLibraryScreen({super.key});

  @override
  _GameLibraryScreenState createState() => _GameLibraryScreenState();
}

class _GameLibraryScreenState extends State<GameLibraryScreen> {
  final Set<DownloadTask> _selectedTasks = {};
  bool _isSelectionMode = false;

  void _showRenameDialog(BuildContext context, DownloadTask task) {
    final TextEditingController _renameController = TextEditingController(text: task.fileName);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename File'),
          content: TextField(
            controller: _renameController,
            decoration: const InputDecoration(hintText: 'Enter new file name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Rename'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (_renameController.text.isNotEmpty && _renameController.text != task.fileName) {
                  Provider.of<DownloadManager>(context, listen: false)
                      .renameTask(task, _renameController.text);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showContextMenu(BuildContext context, DownloadTask task) {
    final isApk = task.fileName?.toLowerCase().endsWith('.apk') ?? false;
    final hasEngine = task.engine != null && task.engine!.isNotEmpty;
    final downloadManager = Provider.of<DownloadManager>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(context).pop();
                _showRenameDialog(context, task);
              },
            ),
            // Open/Install option for completed downloads
            if (task.status == DownloadTaskStatus.complete)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(isApk ? 'Install APK' : 'Open'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (task.filePath != null) {
                    FileOpenerService.openFile(task.filePath!);
                  }
                },
              ),
            // Play with Tool option (for games with engine info)
            if (task.status == DownloadTaskStatus.complete && hasEngine && !isApk)
              ListTile(
                leading: const Icon(Icons.sports_esports),
                title: const Text('Play with Tool'),
                subtitle: Text('Engine: ${task.engine}'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _playWithTool(context, task);
                },
              ),
            // Launch installed app option (only for APK with package name)
            if (task.status == DownloadTaskStatus.complete && task.packageName != null)
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Launch App'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final success = await InstalledAppsService.launchApp(task.packageName!);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App not installed or could not be launched')),
                    );
                  }
                },
              ),
            // Retry option for failed or stuck downloads
            if (task.status == DownloadTaskStatus.failed || 
                task.status == DownloadTaskStatus.canceled)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry Download'),
                onTap: () {
                  Navigator.of(context).pop();
                  downloadManager.retryTask(task);
                },
              ),
            // Cancel option for running/enqueued downloads
            if (task.status == DownloadTaskStatus.running ||
                task.status == DownloadTaskStatus.enqueued)
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel Download'),
                onTap: () {
                  Navigator.of(context).pop();
                  downloadManager.cancelTask(task);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.of(context).pop();
                downloadManager.deleteTask(task);
              },
            ),
            const Divider(),
            // Debug Info option
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug Info'),
              onTap: () {
                Navigator.of(context).pop();
                _showDebugInfo(context, task);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDebugInfo(BuildContext context, DownloadTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _debugRow('Status', task.status.name),
              _debugRow('Progress', '${(task.progress * 100).toStringAsFixed(1)}%'),
              _debugRow('TaskId', task.taskId ?? 'null'),
              _debugRow('FileName', task.fileName ?? 'null'),
              _debugRow('FilePath', task.filePath ?? 'null'),
              _debugRow('Type', task.type.name),
              _debugRow('Engine', task.engine ?? 'null'),
              _debugRow('Version', task.version ?? 'null'),
              _debugRow('PackageName', task.packageName ?? 'null'),
              const Divider(),
              const Text('URL:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(task.url, style: const TextStyle(fontSize: 10)),
              const Divider(),
              const Text('ImageUrl:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(task.imageUrl ?? 'null', style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _playWithTool(BuildContext context, DownloadTask task) async {
    if (task.engine == null || task.filePath == null) return;

    // Get installed tools for this engine
    final installedTools = await GameToolsService.getInstalledToolsForEngine(task.engine!);

    if (!context.mounted) return;

    if (installedTools.isEmpty) {
      // No tools installed - show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tools installed for ${task.engine} games'),
          action: SnackBarAction(
            label: 'Get Tools',
            onPressed: () {
              // Navigate to tools tab (index 3)
              // Find MainScreen's state and update tab
            },
          ),
        ),
      );
      return;
    }

    bool success;
    if (installedTools.length == 1) {
      // Only one tool - launch directly
      success = await GameToolsService.launchGameWithTool(installedTools.first, task.filePath!);
    } else {
      // Multiple tools - show selection dialog
      final selectedTool = await ToolSelectionDialog.show(
        context,
        tools: installedTools,
        gamePath: task.filePath,
        engineName: task.engine,
      );

      if (selectedTool != null) {
        success = await GameToolsService.launchGameWithTool(selectedTool, task.filePath!);
      } else {
        return; // User cancelled
      }
    }

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to launch game with tool')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Text('${_selectedTasks.length} selected'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedTasks.clear();
                  });
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    final downloadManager = Provider.of<DownloadManager>(context, listen: false);
                    for (var task in _selectedTasks) {
                      downloadManager.deleteTask(task);
                    }
                    setState(() {
                      _isSelectionMode = false;
                      _selectedTasks.clear();
                    });
                  },
                ),
              ],
            )
          : AppBar(
              title: const Text('Game Library'),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'clear_stuck') {
                      final downloadManager = Provider.of<DownloadManager>(context, listen: false);
                      downloadManager.clearStuckDownloads();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cleared stuck downloads')),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear_stuck',
                      child: Row(
                        children: [
                          Icon(Icons.cleaning_services),
                          SizedBox(width: 8),
                          Text('Clear Stuck Downloads'),
                        ],
                      ),
                    ),
                  ],
                ),
                Consumer<AuthManager>(
                  builder: (context, auth, _) {
                    final theme = Theme.of(context);
                    final user = auth.activeAccount;
                    final hasAccounts = auth.accounts.isNotEmpty;
                    final imageUrl = user?.image ?? '';
                    final avatar = imageUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(imageUrl),
                            backgroundColor: theme.colorScheme.primaryContainer,
                          )
                        : CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                            child: Text(
                              user?.username.isNotEmpty == true
                                  ? user!.username[0].toUpperCase()
                                  : '+',
                            ),
                          );

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            if (hasAccounts) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const AccountSwitcherSheet(),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: avatar,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: Consumer<DownloadManager>(
        builder: (context, downloadManager, child) {
          if (downloadManager.tasks.isEmpty) {
            return const Center(
              child: Text('No downloads yet.'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: downloadManager.tasks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8, // Adjust aspect ratio for a "block" feel
            ),
            itemBuilder: (context, index) {
              final task = downloadManager.tasks[index];
              final isSelected = _selectedTasks.contains(task);

              return GestureDetector(
                onTap: () {
                  if (_isSelectionMode) {
                    setState(() {
                      if (isSelected) {
                        _selectedTasks.remove(task);
                      } else {
                        _selectedTasks.add(task);
                      }
                    });
                  } else {
                    _showContextMenu(context, task);
                  }
                },
                onLongPress: () {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedTasks.add(task);
                  });
                },
                child: Card(
                  color: isSelected ? Colors.blue.withOpacity(0.5) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic icon based on file type or image
                        Expanded(
                          child: Center(
                            child: task.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: task.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) => Container(color: Colors.grey[300]),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  )
                                : Icon(
                                    task.type == DownloadType.archive ? Icons.archive : Icons.insert_drive_file,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.fileName ?? task.url,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2, // Allow for 2 lines
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.version != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'v${task.version}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 4),
                        // Combined status and progress row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (task.status == DownloadTaskStatus.running)
                              Expanded(child: LinearProgressIndicator(value: task.progress))
                            else
                              Text(task.status.name, style: const TextStyle(fontSize: 12)),

                            const SizedBox(width: 8),

                            if (task.status == DownloadTaskStatus.running)
                              Text('${(task.progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12))
                            else if (task.status == DownloadTaskStatus.complete)
                              const Icon(Icons.check_circle, color: Colors.green, size: 16)
                            else if (task.status == DownloadTaskStatus.failed)
                              const Icon(Icons.error, color: Colors.red, size: 16),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
