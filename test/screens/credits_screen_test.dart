import 'package:chanolite/screens/credits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CreditsScreen displays credits information', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CreditsScreen(),
      ),
    );

    expect(find.text('Credits'), findsOneWidget);
    expect(find.text('Made with ❤️ by ChanoDev'), findsOneWidget);
    expect(
      find.text('This app is a fan-made project and is not affiliated with the official entities of the content provided.'),
      findsOneWidget,
    );
  });
}
