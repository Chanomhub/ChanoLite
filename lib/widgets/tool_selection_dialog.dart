import 'package:flutter/material.dart';
import '../models/game_tool.dart';
import '../services/game_tools_service.dart';

/// Dialog for selecting a tool when multiple tools support the same engine
class ToolSelectionDialog extends StatelessWidget {
  final List<GameTool> tools;
  final String? gamePath;
  final String? engineName;

  const ToolSelectionDialog({
    super.key,
    required this.tools,
    this.gamePath,
    this.engineName,
  });

  /// Show the tool selection dialog and return the selected tool
  static Future<GameTool?> show(
    BuildContext context, {
    required List<GameTool> tools,
    String? gamePath,
    String? engineName,
  }) async {
    return showModalBottomSheet<GameTool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ToolSelectionDialog(
        tools: tools,
        gamePath: gamePath,
        engineName: engineName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Select Tool',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (engineName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Multiple tools support $engineName',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Tool options
          ...tools.map((tool) => _buildToolOption(context, tool)),

          const SizedBox(height: 12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolOption(BuildContext context, GameTool tool) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectTool(context, tool),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sports_esports,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTool(BuildContext context, GameTool tool) async {
    Navigator.of(context).pop(tool);
  }
}

/// Helper to show tool selection or directly launch if only one tool
Future<bool> showToolSelectionAndLaunch(
  BuildContext context, {
  required String engine,
  String? gamePath,
}) async {
  // Get installed tools for this engine
  final installedTools = await GameToolsService.getInstalledToolsForEngine(engine);

  if (installedTools.isEmpty) {
    // No tools installed - show message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tools installed for $engine games'),
          action: SnackBarAction(
            label: 'Get Tools',
            onPressed: () {
              // Navigate to tools screen
              Navigator.of(context).pushNamed('/tools');
            },
          ),
        ),
      );
    }
    return false;
  }

  if (installedTools.length == 1) {
    // Only one tool - launch directly
    final tool = installedTools.first;
    if (gamePath != null) {
      return await GameToolsService.launchGameWithTool(tool, gamePath);
    } else {
      return await GameToolsService.launchTool(tool);
    }
  }

  // Multiple tools - show selection dialog
  if (!context.mounted) return false;
  
  final selectedTool = await ToolSelectionDialog.show(
    context,
    tools: installedTools,
    gamePath: gamePath,
    engineName: engine,
  );

  if (selectedTool != null) {
    if (gamePath != null) {
      return await GameToolsService.launchGameWithTool(selectedTool, gamePath);
    } else {
      return await GameToolsService.launchTool(selectedTool);
    }
  }

  return false;
}
