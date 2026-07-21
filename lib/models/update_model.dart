class AppUpdateInfo {
  const AppUpdateInfo({
    required this.title,
    required this.versionLabel,
    required this.releaseUrl,
    this.version,
    this.releaseNotes,
    this.releaseNotesHtml,
    this.publishedAt,
  });

  final String title;
  final String versionLabel;
  final String releaseUrl;
  final AppVersion? version;
  final String? releaseNotes;
  final String? releaseNotesHtml;
  final DateTime? publishedAt;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      title: json['name']?.toString().trim() ?? json['tag_name']?.toString().trim() ?? '',
      versionLabel: json['tag_name']?.toString().replaceFirst('v', '') ?? '',
      releaseNotes: json['body']?.toString(),
      releaseNotesHtml: json['body_html']?.toString(),
      releaseUrl: json['html_url']?.toString() ?? '',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'])
          : null,
    );
  }
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
