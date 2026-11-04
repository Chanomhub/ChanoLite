import 'package:flutter/services.dart';

/// Bundled assets used by the mod installer.
class ModAssets {
  ModAssets._();

  static const String thaiFontAsset =
      'assets/mods/NotoSansThai-Regular.ttf';
  static List<int>? _cached;

  /// Noto Sans Thai bundled with the app; null when the asset is missing
  /// (font injection is skipped — JoiPlay ships its own fallback fonts).
  static Future<List<int>?> loadThaiFont() async {
    if (_cached != null) return _cached;
    try {
      final data =
          await rootBundle.load('packages/chanolite/$thaiFontAsset');
      _cached = data.buffer.asUint8List();
      return _cached;
    } catch (_) {
      return null;
    }
  }
}
