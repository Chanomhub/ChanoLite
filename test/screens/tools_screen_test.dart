import 'package:chanolite/screens/tools_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ToolsScreen renders app bar and tools list', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ToolsScreen(),
      ),
    );

    // Initial pump
    await tester.pumpAndSettle();

    expect(find.text('Game Tools'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
