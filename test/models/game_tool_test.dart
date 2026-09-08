import 'package:chanolite/models/game_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameTool & ToolDownloadSource Model Tests', () {
    test('ToolDownloadSource iconName mapping', () {
      const gPlay = ToolDownloadSource(name: 'Google Play', url: 'https://play.google.com', type: SourceType.googlePlay);
      const apk = ToolDownloadSource(name: 'APK', url: 'https://example.com/tool.apk', type: SourceType.apk);
      const github = ToolDownloadSource(name: 'GitHub', url: 'https://github.com/repo', type: SourceType.github);
      const web = ToolDownloadSource(name: 'Web', url: 'https://tool.com', type: SourceType.website);

      expect(gPlay.iconName, 'play_store');
      expect(apk.iconName, 'android');
      expect(github.iconName, 'code');
      expect(web.iconName, 'language');
    });

    test('GameTool.supportsEngine checks engine matching correctly', () {
      const tool = GameTool(
        id: 'joiplay',
        name: 'JoiPlay',
        description: 'Game interpreter',
        packageName: 'cyou.joiplay.joiplay',
        supportedEngines: ['RPG Maker XP', 'RPG Maker VX', 'RPG Maker MV', 'Ren\'Py', 'TyranoBuilder'],
        downloadSources: [
          ToolDownloadSource(name: 'Google Play', url: 'https://play.google.com', type: SourceType.googlePlay)
        ],
      );

      expect(tool.supportsEngine('RPG Maker MV'), isTrue);
      expect(tool.supportsEngine('rpg maker mv'), isTrue); // case insensitive
      expect(tool.supportsEngine('Ren\'Py'), isTrue);
      expect(tool.supportsEngine('Unity'), isFalse);
      expect(tool.supportsEngine('Unreal Engine'), isFalse);
    });
  });
}
