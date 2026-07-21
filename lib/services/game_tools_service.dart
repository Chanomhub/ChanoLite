import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import '../constants/game_tools_data.dart';
import '../models/game_tool.dart';
import 'installed_apps_service.dart';

import '../managers/download_manager.dart';

import 'game_tools_catalog.dart';

/// Service for managing game tools
class GameToolsService {
  GameToolsService._();

  /// Start downloading Proton directly using the provided DownloadManager
  static Future<void> startProtonDownload(DownloadManager downloadManager) async {
    final protonTool = getToolById('proton-ce');
    if (protonTool == null) return;

    // Use the direct download link if available (the first source in our list)
    final directSource = protonTool.downloadSources.firstWhere(
      (s) => s.url.endsWith('.tar.gz') || s.url.endsWith('.tar.xz'),
      orElse: () => protonTool.downloadSources.first,
    );

    print('GameToolsService: Starting direct download for Proton: ${directSource.url}');
    
    await downloadManager.startDownload(
      directSource.url,
      suggestedFilename: 'GE-Proton-Latest.tar.gz',
      engine: 'proton-install',
    );
  }

  /// Get all available tools
  static List<GameTool> getAllTools() => GameToolsCatalog.getAllTools();

  /// Get all main tools (excluding plugins)
  static List<GameTool> getMainTools() => GameToolsCatalog.getMainTools();

  /// Get plugins for a parent tool
  static List<GameTool> getPluginsFor(String parentToolId) =>
      GameToolsCatalog.getPluginsFor(parentToolId);

  /// Get tool by ID
  static GameTool? getToolById(String id) => GameToolsCatalog.getToolById(id);

  /// Get all tools that support a specific engine
  static List<GameTool> getToolsForEngine(String engine) =>
      GameToolsCatalog.getToolsForEngine(engine);

  /// Check if a tool is installed
  static Future<bool> isToolInstalled(GameTool tool) async {
    if (tool.id == 'proton-ce') {
      return await isProtonInstalled();
    }
    if (!Platform.isAndroid) return false;
    return await InstalledAppsService.isAppInstalled(tool.packageName);
  }

  /// Check if Proton is manually installed in the Linux environment
  static Future<bool> isProtonInstalled() async {
    final home = Platform.environment['HOME'] ?? '/home/jop';
    final protonPath = '$home/.steam/root/steamapps/common/Proton 10.0/proton';
    return await File(protonPath).exists();
  }

  /// Install Proton from a downloaded archive
  static Future<bool> installProton(String archivePath) async {
    final home = Platform.environment['HOME'] ?? '/home/jop';
    final installDir = '$home/.steam/root/steamapps/common/';
    
    try {
      print('GameToolsService: Installing Proton to $installDir...');
      
      // Create destination directory
      final dir = Directory(installDir);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      final shell = Platform.isAndroid ? '/system/bin/sh' : 'sh';

      // Delete existing Proton 10.0 directory if it exists to avoid conflicts
      final proton10Dir = '$installDir/Proton 10.0';
      print('GameToolsService: Removing existing $proton10Dir if any...');
      await Process.run(shell, ['-c', 'rm -rf "$proton10Dir"']);

      final command = 'tar -xf "$archivePath" -C "$installDir"';
      
      print('GameToolsService: Executing install command: $command');

      final result = await Process.run(shell, ['-c', command]);
      
      if (result.exitCode == 0) {
        print('GameToolsService: Extraction successful.');
        
        // Find the newly extracted folder and rename it to "Proton 10.0"
        final findAndRenameCommand = 'cd "$installDir" && mv GE-Proton* "Proton 10.0"';
        final mvResult = await Process.run(shell, ['-c', findAndRenameCommand]);
        
        if (mvResult.exitCode == 0) {
            print('GameToolsService: Rename to "Proton 10.0" successful.');
        } else {
            print('GameToolsService: Failed to rename folder (may already be correct): ${mvResult.stderr}');
        }

        // Clean up the archive file to save space
        await Process.run(shell, ['-c', 'rm -f "$archivePath"']);
        print('GameToolsService: Cleaned up archive file.');

        return true;
      } else {
        print('GameToolsService: Extraction failed: ${result.stderr}');
        return false;
      }
    } catch (e) {
      print('GameToolsService: Error installing Proton: $e');
      return false;
    }
  }

  /// Check if a tool and its required parent (if any) are installed
  static Future<bool> isToolFullyInstalled(GameTool tool) async {
    if (!Platform.isAndroid) return false;

    // Check main tool
    final isInstalled = await isToolInstalled(tool);
    if (!isInstalled) return false;

    // If it's a plugin, check parent tool
    if (tool.isPlugin && tool.parentToolId != null) {
      final parentTool = getToolById(tool.parentToolId!);
      if (parentTool != null) {
        return await isToolInstalled(parentTool);
      }
    }

    return true;
  }

  /// Get all installed tools for a specific engine
  static Future<List<GameTool>> getInstalledToolsForEngine(String engine) async {
    if (!Platform.isAndroid) return [];

    final supportingTools = getToolsForEngine(engine);
    final installedTools = <GameTool>[];

    for (final tool in supportingTools) {
      if (await isToolFullyInstalled(tool)) {
        installedTools.add(tool);
      }
    }

    return installedTools;
  }

  /// Launch a tool
  static Future<bool> launchTool(GameTool tool) async {
    if (!Platform.isAndroid) return false;
    return await InstalledAppsService.launchApp(tool.packageName);
  }

  /// Launch a game with a specific tool
  /// Returns true if launch was successful
  static Future<bool> launchGameWithTool(GameTool tool, String gamePath) async {
    // Handle Proton manual command for Linux and Android environments (like Termux)
    if (tool.id == 'proton-ce') {
      return await _launchProton(gamePath);
    }

    if (!Platform.isAndroid) return false;

    try {
      // Different tools have different ways to open games
      switch (tool.id) {
        case 'joiplay':
        case 'joiplay-rpgmaker':
        case 'joiplay-renpy':
        case 'joiplay-tyrano':
          return await _launchJoiPlay(gamePath);

        case 'kirikiroid2':
          return await _launchKirikiroid2(gamePath);

        case 'easyrpg':
          return await _launchEasyRPG(gamePath);

        case 'ppsspp':
          return await _launchPPSSPP(gamePath);

        default:
          // Generic launch - just open the tool
          return await launchTool(tool);
      }
    } catch (e) {
      print('GameToolsService: Error launching game with tool: $e');
      return false;
    }
  }

  /// Launch game with JoiPlay
  static Future<bool> _launchJoiPlay(String gamePath) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'cyou.joiplay.joiplay',
        data: 'file://$gamePath',
      );
      await intent.launch();
      return true;
    } catch (e) {
      print('GameToolsService: Error launching JoiPlay: $e');
      // Fallback: just open JoiPlay
      return await InstalledAppsService.launchApp('cyou.joiplay.joiplay');
    }
  }

  /// Launch game with Kirikiroid2
  static Future<bool> _launchKirikiroid2(String gamePath) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'org.tvp.kirikiri2',
        data: 'file://$gamePath',
      );
      await intent.launch();
      return true;
    } catch (e) {
      print('GameToolsService: Error launching Kirikiroid2: $e');
      return await InstalledAppsService.launchApp('org.tvp.kirikiri2');
    }
  }

  /// Launch game with EasyRPG Player
  static Future<bool> _launchEasyRPG(String gamePath) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'org.easyrpg.player',
        data: 'file://$gamePath',
      );
      await intent.launch();
      return true;
    } catch (e) {
      print('GameToolsService: Error launching EasyRPG: $e');
      return await InstalledAppsService.launchApp('org.easyrpg.player');
    }
  }

  /// Launch game with PPSSPP
  static Future<bool> _launchPPSSPP(String gamePath) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'org.ppsspp.ppsspp',
        data: 'file://$gamePath',
        type: 'application/octet-stream',
      );
      await intent.launch();
      return true;
    } catch (e) {
      print('GameToolsService: Error launching PPSSPP: $e');
      return await InstalledAppsService.launchApp('org.ppsspp.ppsspp');
    }
  }

  /// Get installation status for all tools
  static Future<Map<String, bool>> getToolsInstallationStatus() async {
    final status = <String, bool>{};
    for (final tool in getAllTools()) {
      status[tool.id] = await isToolInstalled(tool);
    }
    return status;
  }

  /// Launch game with Proton (Linux-style command for Android/Linux shells with GUI support)
  static Future<bool> _launchProton(String gamePath) async {
    // Attempt to use system home, or fallback to your example
    final home = Platform.environment['HOME'] ?? '/home/jop';
    
    // Command parts from your example
    final protonPath = '$home/.steam/root/steamapps/common/Proton 10.0/proton';
    final steamClientPath = '$home/.local/share/Steam';
    final compatDataPath = '$home/proton-prefix/mygame';

    try {
      print('GameToolsService: Running Proton with GUI Support...');
      
      // Create compat data directory if needed
      final compatDir = Directory(compatDataPath);
      if (!compatDir.existsSync()) {
        await compatDir.create(recursive: true);
      }

      // We run this via /system/bin/sh (Android) or sh (Linux)
      final shell = Platform.isAndroid ? '/system/bin/sh' : 'sh';

      // Build the command with GUI (DISPLAY) and Audio (PULSE_SERVER) support
      // We use export to ensure variables are available to the proton process and its children
      final command = 
          'export DISPLAY=:0; '
          'export PULSE_SERVER=127.0.0.1; '
          'export STEAM_COMPAT_CLIENT_INSTALL_PATH="$steamClientPath"; '
          'export STEAM_COMPAT_DATA_PATH="$compatDataPath"; '
          '"$protonPath" run "$gamePath"';

      print('GameToolsService: Executing: $command');

      await Process.start(
        shell,
        ['-c', command],
        mode: ProcessStartMode.detached,
      );

      return true;
    } catch (e) {
      print('GameToolsService: Error running Proton via Shell: $e');
      return false;
    }
  }
}
