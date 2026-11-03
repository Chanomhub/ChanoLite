import 'dart:convert';

import 'package:chanolite/services/update_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus_platform_interface/package_info_data.dart';
import 'package:package_info_plus_platform_interface/package_info_platform_interface.dart';

class _FakePackageInfo extends PackageInfoPlatform {
  @override
  Future<PackageInfoData> getAll({String? baseUrl}) async {
    return PackageInfoData(
      appName: 'ChanoLite',
      packageName: 'com.chanomhub.chanolite',
      version: '2.1.8',
      buildNumber: '1',
      buildSignature: '',
    );
  }
}

http.Response _githubRelease({
  String tagName = 'v2.2.0',
  String? name,
  String? body,
}) {
  return http.Response(
    json.encode({
      'tag_name': tagName,
      'name': name ?? 'ChanoLite $tagName',
      'html_url': 'https://github.com/chanomhub/chanolite/releases/tag/$tagName',
      'body': body,
      'published_at': '2026-11-01T00:00:00Z',
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  // package_info_plus reads the method channel by default in tests — stub it
  // so UpdateService sees a fixed current version of 2.1.8+1.
  TestWidgetsFlutterBinding.ensureInitialized();
  PackageInfoPlatform.instance = _FakePackageInfo();

  group('UpdateService.checkForUpdate', () {
    test('returns release info when GitHub version is newer', () async {
      final service = UpdateService(
        httpClient: MockClient((req) async {
          expect(
            req.url.toString(),
            'https://api.github.com/repos/chanomhub/chanolite/releases/latest',
          );
          expect(req.headers['Accept'], contains('vnd.github'));
          return _githubRelease(tagName: 'v2.2.0');
        }),
      );

      final update = await service.checkForUpdate();

      expect(update, isNotNull);
      expect(update!.version.toString(), '2.2.0');
      expect(update.releaseUrl, contains('releases/tag/v2.2.0'));
      expect(update.publishedAt, isNotNull);
    });

    test('returns null when installed version is up to date', () async {
      final service = UpdateService(
        httpClient: MockClient((req) async => _githubRelease(tagName: 'v2.1.8')),
      );

      expect(await service.checkForUpdate(), isNull);
    });

    test('returns null when installed version is newer than latest tag',
        () async {
      final service = UpdateService(
        httpClient: MockClient((req) async => _githubRelease(tagName: 'v2.0.9')),
      );

      expect(await service.checkForUpdate(), isNull);
    });

    test('returns null on 404 (no releases published yet)', () async {
      final service = UpdateService(
        httpClient: MockClient((req) async => http.Response('', 404)),
      );

      expect(await service.checkForUpdate(), isNull);
    });

    test('throws on other HTTP errors', () async {
      final service = UpdateService(
        httpClient: MockClient((req) async => http.Response('rate limited', 403)),
      );

      await expectLater(service.checkForUpdate(), throwsException);
    });

    test('parses tag without v prefix and mixed formats', () async {
      final service = UpdateService(
        httpClient: MockClient((req) async => _githubRelease(tagName: '3.0')),
      );

      final update = await service.checkForUpdate();

      expect(update!.version.toString(), '3.0');
      expect(update.versionLabel, '3.0');
    });
  });

  group('UpdateService.release notes rendering', () {
    test('renders markdown notes to HTML', () async {
      final service = UpdateService(
        httpClient: MockClient(
          (req) async => _githubRelease(body: '## Fixed\n- bug A'),
        ),
      );

      final update = await service.checkForUpdate();

      // gitHubWeb extensionSet adds anchor ids to headings
      expect(update!.releaseNotesHtml, contains('<h2'));
      expect(update.releaseNotesHtml, contains('bug A'));
    });

    test('passes pre-rendered HTML through untouched', () async {
      final service = UpdateService(
        httpClient: MockClient(
          (req) async => _githubRelease(body: '<p>already html</p>'),
        ),
      );

      final update = await service.checkForUpdate();

      expect(update!.releaseNotesHtml, '<p>already html</p>');
    });
  });

  group('UpdateService.getAllReleases', () {
    test('maps the release list', () async {
      final service = UpdateService(
        httpClient: MockClient((req) async {
          expect(req.url.toString(),
              'https://api.github.com/repos/chanomhub/chanolite/releases?per_page=30');
          return http.Response(
            json.encode([
              {'tag_name': 'v2.2.0', 'name': 'Two Two'},
              {'tag_name': 'v2.1.8', 'name': 'Current'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final releases = await service.getAllReleases();

      expect(releases.length, 2);
      expect(releases.first.versionLabel, '2.2.0');
      expect(releases.first.title, 'Two Two');
    });

    test('returns an empty list on non-200', () async {
      final service = UpdateService(
        httpClient: MockClient((req) async => http.Response('', 500)),
      );

      expect(await service.getAllReleases(), isEmpty);
    });
  });
}
