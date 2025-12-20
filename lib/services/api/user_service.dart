import 'dart:async';
import 'dart:convert';
import 'package:chanolite/models/user_model.dart';
import 'package:chopper/chopper.dart';
import 'package:chanolite/services/api/api_client.dart';
import 'user_api_service.dart';

class UserService {
  late final ChopperClient _client;
  late final UserApiService _apiService;

  UserService() {
    _client = ChopperClient(
      baseUrl: Uri.parse(ApiClient.baseUrl),
      services: [UserApiService.create()],
      interceptors: [
        _AuthInterceptor(),
      ],
      converter: const JsonConverter(),
    );
    _apiService = _client.getService<UserApiService>();
  }

  void dispose() {
    _client.dispose();
  }

  // User and Authentication

  Future<User> getCurrentUser() async {
    final response = await _apiService.getCurrentUser();
    _checkResponse(response);
    final data = response.body as Map<String, dynamic>;
    return User.fromJson(data['user']);
  }

  Future<User> updateCurrentUser(Map<String, dynamic> user) async {
    final response = await _apiService.updateCurrentUser({'user': user});
    _checkResponse(response);
    final data = response.body as Map<String, dynamic>;
    return User.fromJson(data['user']);
  }

  Future<String> createPermanentToken(String duration, List<String> roles) async {
    final response = await _apiService.createPermanentToken({'duration': duration, 'roles': roles});
    _checkResponse(response);
    final data = response.body as Map<String, dynamic>;
    return data['token'];
  }

  Future<List<dynamic>> listTokens() async {
    final response = await _apiService.listTokens();
    _checkResponse(response);
    return response.body as List<dynamic>;
  }

  Future<void> revokeToken(String id) async {
    final response = await _apiService.revokeToken(id);
    _checkResponse(response);
  }

  Future<User> registerUser(String email, String username, String password) async {
    final response = await _apiService.registerUser({
      'user': {'email': email, 'username': username, 'password': password}
    });
    _checkResponse(response);
    final data = response.body as Map<String, dynamic>;
    return User.fromJson(data['user']);
  }

  Future<User> login(String email, String password) async {
    final response = await _apiService.login({
      'user': {'email': email, 'password': password}
    });
    _checkResponse(response);
    final responseBody = response.body as Map<String, dynamic>;

    if (responseBody['data'] != null) {
      final data = responseBody['data'];
      final userMap = data['user'];
      return User.fromJson(userMap).copyWith(
        refreshToken: data['refreshToken'],
        expiresIn: data['expiresIn'],
      );
    }
    
    // Fallback for old structure or unexpected format
    return User.fromJson(responseBody['user']);
  }

  /// Login using Supabase SSO token.
  Future<User> loginWithSSO(String supabaseToken) async {
    final response = await _apiService.loginWithSSO({
      'token': supabaseToken,
    });
    _checkResponse(response);
    final data = response.body as Map<String, dynamic>;
    return User.fromJson(data['user']);
  }

  // Profile

  Future<Profile> getProfileByUsername(String username) async {
    final response = await _apiService.getProfileByUsername(username);
    _checkResponse(response);
    final data = response.body as Map<String, dynamic>;
    return Profile.fromJson(data['profile']);
  }

  Future<Profile> followUserByUsername(String username) async {
    final response = await _apiService.followUserByUsername(username);
    _checkResponse(response);
    final data = response.body as Map<String, dynamic>;
    return Profile.fromJson(data['profile']);
  }

  Future<Profile> unfollowUserByUsername(String username) async {
    final response = await _apiService.unfollowUserByUsername(username);
    _checkResponse(response);
    final data = response.body as Map<String, dynamic>;
    return Profile.fromJson(data['profile']);
  }

  void _checkResponse(Response response) {
    if (!response.isSuccessful) {
      throw Exception('Request failed: ${response.statusCode} ${response.error}');
    }
  }
}

/// Interceptor to add Authorization header
class _AuthInterceptor implements Interceptor {
  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    final token = ApiClient.authToken;
    Request request = chain.request;
    
    if (token != null && token.isNotEmpty) {
      request = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer $token',
        },
      );
    }
    
    return chain.proceed(request);
  }
}