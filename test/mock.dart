
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/models/download_task.dart';
import 'package:chanolite/models/user_model.dart';
import 'package:chanolite/repositories/article_repository.dart';
import 'package:chanolite/models/article_model.dart';

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

class MockAuthManager extends Mock implements AuthManager {
  @override
  Future<void> load() async {}
  @override
  bool get isLoading => false;
  @override
  bool get isAuthenticated => true;
  @override
  List<User> get accounts => [];
  @override
  User? get activeAccount => null;
}
class MockDownloadManager extends Mock implements DownloadManager {
  @override
  Future<void> loadTasks() async {}

  @override
  List<DownloadTask> get tasks => [];

  @override
  void onDownloadComplete(Function(DownloadTask) callback) {}
}

class MockArticleRepository extends Mock implements ArticleRepository {
  @override
  Future<ArticlesResponse> getArticles({
    int limit = 20,
    int offset = 0,
    String? query,
    String? tag,
    String? category,
    String? platform,
    String? engine,
    String? status,
    String? sequentialCode,
  }) async {
    return ArticlesResponse(articles: [], articlesCount: 0);
  }
}
