import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/screens/registration_screen.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide User, Profile, Download, Article, Author;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('RegistrationScreen renders all form fields', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
    final authManager = AuthManager(sdk: sdk);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthManager>.value(
        value: authManager,
        child: const MaterialApp(
          home: RegistrationScreen(),
        ),
      ),
    );

    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
  });

  testWidgets('RegistrationScreen validates empty inputs', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});
    final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
    final authManager = AuthManager(sdk: sdk);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthManager>.value(
        value: authManager,
        child: const MaterialApp(
          home: RegistrationScreen(),
        ),
      ),
    );

    final registerButton = find.widgetWithText(ElevatedButton, 'Register');
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your username'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
