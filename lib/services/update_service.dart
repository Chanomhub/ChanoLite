import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  UpdateService({
    http.Client? httpClient,
    this.owner = 'chanomhub',
    this.repository = 'ChanoLite',
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String owner;
  final String repository;

  Future<AppUpdateInfo?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = AppVersion.tryParse(
      '${packageInfo.version}+${packageInfo.buildNumber}',
    );

    final latestRelease = await _fetchLatestRelease();
    if (latestRelease == null) {
      return null;
    }

    final latestVersion = latestRelease.version;
    if (currentVersion != null && latestVersion != null) {
      if (latestVersion.compareTo(currentVersion) <= 0) {
        return null;
      }
    } else if (currentVersion != null && latestVersion == null) {
      return null;
    }

    return latestRelease;
  }

  Future<AppUpdateInfo?> _fetchLatestRelease() async {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repository/releases/latest',
    );

    final response = await _httpClient.get(
      uri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch release info: ${response.statusCode}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = (payload['tag_name'] as String?)?.trim();
    final releaseName = (payload['name'] as String?)?.trim();
    final versionSource = (tagName?.isNotEmpty ?? false)
        ? tagName!
        : (releaseName?.isNotEmpty ?? false)
            ? releaseName!
            : 'latest';

    final version = AppVersion.tryParse(versionSource);
    final htmlUrl = (payload['html_url'] as String?)?.trim();
    final body = (payload['body'] as String?)?.trim();
    final publishedAtRaw = payload['published_at'] as String?;
    final publishedAt =
        publishedAtRaw != null ? DateTime.tryParse(publishedAtRaw) : null;

    return AppUpdateInfo(
      title: releaseName?.isNotEmpty == true ? releaseName! : versionSource,
      versionLabel: versionSource,
      version: version,
      releaseUrl: htmlUrl ?? '',
      releaseNotes: body,
      publishedAt: publishedAt,
    );
  }
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.title,
    required this.versionLabel,
    required this.releaseUrl,
    this.version,
    this.releaseNotes,
    this.publishedAt,
  });

  final String title;
  final String versionLabel;
  final String releaseUrl;
  final AppVersion? version;
  final String? releaseNotes;
  final DateTime? publishedAt;
}

class AppVersion implements Comparable<AppVersion> {
  AppVersion._(this._segments);

  final List<int> _segments;

  static AppVersion? tryParse(String? value) {
    if (value == null) {
      return null;
    }

    var sanitized = value.trim();
    if (sanitized.isEmpty) {
      return null;
    }

    sanitized = sanitized.replaceFirst(RegExp(r'^[^0-9]*'), '');
    if (sanitized.isEmpty) {
      return null;
    }

    final base = sanitized.split('+').first;
    final parts = base.split('.');
    final segments = <int>[];

    for (final part in parts) {
      if (part.isEmpty) {
        segments.add(0);
        continue;
      }

      final numeric = int.tryParse(part);
      if (numeric == null) {
        return null;
      }
      segments.add(numeric);
    }

    if (segments.isEmpty) {
      return null;
    }

    return AppVersion._(segments);
  }

  @override
  int compareTo(AppVersion other) {
    final maxLength =
        _segments.length > other._segments.length ? _segments.length : other._segments.length;
    for (var index = 0; index < maxLength; index++) {
      final left = index < _segments.length ? _segments[index] : 0;
      final right = index < other._segments.length ? other._segments[index] : 0;
      if (left != right) {
        return left.compareTo(right);
      }
    }
    return 0;
  }

  @override
  String toString() => _segments.join('.');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! AppVersion) {
      return false;
    }
    if (_segments.length != other._segments.length) {
      return false;
    }
    for (var index = 0; index < _segments.length; index++) {
      if (_segments[index] != other._segments[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_segments);
}
