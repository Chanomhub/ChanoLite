import 'package:chanolite/models/update_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Update Model & AppVersion Tests', () {
    test('AppVersion.tryParse handles various version formats', () {
      final v1 = AppVersion.tryParse('1.2.3');
      expect(v1, isNotNull);
      expect(v1.toString(), '1.2.3');

      final v2 = AppVersion.tryParse('v2.1.8+1');
      expect(v2, isNotNull);
      expect(v2.toString(), '2.1.8');

      final v3 = AppVersion.tryParse('   v3.0.0   ');
      expect(v3, isNotNull);
      expect(v3.toString(), '3.0.0');

      expect(AppVersion.tryParse(null), isNull);
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('invalid'), isNull);
    });

    test('AppVersion compareTo evaluates precedence correctly', () {
      final v100 = AppVersion.tryParse('1.0.0')!;
      final v101 = AppVersion.tryParse('1.0.1')!;
      final v110 = AppVersion.tryParse('1.1.0')!;
      final v200 = AppVersion.tryParse('2.0.0')!;

      expect(v100.compareTo(v101), lessThan(0));
      expect(v101.compareTo(v100), greaterThan(0));
      expect(v100.compareTo(v100), 0);
      expect(v200.compareTo(v110), greaterThan(0));
      expect(v110.compareTo(v200), lessThan(0));

      final vShort = AppVersion.tryParse('1.2')!;
      final vLong = AppVersion.tryParse('1.2.0')!;
      expect(vShort.compareTo(vLong), 0);
    });

    test('AppVersion equality and hashCode', () {
      final v1 = AppVersion.tryParse('2.1.0');
      final v2 = AppVersion.tryParse('2.1.0');
      final v3 = AppVersion.tryParse('2.1.1');

      expect(v1, equals(v2));
      expect(v1.hashCode, equals(v2.hashCode));
      expect(v1, isNot(equals(v3)));
    });

    test('AppUpdateInfo fromJson parses fields', () {
      final json = {
        'name': 'ChanoLite v2.2.0',
        'tag_name': 'v2.2.0',
        'body': 'Bug fixes and performance improvements',
        'body_html': '<p>Bug fixes and performance improvements</p>',
        'html_url': 'https://github.com/chanomhub/ChanoLite/releases/tag/v2.2.0',
        'published_at': '2026-08-01T10:00:00Z',
      };

      final info = AppUpdateInfo.fromJson(json);
      expect(info.title, 'ChanoLite v2.2.0');
      expect(info.versionLabel, '2.2.0');
      expect(info.releaseNotes, 'Bug fixes and performance improvements');
      expect(info.releaseUrl, 'https://github.com/chanomhub/ChanoLite/releases/tag/v2.2.0');
      expect(info.publishedAt, isNotNull);
    });
  });
}
