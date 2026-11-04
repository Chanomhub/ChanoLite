import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import '../models/game_tool.dart';
import 'installed_apps_service.dart';

import 'game_tools_catalog.dart';
import '../managers/library_manager.dart';

/// Service for managing game tools
class GameToolsService {
  GameToolsService._();

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
    if (!Platform.isAndroid) return false;
    return await InstalledAppsService.isAppInstalled(tool.packageName);
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

        case 'minhub':
          return await _launchMinHub(gamePath);

        case 'mtool':
        case 'mtool-mkxpz':
        case 'mtool-renpy':
        case 'mtool-easyrpg':
          return await _launchMTool(gamePath);

        default:
          // Generic launch - just open the tool
          return await launchTool(tool);
      }
    } catch (e) {
      print('GameToolsService: Error launching game with tool: $e');
      return false;
    }
  }

  /// Launch game with MTool Mobile
  static Future<bool> _launchMTool(String gamePath) async {
    try {
      final dataUri = gamePath.startsWith('/') ? 'file://$gamePath' : gamePath;
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'app.mtool.mtoolmobile',
        componentName: 'app.mtool.mtoolmobile.StartActivity',
        data: dataUri,
        arguments: <String, dynamic>{
          'gamePath': gamePath,
        },
      );
      await intent.launch();
      return true;
    } catch (e) {
      print('GameToolsService: Error launching MTool: $e');
      return await InstalledAppsService.launchApp('app.mtool.mtoolmobile');
    }
  }

  /// Launch game with MinHub
  static Future<bool> _launchMinHub(String gamePath) async {
    try {
      final dataUri = gamePath.startsWith('/') ? 'file://$gamePath' : gamePath;
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.minhub.gamehub',
        data: dataUri,
      );
      await intent.launch();
      return true;
    } catch (e) {
      print('GameToolsService: Error launching MinHub: $e');
      return await InstalledAppsService.launchApp('com.minhub.gamehub');
    }
  }

  /// Launch game with JoiPlay.
  ///
  /// Verified from cyou.joiplay.joiplay (jadx): the VIEW intent lands in
  /// SplashActivity → MainActivity → LauncherFragment.showTitleDialogWithIntent,
  /// which builds a pre-filled Add-Game entry from the path — the user only
  /// confirms the title and taps Next. JoiPlay needs the EXECUTABLE path
  /// (index.html / Game.exe) to pre-fill; a bare folder can't be resolved.
  /// Games live in the public Downloads dir (saveInPublicStorage), which
  /// JoiPlay can read via its MANAGE_EXTERNAL_STORAGE permission.
  static Future<bool> _launchJoiPlay(String gamePath) async {
    try {
      var target = gamePath;
      if (FileSystemEntity.typeSync(gamePath) == FileSystemEntityType.directory) {
        final exe = await LibraryManager.findGameExecutable(gamePath);
        if (exe != null) target = exe;
      }
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'cyou.joiplay.joiplay',
        data: 'file://$target',
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

  /// Get installation status for all tools
  static Future<Map<String, bool>> getToolsInstallationStatus() async {
    final status = <String, bool>{};
    for (final tool in getAllTools()) {
      status[tool.id] = await isToolInstalled(tool);
    }
    return status;
  }
}
