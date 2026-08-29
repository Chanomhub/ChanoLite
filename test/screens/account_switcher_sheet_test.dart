import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/models/user_model.dart';
import 'package:chanolite/screens/account_switcher_sheet.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide User, Profile, Download, Article, Author;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AccountSwitcherSheet renders accounts and add account button', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
    final authManager = AuthManager(sdk: sdk);

    final user1 = User(
      roles: ['user'],
      email: 'user1@example.com',
      username: 'user_one',
      points: 10,
      token: 'token1',
      socialMediaLinks: [],
    );

    await authManager.addAccount(user1);
    await authManager.setActiveAccount(user1);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthManager>.value(
        value: authManager,
        child: const MaterialApp(
          home: Scaffold(
            body: AccountSwitcherSheet(),
          ),
        ),
      ),
    );

    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('user_one'), findsOneWidget);
    expect(find.text('user1@example.com'), findsOneWidget);
    expect(find.text('Add account'), findsOneWidget);
  });
}
