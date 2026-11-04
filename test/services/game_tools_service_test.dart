import 'package:chanolite/constants/game_tools_data.dart';
import 'package:chanolite/services/game_tools_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The catalog was trimmed to JoiPlay / MTool / Kirikiroid2 / MinHub.
/// These tests pin the trim so removed tools don't creep back in and the
/// launcher switch keeps a case for every remaining main tool.
void main() {
  group('trimmed catalog', () {
    test('keeps exactly the four supported tool families', () {
      final mainIds =
          GameToolsData.mainTools.map((t) => t.id).toSet();
      expect(mainIds, {'joiplay', 'kirikiroid2', 'minhub', 'mtool'});
    });

    test('removed tools stay removed', () {
      for (final removed in [
        'exagear',
        'winlator',
        'neko-rpgxp',
        'maldives',
        'proton-ce',
        'easyrpg',
        'onscripter',
        'ppsspp',
      ]) {
        expect(GameToolsService.getToolById(removed), isNull,
            reason: '$removed should not be in the catalog');
      }
    });

    test('plugin parent references still resolve', () {
      for (final plugin
          in GameToolsService.getAllTools().where((t) => t.isPlugin)) {
        expect(plugin.parentToolId, isNotNull);
        expect(GameToolsService.getToolById(plugin.parentToolId!), isNotNull,
            reason: '${plugin.id} parent missing');
      }
    });
  });
}
