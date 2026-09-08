import 'package:chanolite/utils/url_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrlHelper & InAppBrowserHelper Tests', () {
    test('resolveDownloadUrl returns full URL unchanged', () {
      expect(
        resolveDownloadUrl('https://example.com/file.zip'),
        'https://example.com/file.zip',
      );
      expect(
        resolveDownloadUrl('http://example.com/file.apk'),
        'http://example.com/file.apk',
      );
    });

    test('resolveDownloadUrl prepends CDN domain for relative paths', () {
      expect(
        resolveDownloadUrl('public/game.zip'),
        'https://storage.chanomhub.com/public/game.zip',
      );
      expect(
        resolveDownloadUrl('/public/game.zip'),
        'https://storage.chanomhub.com/public/game.zip',
      );
    });

    test('extractFilename from Content-Disposition header', () {
      expect(
        InAppBrowserHelper.extractFilename('attachment; filename="game_release.zip"'),
        'game_release.zip',
      );
      expect(
        InAppBrowserHelper.extractFilename("attachment; filename*=UTF-8''my%20game%20v1.zip"),
        'my game v1.zip',
      );
      expect(
        InAppBrowserHelper.extractFilename(null),
        isNull,
      );
    });

    test('getFilenameFromUrl extracts decoded last path segment', () {
      final uri1 = Uri.parse('https://example.com/downloads/my%20game.apk');
      expect(InAppBrowserHelper.getFilenameFromUrl(uri1), 'my game.apk');

      final uri2 = Uri.parse('https://example.com/');
      expect(InAppBrowserHelper.getFilenameFromUrl(uri2), isNull);
    });
  });
}
