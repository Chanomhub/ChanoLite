import 'package:chanolite/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;
  SeasonalPalette _currentPalette;

  ThemeNotifier(this._themeMode) : _currentPalette = AppTheme.getSeasonalPalette(DateTime.now());

  ThemeMode get themeMode => _themeMode;
  SeasonalPalette get currentPalette => _currentPalette;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void updateSeasonalPalette() {
    final newPalette = AppTheme.getSeasonalPalette(DateTime.now());
    if (_currentPalette != newPalette) {
      _currentPalette = newPalette;
      notifyListeners();
    }
  }
}
