import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

/// Service for checking and launching installed apps
class InstalledAppsService {
  /// Check if an app with the given package name is installed
  static Future<bool> isAppInstalled(String packageName) async {
    if (!Platform.isAndroid) return false;
    
    try {
      final isInstalled = await InstalledApps.isAppInstalled(packageName);
      return isInstalled ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Launch an app by its package name using InstalledApps.startApp
  /// Returns true if the app was launched successfully
  static Future<bool> launchApp(String packageName) async {
    if (!Platform.isAndroid) return false;
    
    try {
      // Use InstalledApps.startApp instead of android_intent_plus
      await InstalledApps.startApp(packageName);
      return true;
    } catch (e) {
      print('InstalledAppsService: Error launching app: $e');
      // Fallback to android_intent_plus
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: packageName,
          category: 'android.intent.category.LAUNCHER',
        );
        await intent.launch();
        return true;
      } catch (e2) {
        print('InstalledAppsService: Fallback also failed: $e2');
        return false;
      }
    }
  }

  /// Get information about an installed app
  /// Returns null if the app is not installed
  static Future<AppInfo?> getAppInfo(String packageName) async {
    if (!Platform.isAndroid) return null;
    
    try {
      return await InstalledApps.getAppInfo(packageName);
    } catch (e) {
      return null;
    }
  }

  /// Get the installed version of an app
  /// Returns null if the app is not installed
  static Future<String?> getInstalledVersion(String packageName) async {
    final app = await getAppInfo(packageName);
    return app?.versionName;
  }
}
