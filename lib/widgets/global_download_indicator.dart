
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/models/download_task.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GlobalDownloadIndicator extends StatelessWidget {
  const GlobalDownloadIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadManager>(
      builder: (context, downloadManager, child) {
        final runningTasks = downloadManager.tasks
            .where((task) => task.status == DownloadTaskStatus.running)
            .toList();

        if (runningTasks.isEmpty) {
          return const SizedBox.shrink(); // Return empty space if no downloads
        }

        // For simplicity, we show the progress of the first running task
        final task = runningTasks.first;

        return Material(
          child: Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.download, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.fileName ?? 'Downloading...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: task.progress),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text('${(task.progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ),
        );
      },
    );
  }
}
