import 'package:chanolite/l10n/generated/app_localizations.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/screens/settings_screen.dart';
import 'package:chanolite/theme/locale_notifier.dart';
import 'package:chanolite/theme/theme_notifier.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide User, Profile, Download, Article, Author;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SettingsScreen renders account section, settings options', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'download_path': '/storage/emulated/0/Download'});
    PackageInfo.setMockInitialValues(
      appName: 'ChanoLite',
      packageName: 'com.chanomhub.chanolite',
      version: '2.1.8',
      buildNumber: '1',
      buildSignature: '',
    );

    final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
    final authManager = AuthManager(sdk: sdk);
    final localeNotifier = LocaleNotifier(const Locale('en'));
    final themeNotifier = ThemeNotifier(ThemeMode.dark);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthManager>.value(value: authManager),
          ChangeNotifierProvider<LocaleNotifier>.value(value: localeNotifier),
          ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('th'),
          ],
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(find.text('Not signed in'), findsOneWidget);
    expect(find.text('Tap to sign in'), findsOneWidget);
  });
}
