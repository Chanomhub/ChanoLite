import 'dart:convert';

import 'package:chanolite/models/user_model.dart';
import 'package:chanolite/services/api/api_client.dart';
import 'package:chanolite/services/api/user_service.dart';
import 'package:chanolite/services/supabase_auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager extends ChangeNotifier {
  AuthManager({UserService? userService})
      : _userService = userService ?? UserService();

  static const String _accountsKey = 'auth_accounts';
  static const String _activeKey = 'auth_active_account';

  final UserService _userService;
  final List<User> _accounts = [];

  bool _loading = false;
  User? _active;

  List<User> get accounts => List.unmodifiable(_accounts);
  User? get activeAccount => _active;
  bool get isLoading => _loading;
  bool get isAuthenticated => _active != null;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_accountsKey) ?? [];
    final activeUsername = prefs.getString(_activeKey);

    _accounts
      ..clear()
      ..addAll(
        stored
            .map((encoded) {
              try {
                final decoded = json.decode(encoded) as Map<String, dynamic>;
                return User.fromJson(decoded);
              } catch (_) {
                return null;
              }
            })
            .whereType<User>()
            .toList(),
      );

    if (_accounts.isEmpty) {
      _active = null;
    } else if (activeUsername != null && activeUsername.isNotEmpty) {
      _active = _accounts.firstWhere(
        (user) => user.username == activeUsername,
        orElse: () => _accounts.first,
      );
    } else {
      _active = _accounts.first;
    }

    ApiClient.updateAuthToken(_active?.token);

    _loading = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _loading = true;
    notifyListeners();

    try {
      final user = await _userService.login(email, password);
      await _addOrUpdateAccount(user);
      await _setActive(user);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register(
      {required String email,
      required String username,
      required String password}) async {
    _loading = true;
    notifyListeners();

    try {
      final user = await _userService.registerUser(email, username, password);
      await _addOrUpdateAccount(user);
      await _setActive(user);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Login using Google SSO via Supabase.
  /// Initiates OAuth flow, then exchanges Supabase token with backend.
  Future<void> loginWithGoogle() async {
    final supabaseAuth = SupabaseAuthService.instance;
    if (!supabaseAuth.isAvailable) {
      throw Exception('Supabase is not initialized');
    }

    _loading = true;
    notifyListeners();

    try {
      // Initiate Google OAuth flow
      await supabaseAuth.signInWithGoogle();

      // After redirect, get the access token
      final accessToken = supabaseAuth.accessToken;
      if (accessToken == null) {
        throw Exception('No access token from Supabase');
      }

      // Exchange Supabase token with backend
      final user = await _userService.loginWithSSO(accessToken);
      await _addOrUpdateAccount(user);
      await _setActive(user);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setActiveAccount(User user) async {
    await _setActive(user);
    notifyListeners();
  }

  Future<void> addAccount(User user) async {
    await _addOrUpdateAccount(user);
    notifyListeners();
  }

  Future<void> removeAccount(User user) async {
    _accounts.removeWhere((u) => u.username == user.username);
    if (_active?.username == user.username) {
      _active = _accounts.isEmpty ? null : _accounts.first;
      await _persistActive();
    }
    await _persistAccounts();
    ApiClient.updateAuthToken(_active?.token);
    notifyListeners();
  }

  Future<void> signOutAll() async {
    _accounts.clear();
    _active = null;
    await _persistAccounts();
    await _persistActive();
    ApiClient.updateAuthToken(null);
    notifyListeners();
  }

  Future<void> refreshActive() async {
    final active = _active;
    if (active == null) {
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final fresh = await _userService.getCurrentUser();
      final updated = fresh.copyWith(token: active.token);
      await _addOrUpdateAccount(updated);
      await _setActive(updated);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _setActive(User user) async {
    _active = user;
    ApiClient.updateAuthToken(user.token);
    await _persistActive();
  }

  Future<void> _addOrUpdateAccount(User user) async {
    final index = _accounts.indexWhere((existing) => existing.username == user.username);
    if (index >= 0) {
      _accounts[index] = user;
    } else {
      _accounts.add(user);
    }
    await _persistAccounts();
  }

  Future<void> _persistAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _accounts.map((user) => json.encode(user.toJson())).toList();
    await prefs.setStringList(_accountsKey, encoded);
  }

  Future<void> _persistActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, _active?.username ?? '');
  }
}
