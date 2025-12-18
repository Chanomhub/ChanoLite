import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/game_tools_data.dart';
import '../models/game_tool.dart';
import '../services/game_tools_service.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  Map<String, bool> _installationStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstallationStatus();
  }

  Future<void> _loadInstallationStatus() async {
    if (!Platform.isAndroid) {
      setState(() => _isLoading = false);
      return;
    }

    final status = await GameToolsService.getToolsInstallationStatus();
    if (mounted) {
      setState(() {
        _installationStatus = status;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainTools = GameToolsData.mainTools;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadInstallationStatus();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !Platform.isAndroid
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.android, size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Game Tools are only available on Android',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Install these tools to play games from different engines on your device.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main tools
                    ...mainTools.map((tool) => _buildToolCard(context, tool)),
                  ],
                ),
    );
  }

  Widget _buildToolCard(BuildContext context, GameTool tool) {
    final theme = Theme.of(context);
    final isInstalled = _installationStatus[tool.id] ?? false;
    final plugins = GameToolsData.getPluginsFor(tool.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main tool header
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getToolIcon(tool.id),
                color: theme.colorScheme.primary,
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(tool.name)),
                _buildStatusChip(context, isInstalled),
              ],
            ),
            subtitle: Text(
              tool.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Supported engines
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tool.supportedEngines.take(5).map((engine) => Chip(
                label: Text(engine, style: const TextStyle(fontSize: 11)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              )).toList(),
            ),
          ),

          // Download buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tool.downloadSources.map((source) => 
                _buildDownloadButton(context, source, isInstalled)
              ).toList(),
            ),
          ),

          // Plugins section
          if (plugins.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required Plugins',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...plugins.map((plugin) => _buildPluginTile(context, plugin)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPluginTile(BuildContext context, GameTool plugin) {
    final theme = Theme.of(context);
    final isInstalled = _installationStatus[plugin.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plugin.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildStatusChip(context, isInstalled),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            plugin.supportedEngines.join(', '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: plugin.downloadSources.map((source) => 
              _buildDownloadButton(context, source, isInstalled, compact: true)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, bool isInstalled) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isInstalled 
            ? Colors.green.withOpacity(0.2) 
            : theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isInstalled ? 'Installed' : 'Not Installed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isInstalled ? Colors.green : theme.colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context, 
    ToolDownloadSource source, 
    bool isInstalled, {
    bool compact = false,
  }) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: () => _openDownloadSource(source),
      icon: Icon(_getSourceIcon(source.type), size: compact ? 14 : 16),
      label: Text(source.name),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12, 
          vertical: compact ? 4 : 8,
        ),
        textStyle: TextStyle(fontSize: compact ? 11 : 12),
        visualDensity: compact ? VisualDensity.compact : null,
      ),
    );
  }

  Future<void> _openDownloadSource(ToolDownloadSource source) async {
    final uri = Uri.tryParse(source.url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _getToolIcon(String toolId) {
    switch (toolId) {
      case 'joiplay':
        return Icons.sports_esports;
      case 'kirikiroid2':
        return Icons.menu_book;
      case 'easyrpg':
        return Icons.videogame_asset;
      case 'onscripter':
        return Icons.auto_stories;
      case 'ppsspp':
        return Icons.gamepad;
      case 'exagear':
        return Icons.computer;
      default:
        return Icons.extension;
    }
  }

  IconData _getSourceIcon(SourceType type) {
    switch (type) {
      case SourceType.googlePlay:
        return Icons.shop;
      case SourceType.apk:
        return Icons.android;
      case SourceType.github:
        return Icons.code;
      case SourceType.website:
        return Icons.language;
    }
  }
}
