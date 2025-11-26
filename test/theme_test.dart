import 'package:flutter_test/flutter_test.dart';
import 'package:chanolite/theme/app_theme.dart';

void main() {
  group('AppTheme.getSeasonalPalette', () {
    test('returns christmas palette for Dec 25', () {
      final date = DateTime(2023, 12, 25);
      expect(AppTheme.getSeasonalPalette(date), SeasonalPalette.christmas);
    });

    test('returns christmas palette for Dec 20', () {
      final date = DateTime(2023, 12, 20);
      expect(AppTheme.getSeasonalPalette(date), SeasonalPalette.christmas);
    });

    test('returns christmas palette for Dec 31', () {
      final date = DateTime(2023, 12, 31);
      expect(AppTheme.getSeasonalPalette(date), SeasonalPalette.christmas);
    });

    test('returns spooky palette for Oct 31', () {
      final date = DateTime(2023, 10, 31);
      expect(AppTheme.getSeasonalPalette(date), SeasonalPalette.spooky);
    });

    test('returns summer palette for Jul 15', () {
      final date = DateTime(2023, 7, 15);
      expect(AppTheme.getSeasonalPalette(date), SeasonalPalette.summer);
    });

    test('returns standard palette for Jan 1', () {
      final date = DateTime(2023, 1, 1);
      expect(AppTheme.getSeasonalPalette(date), SeasonalPalette.standard);
    });
  });
}
