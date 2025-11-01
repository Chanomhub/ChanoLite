import 'dart:async';
import 'package:app_links/app_links.dart';

import 'package:chanolite/game_library_screen.dart';
import 'package:chanolite/home_screen.dart';
import 'package:chanolite/managers/ad_manager.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:chanolite/search_screen.dart';
import 'package:chanolite/settings_screen.dart';
import 'package:chanolite/theme/app_theme.dart';
import 'package:chanolite/widgets/global_download_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  final adManager = AdManager(
    configProvider: () async => const AdManagerConfig(
      sdkKey: 'YOUR_APPLOVIN_SDK_KEY',
      bannerAdUnitId: 'YOUR_BANNER_AD_UNIT_ID',
    ),
  );
  unawaited(adManager.initialize());
  runApp(MyApp(adManager: adManager));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.adManager});

  final AdManager adManager;

  @override
  Widget build(BuildContext context) {
    const palette = SeasonalPalette.spooky;
    final authManager = AuthManager()
      ..load();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DownloadManager()),
        ChangeNotifierProvider.value(value: authManager),
        Provider<AdManager>.value(value: adManager),
      ],
      child: MaterialApp(
        title: 'ChanoLite',
        theme: AppTheme.light(palette: palette),
        darkTheme: AppTheme.dark(palette: palette),
        themeMode: ThemeMode.dark,
        home: const AuthGate(),
        routes: {
          '/login': (_) => const LoginScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      print('Initial deep link: $initialLink');
      // TODO: Add navigation logic for the initial link.
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('Latest deep link: $uri');
      // TODO: Add navigation logic for incoming links.
    });
  }

  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const SearchScreen(),
    const GameLibraryScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
          const GlobalDownloadIndicator(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthManager>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        return child!;
      },
      child: const MainScreen(),
    );
  }
}
