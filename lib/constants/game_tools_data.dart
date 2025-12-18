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
          url: 'https://apkpure.com/joiplay-tyranobuilder-plugin/cyou.joiplay.tyranobuilder',
          type: SourceType.apk,
        ),
      ],
      isPlugin: true,
      parentToolId: 'joiplay',
    ),

    // Kirikiroid2
    GameTool(
      id: 'kirikiroid2',
      name: 'Kirikiroid2',
      description: 'Player for Kirikiri/KAG engine visual novels (.xp3 files)',
      packageName: 'org.tvp.kirikiri2',
      supportedEngines: ['Kirikiri', 'KAG', 'Kirikiri2', 'xp3'],
      downloadSources: [
        ToolDownloadSource(
          name: 'GitHub',
          url: 'https://github.com/zeas2/Kirikiroid2/releases',
          type: SourceType.github,
        ),
        ToolDownloadSource(
          name: 'APKFab',
          url: 'https://apkfab.com/kirikiroid2/org.tvp.kirikiri2',
          type: SourceType.apk,
        ),
      ],
    ),

    // EasyRPG Player
    GameTool(
      id: 'easyrpg',
      name: 'EasyRPG Player',
      description: 'Open-source player for RPG Maker 2000/2003 games',
      packageName: 'org.easyrpg.player',
      supportedEngines: ['RPG Maker 2000', 'RPG Maker 2003', 'RM2K', 'RM2K3', 'RPG2000', 'RPG2003'],
      downloadSources: [
        ToolDownloadSource(
          name: 'Google Play',
          url: 'https://play.google.com/store/apps/details?id=org.easyrpg.player',
          type: SourceType.googlePlay,
        ),
        ToolDownloadSource(
          name: 'Official Site',
          url: 'https://easyrpg.org/player/downloads/',
          type: SourceType.website,
        ),
        ToolDownloadSource(
          name: 'APKPure',
          url: 'https://apkpure.com/easyrpg-player/org.easyrpg.player',
          type: SourceType.apk,
        ),
      ],
    ),

    // ONScripter Plus
    GameTool(
      id: 'onscripter',
      name: 'ONScripter Plus',
      description: 'Player for NScripter/ONScripter visual novels',
      packageName: 'com.onscripter.plus',
      supportedEngines: ['NScripter', 'ONScripter', 'nscr'],
      downloadSources: [
        ToolDownloadSource(
          name: 'Google Play',
          url: 'https://play.google.com/store/apps/details?id=com.onscripter.plus',
          type: SourceType.googlePlay,
        ),
      ],
    ),

    // PPSSPP (for PSP games)
    GameTool(
      id: 'ppsspp',
      name: 'PPSSPP',
      description: 'PSP emulator for playing PSP games',
      packageName: 'org.ppsspp.ppsspp',
      supportedEngines: ['PSP', 'PlayStation Portable'],
      downloadSources: [
        ToolDownloadSource(
          name: 'Google Play',
          url: 'https://play.google.com/store/apps/details?id=org.ppsspp.ppsspp',
          type: SourceType.googlePlay,
        ),
        ToolDownloadSource(
          name: 'Official Site',
          url: 'https://www.ppsspp.org/downloads.html',
          type: SourceType.website,
        ),
      ],
    ),

    // Exagear (for Windows games)
    GameTool(
      id: 'exagear',
      name: 'ExaGear',
      description: 'Windows emulator for running PC games on Android',
      packageName: 'com.eltechs.ed',
      supportedEngines: ['Windows', 'PC', 'Win32', 'Wolf RPG Editor', 'Wolf RPG'],
      downloadSources: [
        ToolDownloadSource(
          name: 'APKPure',
          url: 'https://apkpure.com/exagear-windows-emulator/com.eltechs.ed',
          type: SourceType.apk,
        ),
      ],
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
