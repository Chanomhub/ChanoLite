import 'dart:async';
import 'package:chanolite/models/user_model.dart';
import 'package:chopper/chopper.dart';
import 'package:chanolite/services/api/api_client.dart';
import 'package:chanomhub_flutter/chanomhub_flutter.dart' hide User, Profile, Author;
import 'package:chanomhub_flutter/chanomhub_flutter.dart' as sdk_models;
import 'user_api_service.dart';

class UserService {
  late final ChopperClient _client;
  late final UserApiService _apiService;
  final ChanomhubClient? sdk;

  UserService({this.sdk}) {
    _client = ChopperClient(
      baseUrl: Uri.parse(ApiClient.baseUrl),
      services: [UserApiService.create()],
      interceptors: [
        _AuthInterceptor(),
      ],
      authenticator: _AuthAuthenticator(),
      converter: const JsonConverter(),
    );
    _apiService = _client.getService<UserApiService>();
  }

  void dispose() {
    _client.dispose();
  }

  // User and Authentication

  // User and Authentication

  Future<User> getCurrentUser() async {
    // SDK 1.0.1 doesn't have getMe, fallback to chopper service
    final response = await _apiService.getCurrentUser();
    _checkResponse(response);
    final data = response.body as Map<String, dynamic>;
    return User.fromJson(data['user']);
  }

  User _mapSdkUserToLocalUser(sdk_models.UserDTO user, {String? refreshToken, int? expiresIn}) {
    return User(
      roles: user.roles,
      email: user.email,
      username: user.username,
      bio: user.bio,
      image: user.image,
      backgroundImage: user.backgroundImage,
      points: user.points?.toInt() ?? 0,
      shrtflyApiKey: null, // SDK doesn't expose this yet
      token: user.token ?? '',
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      socialMediaLinks: [], // Map if SDK provides it later
    );
  }

  Future<User> registerUser(String email, String username, String password) async {
    if (sdk != null) {
      final response = await sdk!.auth.register(
        email: email,
        username: username,
        password: password,
      );
      return _mapSdkUserToLocalUser(response.user, refreshToken: response.refreshToken, expiresIn: response.expiresIn);
    }
    final response = await _apiService.registerUser({
      'user': {'email': email, 'username': username, 'password': password}
    });
    _checkResponse(response);
    final data = response.body as Map<String, dynamic>;
    return User.fromJson(data['user']);
  }

  Future<User> login(String email, String password) async {
    if (sdk != null) {
      final response = await sdk!.auth.login(
        email: email,
        password: password,
      );
      return _mapSdkUserToLocalUser(response.user, refreshToken: response.refreshToken, expiresIn: response.expiresIn);
    }
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
    
    return User.fromJson(responseBody['user']);
  }

  /// Login using Supabase SSO token.
  Future<User> loginWithSSO(String supabaseToken) async {
    final response = await _apiService.loginWithSSO({
      'token': supabaseToken,
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
    
    return User.fromJson(responseBody['user']);
  }

  Future<User> refreshToken(String refreshToken) async {
    if (sdk != null) {
      final response = await sdk!.auth.refresh(refreshToken);
      // SDK doesn't return user here, only tokens.
      // We might need to fetch the user separately if needed, 
      // but let's at least return what we have.
      return User(
        username: '', // Temporary placeholder
        email: '',
        token: response.accessToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
        points: 0,
        roles: [],
        socialMediaLinks: [],
      );
    }
    final response = await _apiService.refreshToken({
      'refreshToken': refreshToken,
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

    return User.fromJson(responseBody['user']);
  }

  Future<void> logout() async {
    if (sdk != null) {
      final token = ApiClient.refreshToken;
      if (token != null) {
        await sdk!.auth.logout(token);
      }
      return;
    }
    final response = await _apiService.logout();
    _checkResponse(response);
  }

  Future<void> logoutAll() async {
    if (sdk != null) {
      await sdk!.auth.logoutAll();
      return;
    }
    final response = await _apiService.logoutAll();
    _checkResponse(response);
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
      print('Request failed: Status=${response.statusCode} Error=${response.error} Body=${response.body}');
      throw Exception('Request failed: ${response.statusCode} ${response.error} body: ${response.body}');
    }
  }
}

class _AuthAuthenticator extends Authenticator {
  @override
  FutureOr<Request?> authenticate(
      Request request, Response response, [Request? originalRequest]) async {
    if (response.statusCode == 401 && ApiClient.onUnauthorized != null) {
      try {
        await ApiClient.onUnauthorized!();
        final newToken = ApiClient.authToken;
        if (newToken != null) {
          return request.copyWith(headers: {
            ...request.headers,
            'Authorization': 'Bearer $newToken',
          });
        }
      } catch (e) {
        print('Chopper authentication failed: $e');
      }
    }
    return null;
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