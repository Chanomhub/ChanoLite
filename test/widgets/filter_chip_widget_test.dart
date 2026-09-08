import 'package:chanolite/widgets/filter_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppFilterChip renders label and handles tap and delete', (WidgetTester tester) async {
    bool tapped = false;
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFilterChip(
            label: 'RPG',
            isTag: true,
            onTap: () => tapped = true,
            onDeleted: () => deleted = true,
          ),
        ),
      ),
    );

    expect(find.text('RPG'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.text('RPG'));
    expect(tapped, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    expect(deleted, isTrue);
  });
}
