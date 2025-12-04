import 'package:chanolite/theme/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocaleNotifier', () {
    test('initial locale is set correctly', () {
      final notifier = LocaleNotifier(const Locale('en'));
      expect(notifier.locale, const Locale('en'));
    });

    test('setLocale updates locale and notifies listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = LocaleNotifier(const Locale('en'));
      bool notified = false;
      notifier.addListener(() {
        notified = true;
      });

      await notifier.setLocale(const Locale('th'));

      expect(notifier.locale, const Locale('th'));
      expect(notified, true);
    });

    test('loadSavedLocale returns default if no preference', () async {
      SharedPreferences.setMockInitialValues({});
      final locale = await LocaleNotifier.loadSavedLocale();
      expect(locale, const Locale('en'));
    });

    test('loadSavedLocale returns saved locale', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
      final locale = await LocaleNotifier.loadSavedLocale();
      expect(locale, const Locale('ja'));
    });
  });
}
