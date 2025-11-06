import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel('plugins.flutter.io/firebase_core')
      .setMockMethodCallHandler((call) async {
    if (call.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': '123',
            'appId': '123',
            'messagingSenderId': '123',
            'projectId': '123',
          },
          'pluginConstants': {},
        }
      ];
    }

    if (call.method == 'Firebase#initializeApp') {
      return {
        'name': call.arguments['appName'],
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }

    if (customHandlers != null) {
      customHandlers(call);
    }

    return null;
  });

  const MethodChannel('plugins.flutter.io/firebase_core/app')
      .setMockMethodCallHandler((call) async {
    if (call.method == 'FirebaseApp#options') {
      return {
        'apiKey': '123',
        'appId': '123',
        'messagingSenderId': '123',
        'projectId': '123',
      };
    }
    return null;
  });
}

class MockAuthManager extends Mock implements AuthManager {}
class MockDownloadManager extends Mock implements DownloadManager {}
