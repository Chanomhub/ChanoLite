import 'package:flutter/material.dart';

/// Extension methods on BuildContext for easier access to theme and colors.
extension ContextExtensions on BuildContext {
  /// Get the current ThemeData
  ThemeData get theme => Theme.of(this);

  /// Get the current ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get the current TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get the current MediaQueryData
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get the screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get the screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if the current theme is dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Show a snackbar with the given message
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
}
