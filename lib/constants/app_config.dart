/// Application configuration constants.
/// Centralized config for easy modification.
class AppConfig {
  AppConfig._();

  /// Base URL for the CDN. 
  /// Images that start with '/' will be prefixed with this URL.
  static const String cdnBaseUrl = 'https://cdn.chanomhub.com';
  
  /// Imgproxy base URL
  static const String imgproxyBaseUrl = 'https://imgproxy.chanomhub.com';

  /// Imgproxy options (e.g., resizing, formatting)
  /// Using 'insecure/plain' for now as per plan.
  static const String imgproxyOption = '/insecure/plain';

  /// API base URL
  static const String apiBaseUrl = 'https://api.chanomhub.com';
}
