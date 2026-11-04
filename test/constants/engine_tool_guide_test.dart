import 'package:chanolite/constants/engine_tool_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EngineToolGuide.forEngine', () {
    test('matches backend engine names', () {
      // Real engine keys from GET /api/engines + engine-detect.
      expect(EngineToolGuide.forEngine('rpgm')!.title, 'RPG Maker MV / MZ');
      expect(EngineToolGuide.forEngine('pgmmv')!.title, 'RPG Maker MV / MZ');
      expect(EngineToolGuide.forEngine('RPG Maker MV')!.title,
          'RPG Maker MV / MZ');
      expect(EngineToolGuide.forEngine("Ren'Py")!.title, "Ren'Py");
      expect(EngineToolGuide.forEngine('wolfrpg')!.title, 'Wolf RPG Editor');
      expect(EngineToolGuide.forEngine('Unity')!.title, 'Unity');
      expect(EngineToolGuide.forEngine('Godot')!.title, 'Godot');
      expect(EngineToolGuide.forEngine('tyranobuilder')!.title,
          'TyranoBuilder / TyranoScript');
      expect(EngineToolGuide.forEngine('html5')!.title, 'HTML / Web');
      expect(EngineToolGuide.forEngine('unreal')!.title, 'Unreal Engine');
      expect(EngineToolGuide.forEngine('windows')!.title, 'Windows (exe)');
    });

    test('case-insensitive', () {
      expect(EngineToolGuide.forEngine('RPGM')!.title, 'RPG Maker MV / MZ');
      expect(EngineToolGuide.forEngine('UNITY')!.title, 'Unity');
    });

    test('unknown or blank engine → no guide (no nagging)', () {
      expect(EngineToolGuide.forEngine(null), isNull);
      expect(EngineToolGuide.forEngine(''), isNull);
      expect(EngineToolGuide.forEngine('SomeCustomEngine'), isNull);
    });

    test('every entry points at a tool that exists in the catalog', () {
      for (final guide in EngineToolGuide.guides) {
        for (final entry in guide.entries) {
          expect(
            EngineToolGuide.toolById(entry.toolId),
            isNotNull,
            reason:
                '${guide.engine}: entry ${entry.toolId} missing from catalog',
          );
        }
      }
    });

    test('every catalog main tool is recommended somewhere', () {
      final recommended =
          EngineToolGuide.guides.expand((g) => g.entries.map((e) => e.toolId));
      expect(
        recommended.toSet(),
        containsAll(['joiplay', 'mtool', 'gamehub']),
      );
    });
  });
}
