import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_downloader/flutter_downloader.dart';


import 'package:chanolite/screens/game_library_screen.dart';
import 'package:chanolite/screens/home_screen.dart';

import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:chanolite/screens/search_screen.dart';
import 'package:chanolite/screens/settings_screen.dart';
import 'package:chanolite/theme/app_theme.dart';
import 'package:chanolite/theme/theme_notifier.dart';
import 'package:chanolite/widgets/global_download_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chanolite/services/notification_service.dart';
import 'package:chanolite/services/local_notification_service.dart';
import 'package:chanolite/services/cache_service.dart';
import 'package:chanolite/screens/article_detail_screen.dart';
import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/services/api/article_service.dart';
import 'package:chanolite/theme/locale_notifier.dart';
import 'package:chanolite/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true
  );
  await NotificationService.initialize();
  await LocalNotificationService.initialize();
  await _requestNotificationPermission();
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $fcmToken');

  await FirebaseMessaging.instance.subscribeToTopic('all');
  print('Subscribed to topic: all');



  final downloadManager = DownloadManager();
  await downloadManager.loadTasks();

  final initialLocale = await LocaleNotifier.loadSavedLocale();

  runApp(MyApp(
    downloadManager: downloadManager,
    initialLocale: initialLocale,
  ));
}

Future<void> _requestNotificationPermission() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.downloadManager,
    required this.initialLocale,
  });

  final DownloadManager downloadManager;
  final Locale initialLocale;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupInteractedMessage();
  }

  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data.containsKey('article_id')) {
      final articleIdString = message.data['article_id'];
      final articleId = int.tryParse(articleIdString ?? '');
      if (articleId != null) {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => ArticleDetailScreen(articleId: articleId),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = AuthManager()..load();
    return MultiProvider(
      providers: [
        Provider<CacheService>(create: (_) => CacheService()),
        Provider<ArticleService>(create: (_) => ArticleService()),
        ChangeNotifierProvider.value(value: widget.downloadManager),
        ChangeNotifierProvider.value(value: authManager),
        ChangeNotifierProvider(create: (_) => ThemeNotifier(ThemeMode.dark)),
        ChangeNotifierProvider(create: (_) => LocaleNotifier(widget.initialLocale)),
      ],
      child: Consumer2<ThemeNotifier, LocaleNotifier>(
        builder: (context, themeNotifier, localeNotifier, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'ChanoLite',
            theme: AppTheme.light(palette: themeNotifier.currentPalette),
            darkTheme: AppTheme.dark(palette: themeNotifier.currentPalette),
            themeMode: themeNotifier.themeMode,
            locale: localeNotifier.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('th'),
              Locale('ja'),
              Locale('zh'),
            ],
            home: const AuthGate(),
            routes: {
              '/login': (_) => const LoginScreen(),
            },
          );
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
