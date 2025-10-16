
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/screens/account_switcher_sheet.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String downloadPathKey = 'download_path';
  String? _downloadPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadPath();
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
      _isLoading = false;
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
          : Padding(
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
                      title: Text(auth.activeAccount?.username ?? 'Not signed in'),
                      subtitle: Text(auth.activeAccount?.email ?? 'Tap to sign in'),
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
                  Text(_downloadPath ?? 'Not set'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickDownloadPath,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Choose Location'),
                  ),
                ],
              ),
            ),
    );
  }
}
