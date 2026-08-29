import 'package:chanolite/theme/app_theme.dart';
import 'package:chanolite/theme/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeNotifier Tests', () {
    test('Initial themeMode is configured properly', () {
      final notifier = ThemeNotifier(ThemeMode.dark);
      expect(notifier.themeMode, ThemeMode.dark);
      expect(notifier.currentPalette, isA<SeasonalPalette>());
    });

    test('setThemeMode updates themeMode and notifies listeners', () {
      final notifier = ThemeNotifier(ThemeMode.system);
      bool notified = false;
      notifier.addListener(() => notified = true);

      notifier.setThemeMode(ThemeMode.light);
      expect(notifier.themeMode, ThemeMode.light);
      expect(notified, isTrue);
    });

    test('updateSeasonalPalette executes without errors', () {
      final notifier = ThemeNotifier(ThemeMode.dark);
      notifier.updateSeasonalPalette();
      expect(notifier.currentPalette, isA<SeasonalPalette>());
    });
  });
}
