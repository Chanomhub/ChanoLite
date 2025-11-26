import 'package:chanolite/credits_screen.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/screens/account_switcher_sheet.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:chanolite/services/update_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String downloadPathKey = 'download_path';
  final UpdateService _updateService = UpdateService();
  String? _downloadPath;
  bool _isLoading = true;
  String _appVersion = '';
  bool _isCheckingForUpdate = false;
  bool _isLoadingAllVersions = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadDownloadPath();
    await _loadAppVersion();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Version ${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _loadDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString(downloadPathKey);

    if (savedPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      savedPath = directory.path;
    }

    setState(() {
      _downloadPath = savedPath;
    });
  }

  Future<void> _pickDownloadPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(downloadPathKey, selectedDirectory);
      setState(() {
        _downloadPath = selectedDirectory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthManager>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor:
                  Theme.of(context).colorScheme.onPrimaryContainer,
                  child: auth.activeAccount != null
                      ? Text(auth.activeAccount!.username[0].toUpperCase())
                      : const Icon(Icons.person),
                ),
                title: Text(
                  auth.activeAccount?.username ?? 'Not signed in',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  auth.activeAccount?.email ?? 'Tap to sign in',
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  if (auth.accounts.isEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AccountSwitcherSheet(),
                    );
                  }
                },
                trailing: auth.accounts.length > 1
                    ? IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AccountSwitcherSheet(),
                    );
                  },
                )
                    : IconButton(
                  icon: const Icon(Icons.login),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Download Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _downloadPath ?? 'Not set',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickDownloadPath,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose Location'),
            ),
            const SizedBox(height: 24),
            const Text(
              'App Version',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_appVersion),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isCheckingForUpdate ? null : _checkForUpdates,
                  icon: _isCheckingForUpdate
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.update),
                  label: const Text('Check for Updates'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isLoadingAllVersions ? null : _showAllVersions,
                  icon: _isLoadingAllVersions
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.history),
                  label: const Text('All Versions'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Community',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.discord),
                title: const Text('Go to Community'),
                onTap: () => _openUpdateLink('https://discord.gg/QTmeKmKf2w'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Credits'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreditsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('View Licenses'),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'ChanoLite',
                        applicationVersion: _appVersion,
                      );
                    },
                  ),
                ],
              ),
            ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingForUpdate = true;
    });

    try {
      final updateInfo = await _updateService.checkForUpdate();
      if (!mounted) return;

      if (updateInfo != null) {
        _showUpdateDialog(updateInfo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App is up to date')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check for updates: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingForUpdate = false;
        });
      }
    }
  }

  Future<void> _showAllVersions() async {
    setState(() {
      _isLoadingAllVersions = true;
    });

    try {
      final versions = await _updateService.getAllReleases();
      if (!mounted) return;

      if (versions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No releases found')),
        );
        return;
      }

      _showVersionListDialog(versions);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load versions: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAllVersions = false;
        });
      }
    }
  }

  Future<void> _showVersionListDialog(List<AppUpdateInfo> versions) async {
    if (!mounted) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Available Versions'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: versions.length,
              itemBuilder: (context, index) {
                final version = versions[index];
                final isCurrentVersion = version.versionLabel == currentVersion;
                final publishedDate = version.publishedAt != null
                    ? _formatDate(version.publishedAt!)
                    : 'Unknown date';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrentVersion
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        isCurrentVersion ? Icons.check : Icons.download,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            version.versionLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentVersion) ...[
                          const SizedBox(width: 8),
                          const Chip(
                            label: Text('Current'),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            labelStyle: TextStyle(fontSize: 11),
                          ),
                        ],
                        if (index == 0) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text('Latest'),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            labelStyle: const TextStyle(fontSize: 11),
                            backgroundColor:
                            Theme.of(context).colorScheme.tertiaryContainer,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      publishedDate,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showUpdateDialog(version);
                      },
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openUpdateLink(version.releaseUrl);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showUpdateDialog(AppUpdateInfo info) async {
    if (!mounted) return;

    final updateUrl = info.releaseUrl.isNotEmpty
        ? info.releaseUrl
        : 'https://github.com/${_updateService.owner}/${_updateService.repository}/releases/latest';
    final releaseNotesData = info.releaseNotesHtml ?? info.releaseNotes;

    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Version ${info.versionLabel}',
            overflow: TextOverflow.ellipsis,
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
              maxHeight: 360,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (releaseNotesData != null && releaseNotesData.isNotEmpty)
                    Html(
                      data: releaseNotesData,
                      shrinkWrap: true,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(
                            theme.textTheme.bodySmall?.fontSize ?? 14,
                          ),
                          lineHeight: const LineHeight(1.4),
                        ),
                        'p': Style(margin: Margins.only(bottom: 12)),
                        'ul': Style(
                          margin: Margins.only(bottom: 12),
                          padding: HtmlPaddings.only(left: 16),
                        ),
                        'ol': Style(
                          margin: Margins.only(bottom: 12),
                          padding: HtmlPaddings.only(left: 16),
                        ),
                        'li': Style(margin: Margins.only(bottom: 6)),
                        'img': Style(
                          margin: Margins.symmetric(vertical: 12),
                          width: Width(100, Unit.percent),
                          height: Height.auto(),
                        ),
                      },
                      onLinkTap: (url, attributes, element) {
                        if (url != null) {
                          _openUpdateLink(url);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openUpdateLink(updateUrl);
              },
              child: const Text('Download'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUpdateLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      debugPrint('Invalid update url: $url');
      return;
    }

    if (!await canLaunchUrl(uri)) {
      debugPrint('Cannot launch $url');
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}