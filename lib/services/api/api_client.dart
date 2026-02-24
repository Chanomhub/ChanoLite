
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://api.chanomhub.com/api';
  static String? _authToken;
  static String? _refreshToken;
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static void updateAuthToken(String? token) {
    _authToken = token;
  }

  static void updateRefreshToken(String? token) {
    _refreshToken = token;
  }

  static String? get authToken => _authToken;
  static String? get refreshToken => _refreshToken;

  static Future<void> Function()? onUnauthorized;

  Future<dynamic> get(String endpoint, {Map<String, String>? headers, bool isRetry = false}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _httpClient.get(uri, headers: _buildHeaders(headers));
    return _handleResponse(response, () => get(endpoint, headers: headers, isRetry: true), isRetry);
  }

  Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers, bool isRetry = false}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _httpClient.post(uri, headers: _buildHeaders(headers), body: json.encode(body));
    return _handleResponse(response, () => post(endpoint, body: body, headers: headers, isRetry: true), isRetry);
  }

  Future<dynamic> put(String endpoint, {dynamic body, Map<String, String>? headers, bool isRetry = false}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _httpClient.put(uri, headers: _buildHeaders(headers), body: json.encode(body));
    return _handleResponse(response, () => put(endpoint, body: body, headers: headers, isRetry: true), isRetry);
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers, bool isRetry = false}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _httpClient.delete(uri, headers: _buildHeaders(headers));
    return _handleResponse(response, () => delete(endpoint, headers: headers, isRetry: true), isRetry);
  }

  Future<Map<String, dynamic>> query(String query, {Map<String, dynamic>? variables, bool isRetry = false}) async {
    final uri = Uri.parse('$baseUrl/graphql');
    final body = {
      'query': query,
      'variables': variables,
    };
    final response = await _httpClient.post(uri, headers: _buildHeaders(null), body: json.encode(body));
    
    final data = _handleResponse(response, () => this.query(query, variables: variables, isRetry: true), isRetry);
    if (data is Map<String, dynamic> && data.containsKey('errors')) {
       throw Exception('GraphQL Error: ${json.encode(data['errors'])}');
    }
    return data as Map<String, dynamic>;
  }

  Map<String, String> _buildHeaders(Map<String, String>? additionalHeaders) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response, Future<dynamic> Function() retryAction, bool isRetry) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      } else {
        return {};
      }
    } else if (response.statusCode == 401 && !isRetry && onUnauthorized != null) {
      // Handle Unauthorized by refreshing the token and retrying
      return onUnauthorized!().then((_) => retryAction());
    } else {
      // You can handle different error codes here
      throw Exception('Failed to load data: ${response.statusCode} ${response.body}');
    }
  }
}
