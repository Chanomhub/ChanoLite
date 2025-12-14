import 'package:chanolite/constants/app_config.dart';

/// Helper utilities for working with image URLs.
class ImageUrlHelper {
  ImageUrlHelper._();

  /// Resolves an image URL to a full URL.
  /// 
  /// - If [url] is null or empty, returns null.
  /// - If [url] starts with '/', prepends the CDN base URL.
  /// - If [url] is already a full URL (http/https), returns as-is.
  /// 
  /// Examples:
  /// ```dart
  /// resolve('/abc123.jpg') 
  ///   => 'https://cdn.chanomhub.online/abc123.jpg'
  /// 
  /// resolve('https://example.com/img.jpg') 
  ///   => 'https://example.com/img.jpg'
  /// 
  /// resolve(null) => null
  /// ```
  static String? resolve(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    // Already a full URL
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Relative URL starting with /
    if (url.startsWith('/')) {
      return '${AppConfig.cdnBaseUrl}$url';
    }

    // Relative URL without leading slash - add it
    return '${AppConfig.cdnBaseUrl}/$url';
  }

  /// Resolves multiple image URLs.
  static List<String> resolveAll(List<String?> urls) {
    return urls
        .map(resolve)
        .where((url) => url != null)
        .cast<String>()
        .toList();
  }

  /// Gets the first valid image URL from a list of candidates.
  static String? getFirstValid(List<String?> candidates) {
    for (final url in candidates) {
      final resolved = resolve(url);
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    }
    return null;
  }
}
