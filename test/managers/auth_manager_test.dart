import 'dart:convert';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/models/user_model.dart';
import 'package:chanolite/services/api/user_service.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide User, Profile, Download, Article, Author;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserService extends Mock implements UserService {
  @override
  Future<User> login(String email, String password) async {
    return User(
      roles: ['user'],
      email: email,
      username: 'user_${email.split('@').first}',
      points: 100,
      token: 'mock_token_$email',
      refreshToken: 'mock_refresh_$email',
      socialMediaLinks: [],
    );
  }

  @override
  Future<User> registerUser(String email, String username, String password) async {
    return User(
      roles: ['user'],
      email: email,
      username: username,
      points: 50,
      token: 'mock_token_$username',
      refreshToken: 'mock_refresh_$username',
      socialMediaLinks: [],
    );
  }

  @override
  Future<User> exchangeBetterAuthSession(String cookie) async {
    return User(
      roles: ['user'],
      email: 'sso@example.com',
      username: 'sso_user',
      points: 200,
      token: 'sso_token_123',
      refreshToken: 'sso_refresh_123',
      socialMediaLinks: [],
    );
  }

  @override
  Future<User> getCurrentUser() async {
    return User(
      roles: ['user', 'vip'],
      email: 'updated@example.com',
      username: 'sso_user',
      points: 999,
      token: 'fresh_token',
      socialMediaLinks: [],
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutAll() async {}
}

void main() {
  group('AuthManager Tests', () {
    late AuthManager authManager;
    late MockUserService mockUserService;
    late ChanomhubClient sdk;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockUserService = MockUserService();
      sdk = ChanomhubClient(baseUrl: 'http://localhost', cdnUrl: '');
      authManager = AuthManager(userService: mockUserService, sdk: sdk);
    });

    test('Initial state is unauthenticated and not loading', () {
      expect(authManager.isLoading, isFalse);
      expect(authManager.isAuthenticated, isFalse);
      expect(authManager.accounts, isEmpty);
      expect(authManager.activeAccount, isNull);
    });

    test('load() restores saved accounts from SharedPreferences', () async {
      final savedUser = User(
        roles: ['user'],
        email: 'saved@example.com',
        username: 'saved_user',
        points: 50,
        token: 'token_saved',
        refreshToken: 'refresh_saved',
        socialMediaLinks: [],
      );

      SharedPreferences.setMockInitialValues({
        'auth_accounts': [json.encode(savedUser.toJson())],
        'auth_active_account': 'saved_user',
      });

      await authManager.load();

      expect(authManager.isAuthenticated, isTrue);
      expect(authManager.accounts.length, 1);
      expect(authManager.activeAccount?.username, 'saved_user');
      expect(authManager.activeAccount?.email, 'saved@example.com');
    });

    test('login() logs in and sets active user', () async {
      await authManager.login(email: 'test@example.com', password: 'password123');

      expect(authManager.isAuthenticated, isTrue);
      expect(authManager.accounts.length, 1);
      expect(authManager.activeAccount?.email, 'test@example.com');
      expect(authManager.activeAccount?.token, 'mock_token_test@example.com');
    });

    test('register() creates account and activates it', () async {
      await authManager.register(
        email: 'new@example.com',
        username: 'newbie',
        password: 'password123',
      );

      expect(authManager.isAuthenticated, isTrue);
      expect(authManager.activeAccount?.username, 'newbie');
    });

    test('loginWithGoogle() exchanges session and sets active user', () async {
      await authManager.loginWithGoogle('mock_cookie=123');

      expect(authManager.isAuthenticated, isTrue);
      expect(authManager.activeAccount?.username, 'sso_user');
    });

    test('removeAccount() removes user and updates active account', () async {
      final user1 = User(
        roles: ['user'],
        email: 'u1@example.com',
        username: 'user1',
        points: 0,
        token: 't1',
        socialMediaLinks: [],
      );
      final user2 = User(
        roles: ['user'],
        email: 'u2@example.com',
        username: 'user2',
        points: 0,
        token: 't2',
        socialMediaLinks: [],
      );

      await authManager.addAccount(user1);
      await authManager.addAccount(user2);
      await authManager.setActiveAccount(user1);

      expect(authManager.accounts.length, 2);
      expect(authManager.activeAccount?.username, 'user1');

      await authManager.removeAccount(user1);
      expect(authManager.accounts.length, 1);
      expect(authManager.activeAccount?.username, 'user2');

      await authManager.removeAccount(user2);
      expect(authManager.accounts, isEmpty);
      expect(authManager.isAuthenticated, isFalse);
    });

    test('signOutAll() clears all accounts and reset tokens', () async {
      await authManager.login(email: 'user@example.com', password: 'password');
      expect(authManager.isAuthenticated, isTrue);

      await authManager.signOutAll();
      expect(authManager.accounts, isEmpty);
      expect(authManager.activeAccount, isNull);
      expect(authManager.isAuthenticated, isFalse);
    });
  });
}
