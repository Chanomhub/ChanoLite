import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide User, Profile, Download, Article, Author;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('LoginScreen renders fields and buttons', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
    final authManager = AuthManager(sdk: sdk);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthManager>.value(
        value: authManager,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text("Don't have an account? Sign up"), findsOneWidget);
  });

  testWidgets('LoginScreen displays validation error when submitted empty', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
    final authManager = AuthManager(sdk: sdk);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthManager>.value(
        value: authManager,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    final signInButton = find.widgetWithText(ElevatedButton, 'Sign in');
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
