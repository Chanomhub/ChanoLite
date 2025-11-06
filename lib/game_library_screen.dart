
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/models/download_task.dart';
import 'package:chanolite/screens/account_switcher_sheet.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:chanolite/services/file_opener_service.dart';
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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(context).pop(); // Close the bottom sheet
                _showRenameDialog(context, task); // Show rename dialog
              },
            ),
            if (task.status == DownloadTaskStatus.complete)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  if (task.filePath != null) {
                    FileOpenerService.openFile(task.filePath!);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.of(context).pop(); // Close the bottom sheet
                // Get the DownloadManager and call the delete method
                Provider.of<DownloadManager>(context, listen: false).deleteTask(task);
              },
            ),
          ],
        );
      },
    );
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
                        // Dynamic icon based on file type
                        Expanded(
                          child: Center(
                            child: Icon(
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
