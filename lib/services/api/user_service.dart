import 'package:chanolite/models/user_model.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _apiClient;

  UserService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // User and Authentication

  Future<User> getCurrentUser() async {
    final data = await _apiClient.get('user') as Map<String, dynamic>;;
    return User.fromJson(data['user']);
  }

  Future<User> updateCurrentUser(Map<String, dynamic> user) async {
    final data = await _apiClient.put('user', body: {'user': user}) as Map<String, dynamic>;;
    return User.fromJson(data['user']);
  }

  Future<String> createPermanentToken(String duration, List<String> roles) async {
    final data = await _apiClient.post('user/tokens', body: {'duration': duration, 'roles': roles}) as Map<String, dynamic>;;
    return data['token'];
  }

  Future<List<dynamic>> listTokens() async {
    final data = await _apiClient.get('user/tokens') as List<dynamic>;
    return data;
  }

  Future<void> revokeToken(String id) async {
    await _apiClient.delete('user/tokens/$id');
  }

  Future<User> registerUser(String email, String username, String password) async {
    final data = await _apiClient.post('users', body: {
      'user': {'email': email, 'username': username, 'password': password}
    }) as Map<String, dynamic>;;
    return User.fromJson(data['user']);
  }

  Future<User> login(String email, String password) async {
    final data = await _apiClient.post('users/login', body: {
      'user': {'email': email, 'password': password}
    }) as Map<String, dynamic>;;
    return User.fromJson(data['user']);
  }

  /// Login using Supabase SSO token.
  /// Exchanges the Supabase access token with the backend to get an app User.
  Future<User> loginWithSSO(String supabaseToken) async {
    final data = await _apiClient.post('users/sso', body: {
      'token': supabaseToken,
    }) as Map<String, dynamic>;
    return User.fromJson(data['user']);
  }

  // Profile

  Future<Profile> getProfileByUsername(String username) async {
    final data = await _apiClient.get('profiles/$username') as Map<String, dynamic>;;
    return Profile.fromJson(data['profile']);
  }

  Future<Profile> followUserByUsername(String username) async {
    final data = await _apiClient.post('profiles/$username/follow') as Map<String, dynamic>;;
    return Profile.fromJson(data['profile']);
  }

  Future<Profile> unfollowUserByUsername(String username) async {
    final data = await _apiClient.delete('profiles/$username/follow') as Map<String, dynamic>;;
    return Profile.fromJson(data['profile']);
  }
}