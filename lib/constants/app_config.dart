/// Application configuration constants.
/// Centralized config for easy modification.
class AppConfig {
  AppConfig._();

  /// Base URL for the CDN. 
  /// Images that start with '/' will be prefixed with this URL.
  static const String cdnBaseUrl = 'https://cdn.chanomhub.online';

  /// API base URL
  static const String apiBaseUrl = 'https://api.chanomhub.online';
}
