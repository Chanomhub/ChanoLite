import 'dart:ui';

extension LocaleExtension on Locale {
  /// Returns the language code expected by the backend.
  /// Maps 'ja' to 'jp' for compatibility.
  String get toBackendCode {
    if (languageCode == 'ja') {
      return 'jp';
    }
    return languageCode;
  }
}
