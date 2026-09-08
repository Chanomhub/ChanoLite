import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/models/download_task.dart';
import 'package:chanolite/screens/game_library_screen.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide User, Profile, Download, Article, Author;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDownloadManager extends ChangeNotifier implements DownloadManager {
  final List<DownloadTask> _taskList;
  FakeDownloadManager([this._taskList = const []]);

  @override
  List<DownloadTask> get tasks => _taskList;

  @override
  Future<void> loadTasks() async {}

  @override
  void onDownloadComplete(Function(DownloadTask) callback) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('GameLibraryScreen displays empty state when no tasks exist', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
    final authManager = AuthManager(sdk: sdk);
    final downloadManager = FakeDownloadManager([]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthManager>.value(value: authManager),
          ChangeNotifierProvider<DownloadManager>.value(value: downloadManager),
        ],
        child: const MaterialApp(
          home: GameLibraryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Game Library'), findsOneWidget);
    expect(find.text('No downloads yet.'), findsOneWidget);
  });
}
