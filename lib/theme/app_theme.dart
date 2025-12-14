import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

enum SeasonalPalette {
  standard,
  festive,
  spooky,
  summer,
  christmas,
}

class AppTheme {
  const AppTheme._();

  static ThemeData light({SeasonalPalette palette = SeasonalPalette.standard}) {
    return FlexThemeData.light(
      scheme: _schemeFor(palette),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 8,
      subThemesData: _subThemes,
      keyColors: _keyColors,
      tones: FlexTones.material(Brightness.light).copyWith(
        primaryTone: 40,
        secondaryTone: 50,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    );
  }

  static ThemeData dark({SeasonalPalette palette = SeasonalPalette.standard}) {
    return FlexThemeData.dark(
      scheme: _schemeFor(palette),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 14,
      subThemesData: _subThemes,
      keyColors: _keyColors,
      tones: FlexTones.material(Brightness.dark).copyWith(
        primaryTone: 70,
        secondaryTone: 80,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    );
  }

  static const _subThemes = FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    useTextTheme: true,
    blendOnLevel: 12,
    blendOnColors: false,
    defaultRadius: 14,
    elevatedButtonRadius: 18,
    dialogBackgroundSchemeColor: SchemeColor.surface,
    bottomNavigationBarBackgroundSchemeColor: SchemeColor.surfaceContainer,
  );

  static const _keyColors = FlexKeyColors(
    useSecondary: true,
    useTertiary: true,
    keepPrimary: false,
  );

  static FlexScheme _schemeFor(SeasonalPalette palette) {
    switch (palette) {
      case SeasonalPalette.festive:
        return FlexScheme.redWine;
      case SeasonalPalette.spooky:
        return FlexScheme.outerSpace;
      case SeasonalPalette.summer:
        return FlexScheme.mango;
      case SeasonalPalette.christmas:
        return FlexScheme.mandyRed;
      case SeasonalPalette.standard:
        return FlexScheme.deepPurple;
    }
  }

  static SeasonalPalette getSeasonalPalette(DateTime date) {
    final month = date.month;
    final day = date.day;

    // Christmas: Dec 20 - Dec 31
    if (month == 12 && day >= 20 && day <= 31) {
      return SeasonalPalette.christmas;
    }

    // Halloween: Oct 25 - Oct 31
    if (month == 10 && day >= 25 && day <= 31) {
      return SeasonalPalette.spooky;
    }

    // Summer: Jun 1 - Aug 31 (Example)
    if (month >= 6 && month <= 8) {
      return SeasonalPalette.summer;
    }

    return SeasonalPalette.standard;
  }
}
