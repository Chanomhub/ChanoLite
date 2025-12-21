/// Application configuration constants.
/// Centralized config for easy modification.
class AppConfig {
  AppConfig._();

  /// Base URL for the CDN. 
  /// Images that start with '/' will be prefixed with this URL.
  static const String cdnBaseUrl = 'https://cdn.chanomhub.com';
  
  /// Cloudflare image resizing/formatting path
  static const String cdnOptimizationPath = '/cdn-cgi/image/format=auto';

  /// API base URL
  static const String apiBaseUrl = 'https://api.chanomhub.com';
}
