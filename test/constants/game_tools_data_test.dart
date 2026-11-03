import 'package:chanolite/constants/game_tools_data.dart';
import 'package:chanolite/models/game_tool.dart';
import 'package:flutter_test/flutter_test.dart';

/// Data invariants for the tools catalog — the Tools screen and
/// GameToolsService both index into this static data, so a broken entry
/// (dead parent reference, empty sources, wrong type mapping) breaks users
/// at runtime instead of compile time.
void main() {
  final all = GameToolsData.tools;

  group('GameToolsData catalog invariants', () {
    test('catalog is not empty and ids are unique', () {
      expect(all, isNotEmpty);
      final ids = all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate tool id');
    });

    test('every tool has at least one download source with a URL', () {
      for (final tool in all) {
        expect(tool.downloadSources, isNotEmpty,
            reason: '${tool.id} has no download sources');
        for (final source in tool.downloadSources) {
          expect(source.url, startsWith('https://'),
              reason: '${tool.id} source ${source.name} is not https');
        }
      }
    });

    test('plugin parentToolId references an existing main tool', () {
      for (final tool in all.where((t) => t.isPlugin)) {
        expect(tool.parentToolId, isNotNull,
            reason: '${tool.id} is a plugin without parentToolId');
        final parent = GameToolsData.getToolById(tool.parentToolId!);
        expect(parent, isNotNull,
            reason: '${tool.id} points at missing parent ${tool.parentToolId}');
        expect(parent!.isPlugin, isFalse,
            reason: '${tool.id} parent ${parent.id} is itself a plugin');
      }
    });

    test('every tool has a non-empty Android packageName', () {
      for (final tool in all) {
        expect(tool.packageName, isNotEmpty,
            reason: '${tool.id} has no packageName');
      }
    });

    test('every tool supports at least one engine', () {
      for (final tool in all) {
        expect(tool.supportedEngines, isNotEmpty,
            reason: '${tool.id} supports no engines');
      }
    });
  });

  group('GameToolsData lookups', () {
    test('getToolById finds proton-ce and returns null for unknown id', () {
      final proton = GameToolsData.getToolById('proton-ce');
      expect(proton, isNotNull);
      expect(proton!.downloadSources.first.url, endsWith('.tar.gz'),
          reason: 'first proton source must be the direct archive download');

      expect(GameToolsData.getToolById('no-such-tool'), isNull);
    });

    test('getPluginsFor returns only plugins of that parent', () {
      final joiplayPlugins = GameToolsData.getPluginsFor('joiplay');

      expect(joiplayPlugins, isNotEmpty);
      expect(
        joiplayPlugins.every((p) => p.parentToolId == 'joiplay' && p.isPlugin),
        isTrue,
      );
    });

    test('mainTools excludes plugins', () {
      expect(GameToolsData.mainTools.any((t) => t.isPlugin), isFalse);
      expect(GameToolsData.mainTools.length,
          all.where((t) => !t.isPlugin).length);
    });

    test('getToolsForEngine matches and returns empty on blank engine', () {
      expect(GameToolsData.getToolsForEngine(''), isEmpty);
      expect(GameToolsData.getToolsForEngine('rpg maker'),
          everyElement(predicate<GameTool>(
            (t) => t.supportedEngines.any(
              (e) =>
                  e.toLowerCase().contains('rpg maker') ||
                  'rpg maker'.contains(e.toLowerCase()),
            ),
          )));
    });
  });
}
