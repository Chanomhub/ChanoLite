import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import '../constants/game_tools_data.dart';
import '../models/game_tool.dart';
import 'installed_apps_service.dart';

/// Service for managing game tools
class GameToolsService {
  GameToolsService._();

  /// Get all available tools
  static List<GameTool> getAllTools() => GameToolsData.tools;

  /// Get all main tools (excluding plugins)
  static List<GameTool> getMainTools() => GameToolsData.mainTools;

  /// Get plugins for a parent tool
  static List<GameTool> getPluginsFor(String parentToolId) =>
      GameToolsData.getPluginsFor(parentToolId);

  /// Get tool by ID
  static GameTool? getToolById(String id) => GameToolsData.getToolById(id);

  /// Get all tools that support a specific engine
  static List<GameTool> getToolsForEngine(String engine) =>
      GameToolsData.getToolsForEngine(engine);

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
}
