import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/models/download_task.dart';
import 'package:chanolite/widgets/global_download_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeIndicatorDownloadManager extends ChangeNotifier implements DownloadManager {
  List<DownloadTask> _taskList;
  FakeIndicatorDownloadManager(this._taskList);

  @override
  List<DownloadTask> get tasks => _taskList;

  @override
  Map<String, DownloadTask> get downloads => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('GlobalDownloadIndicator hides when no active downloads', (WidgetTester tester) async {
    final manager = FakeIndicatorDownloadManager([]);

    await tester.pumpWidget(
      ChangeNotifierProvider<DownloadManager>.value(
        value: manager,
        child: const MaterialApp(
          home: Scaffold(
            body: GlobalDownloadIndicator(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.download), findsNothing);
  });

  testWidgets('GlobalDownloadIndicator renders active downloading task', (WidgetTester tester) async {
    final task = DownloadTask(
      url: 'https://example.com/game.zip',
      fileName: 'game.zip',
      status: DownloadTaskStatus.running,
      progress: 0.75,
    );
    final manager = FakeIndicatorDownloadManager([task]);

    await tester.pumpWidget(
      ChangeNotifierProvider<DownloadManager>.value(
        value: manager,
        child: const MaterialApp(
          home: Scaffold(
            body: GlobalDownloadIndicator(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.download), findsOneWidget);
    expect(find.text('game.zip'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });
}
