import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling Supabase authentication, specifically OAuth SSO.
class SupabaseAuthService {
  SupabaseAuthService._();

  static final SupabaseAuthService _instance = SupabaseAuthService._();
  static SupabaseAuthService get instance => _instance;

  SupabaseClient get _client => Supabase.instance.client;

  /// Check if Supabase is available (initialized).
  bool get isAvailable {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Current Supabase session.
  Session? get currentSession => _client.auth.currentSession;

  /// Current Supabase user.
  User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with Google OAuth.
  /// Returns the Supabase session after successful authentication.
  Future<AuthResponse> signInWithGoogle() async {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.chanomhub.chanolite://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!response) {
      throw Exception('Failed to initiate Google sign-in');
    }

    // The OAuth flow will redirect back to the app.
    // We need to wait for the auth state change.
    // The caller should listen to authStateChanges or use getSessionFromUrl.
    
    // Wait for the session to be available after redirect
    await Future.delayed(const Duration(seconds: 1));
    
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('No session after Google sign-in');
    }

    return AuthResponse(session: session, user: session.user);
  }

  /// Get the current access token for backend exchange.
  String? get accessToken => currentSession?.accessToken;

  /// Sign out from Supabase.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Handle deep link callback from OAuth.
  Future<AuthSessionUrlResponse?> handleDeepLink(Uri uri) async {
    if (uri.scheme == 'com.chanomhub.chanolite' && uri.host == 'login-callback') {
      final response = await _client.auth.getSessionFromUrl(uri);
      return response;
    }
    return null;
  }
}
