import '../models/game_tool.dart';

/// Static data for all available game tools
class GameToolsData {
  GameToolsData._();

  static const List<GameTool> tools = [
    // JoiPlay - Main app
    GameTool(
      id: 'joiplay',
      name: 'JoiPlay',
      description: 'Game interpreter for RPG Maker, Ren\'Py, TyranoBuilder, and HTML games',
      packageName: 'cyou.joiplay.joiplay',
      testedVersion: 'v1.21.000-patreon',
      iconUrl: 'https://play-lh.googleusercontent.com/1Z8F8x8Cjg0gBdzjLPJEG3z7LD7TxfGhxaK5qS7h0hQ8EIEv4uJOB8vG2sF2fWQ7hiE',
      supportedEngines: ['RPG Maker MV', 'RPG Maker MZ', 'HTML', 'Construct'],
      downloadSources: [
        ToolDownloadSource(
          name: 'Google Play',
          url: 'https://play.google.com/store/apps/details?id=cyou.joiplay.joiplay',
          type: SourceType.googlePlay,
        ),
        ToolDownloadSource(
          name: 'APKPure',
          url: 'https://apkpure.com/joiplay/cyou.joiplay.joiplay',
          type: SourceType.apk,
        ),
        ToolDownloadSource(
          name: 'Uptodown',
          url: 'https://joiplay.en.uptodown.com/android',
          type: SourceType.apk,
        ),
      ],
    ),

    // JoiPlay RPG Maker Plugin
    GameTool(
      id: 'joiplay-rpgmaker',
      name: 'JoiPlay RPG Maker Plugin',
      description: 'Plugin for playing RPG Maker XP/VX/VX Ace/MV/MZ games',
      packageName: 'cyou.joiplay.rpgmaker',
      supportedEngines: [
        'RPG Maker XP',
        'RPG Maker VX',
        'RPG Maker VX Ace',
        'RPG Maker MV',
        'RPG Maker MZ',
        'RPGM',
        'RPGMV',
        'RPGMZ',
      ],
      downloadSources: [
        ToolDownloadSource(
          name: 'Google Play',
          url: 'https://play.google.com/store/apps/details?id=cyou.joiplay.rpgmaker',
          type: SourceType.googlePlay,
        ),
        ToolDownloadSource(
          name: 'APKPure',
          url: 'https://apkpure.com/joiplay-rpg-maker-plugin/cyou.joiplay.rpgmaker',
          type: SourceType.apk,
        ),
      ],
      isPlugin: true,
      parentToolId: 'joiplay',
    ),

    // JoiPlay Ren'Py Plugin
    GameTool(
      id: 'joiplay-renpy',
      name: 'JoiPlay Ren\'Py Plugin',
      description: 'Plugin for playing Ren\'Py visual novels',
      packageName: 'cyou.joiplay.renpy',
      supportedEngines: ['Ren\'Py', 'RenPy', 'Renpy'],
      downloadSources: [
        ToolDownloadSource(
          name: 'Google Play',
          url: 'https://play.google.com/store/apps/details?id=cyou.joiplay.renpy',
          type: SourceType.googlePlay,
        ),
        ToolDownloadSource(
          name: 'APKPure',
          url: 'https://apkpure.com/joiplay-ren-py-plugin/cyou.joiplay.renpy',
          type: SourceType.apk,
        ),
      ],
      isPlugin: true,
      parentToolId: 'joiplay',
    ),

    // JoiPlay TyranoBuilder Plugin
    GameTool(
      id: 'joiplay-tyrano',
      name: 'JoiPlay TyranoBuilder Plugin',
      description: 'Plugin for playing TyranoBuilder/TyranoScript games',
      packageName: 'cyou.joiplay.tyranobuilder',
      supportedEngines: ['TyranoBuilder', 'TyranoScript', 'Tyrano'],
      downloadSources: [
        ToolDownloadSource(
          name: 'Google Play',
          url: 'https://play.google.com/store/apps/details?id=cyou.joiplay.tyranobuilder',
          type: SourceType.googlePlay,
        ),
        ToolDownloadSource(
          name: 'APKPure',
          url: 'https://apkpure.com/joiplay-tyrano-builder-plugin/cyou.joiplay.tyranobuilder',
          type: SourceType.apk,
        ),
      ],
      isPlugin: true,
      parentToolId: 'joiplay',
    ),

    // GameHub (GameSir/XiaoJi) - Windows PC games on Android via Proton/FEX
    GameTool(
      id: 'gamehub',
      name: 'GameHub',
      description: 'GameSir GameHub — runs Windows PC games on Android through a Proton (Wine) + FEX translation layer. Per-game PC settings: renderer/DXVK/vkd3d, Box64 CPU knobs, memory limit, CPU affinity, Wine env, keymap and translation schemes',
      packageName: 'com.xiaoji.egggame',
      testedVersion: 'v6.3.2',
      supportedEngines: ['Windows', 'PC', 'Win32', 'x64', 'exe', 'Wolf RPG Editor', 'Wolf RPG'],
      downloadSources: [
        ToolDownloadSource(
          name: 'Official Site (website build — local game import)',
          url: 'https://gamehub.xiaoji.com',
          type: SourceType.website,
        ),
        ToolDownloadSource(
          name: 'Google Play (Steam/Epic library only)',
          url: 'https://play.google.com/store/apps/details?id=com.xiaoji.egggame',
          type: SourceType.googlePlay,
        ),
      ],
    ),

    // MTool Mobile - Game interpreter, translator & cheat engine
    GameTool(
      id: 'mtool',
      name: 'MTool Mobile',
      description: 'Gecko & Node.js-based game interpreter, cheat engine, and real-time translator for RPG Maker (MV/MZ/XP/VX), Wolf RPG, and HTML games',
      packageName: 'app.mtool.mtoolmobile',
      testedVersion: 'v54.35 (Build 2013 / 1.0.2012)',
      supportedEngines: [
        'RPG Maker MV',
        'RPG Maker MZ',
        'RPGMV',
        'RPGMZ',
        'HTML',
        'Construct',
        'Wolf RPG Editor',
        'Wolf RPG',
        'RPG Maker XP',
        'RPG Maker VX',
        'RPG Maker VX Ace',
        'RPGM',
        'Ren\'Py',
        'RenPy',
        'EasyRPG',
      ],
      downloadSources: [
        ToolDownloadSource(
          name: 'Official Website',
          url: 'https://mtool.app',
          type: SourceType.website,
        ),
      ],
    ),

    // MTool MKXP-Z Plugin
    GameTool(
      id: 'mtool-mkxpz',
      name: 'MTool MKXP-Z Plugin',
      description: 'Plugin for playing RPG Maker XP/VX/VX Ace games in MTool Mobile',
      packageName: 'app.mtool.mtoolmobile.mkxpz',
      testedVersion: 'v54.35 compatible',
      supportedEngines: [
        'RPG Maker XP',
        'RPG Maker VX',
        'RPG Maker VX Ace',
      ],
      downloadSources: [
        ToolDownloadSource(
          name: 'Official Website',
          url: 'https://mtool.app',
          type: SourceType.website,
        ),
      ],
      isPlugin: true,
      parentToolId: 'mtool',
    ),

    // MTool Ren'Py Plugin
    GameTool(
      id: 'mtool-renpy',
      name: 'MTool Ren\'Py Plugin',
      description: 'Plugin for playing Ren\'Py visual novels in MTool Mobile',
      packageName: 'app.mtool.mtoolmobile.renpy',
      testedVersion: 'v54.35 compatible',
      supportedEngines: ['Ren\'Py', 'RenPy'],
      downloadSources: [
        ToolDownloadSource(
          name: 'Official Website',
          url: 'https://mtool.app',
          type: SourceType.website,
        ),
      ],
      isPlugin: true,
      parentToolId: 'mtool',
    ),

    // MTool EasyRPG Plugin
    GameTool(
      id: 'mtool-easyrpg',
      name: 'MTool EasyRPG Plugin',
      description: 'Plugin for playing EasyRPG / RPG Maker 2000/2003 games in MTool Mobile',
      packageName: 'app.mtool.mtoolmobile.easyrpg',
      testedVersion: 'v54.35 compatible',
      supportedEngines: ['EasyRPG', 'RPG Maker 2000', 'RPG Maker 2003'],
      downloadSources: [
        ToolDownloadSource(
          name: 'Official Website',
          url: 'https://mtool.app',
          type: SourceType.website,
        ),
      ],
      isPlugin: true,
      parentToolId: 'mtool',
    ),
  ];

  /// Get all main tools (not plugins)
  static List<GameTool> get mainTools =>
      tools.where((t) => !t.isPlugin).toList();

  /// Get plugins for a specific parent tool
  static List<GameTool> getPluginsFor(String parentToolId) =>
      tools.where((t) => t.parentToolId == parentToolId).toList();

  /// Get tool by ID
  static GameTool? getToolById(String id) {
    try {
      return tools.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all tools that support a specific engine
  static List<GameTool> getToolsForEngine(String engine) {
    if (engine.isEmpty) return [];
    return tools.where((t) => t.supportsEngine(engine)).toList();
  }
}
