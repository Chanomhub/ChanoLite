import 'package:chanolite/constants/game_tools_data.dart';
import 'package:chanolite/models/game_tool.dart';

/// Which of our supported tools can run a given engine, and what each one
/// needs (extra plugin, special launch). Built from the tool APKs we verified:
/// JoiPlay runtimes + plugins, MTool loader hooks, GameHub's Windows layer.
class EngineToolGuide {
  const EngineToolGuide({
    required this.engine,
    required this.title,
    required this.entries,
  });

  /// Matches the article's `engine` value (lowercased contains-match).
  final String engine;
  final String title;
  final List<EngineToolEntry> entries;

  static const List<EngineToolGuide> guides = [
    EngineToolGuide(
      engine: 'rpgm',
      title: 'RPG Maker MV / MZ',
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Built-in — no plugin needed. Add the game with index.html.',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'mzHook — adds real-time translation.',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton — use for games that fail on JoiPlay.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'pgmmv',
      title: 'RPG Maker MV / MZ',
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Built-in — no plugin needed. Add the game with index.html.',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'mzHook — adds real-time translation.',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'rpg maker mv',
      title: 'RPG Maker MV / MZ',
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Built-in — no plugin needed. Add the game with index.html.',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'mzHook — adds real-time translation.',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'rpg maker mz',
      title: 'RPG Maker MV / MZ',
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Built-in — no plugin needed. Add the game with index.html.',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'mzHook — adds real-time translation.',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'rpg maker xp',
      title: 'RPG Maker XP',
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Needs the JoiPlay RPG Maker plugin (~70% compatibility).',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'RGSSHook — often runs games JoiPlay cannot.',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'rpg maker vx',
      title: 'RPG Maker VX / VX Ace',
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Needs the JoiPlay RPG Maker plugin (~70% compatibility).',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'RGSSHook (or the MKXP-Z plugin).',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'rpg maker 2000',
      title: 'RPG Maker 2000 / 2003',
      entries: [
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'EasyRPG plugin.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'renpy',
      title: "Ren'Py",
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Needs the JoiPlay Ren\'Py plugin.',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'Ren\'Py plugin — adds real-time translation.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'kirikiri',
      title: 'Kirikiri / KAG',
      entries: [
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'krkr2/krkrz hooks.',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'godot',
      title: 'Godot',
      entries: [
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'GodotHook (3.x / 4.x).',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'unity',
      title: 'Unity',
      entries: [
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'MonoJunkie hook (Mono builds only).',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'wolfrpg',
      title: 'Wolf RPG Editor',
      entries: [
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'wolfHook.',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'srpg',
      title: 'SRPG Studio',
      entries: [
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'SRPGHook.',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'bakin',
      title: 'RPG Developer Bakin',
      entries: [
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'Bakin launcher + PythonHook.',
        ),
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'windows',
      title: 'Windows (exe)',
      entries: [
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Any game that runs as an .exe — import the whole folder in GameHub.',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'Winlator plugin — plus translation hooks.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'html5',
      title: 'HTML / Web',
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Built-in HTML runtime.',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'Runs HTML games with translation.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'tyranobuilder',
      title: 'TyranoBuilder / TyranoScript',
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Built-in Tyrano runtime (JoiPlay TyranoBuilder plugin).',
        ),
        EngineToolEntry(
          toolId: 'mtool',
          detail: 'Runs Tyrano games with translation.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'construct',
      title: 'Construct',
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Built-in Construct runtime.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'twine',
      title: 'Twine',
      entries: [
        EngineToolEntry(
          toolId: 'joiplay',
          detail: 'Built-in Twine runtime.',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'unreal',
      title: 'Unreal Engine',
      entries: [
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs the Windows build via Proton (needs a strong device).',
        ),
      ],
    ),
    EngineToolGuide(
      engine: 'flash',
      title: 'Flash / SWF',
      entries: [
        EngineToolEntry(
          toolId: 'gamehub',
          detail: 'Runs via the Windows build (Flash projector) through Proton.',
        ),
      ],
    ),
  ];

  /// Best-effort guide for an engine string from the backend.
  static EngineToolGuide? forEngine(String? engine) {
    if (engine == null || engine.trim().isEmpty) return null;
    final e = _normalize(engine);
    for (final g in guides) {
      final k = _normalize(g.engine);
      if (e.contains(k) || k.contains(e)) return g;
    }
    return null;
  }

  /// Lowercase, drop apostrophes so "Ren'Py" matches the 'renpy' key.
  static String _normalize(String s) =>
      s.toLowerCase().replaceAll("'", '').trim();

  static GameTool? toolById(String id) => GameToolsData.getToolById(id);
}

class EngineToolEntry {
  const EngineToolEntry({required this.toolId, required this.detail});

  final String toolId;
  final String detail;
}
