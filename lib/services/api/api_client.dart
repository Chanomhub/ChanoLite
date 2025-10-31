
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://api.chanomhub.online/api';
  static String? _authToken;
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static void updateAuthToken(String? token) {
    _authToken = token;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    print('GET: $uri'); // Debug print
    final response = await _httpClient.get(uri, headers: _buildHeaders(headers));
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _httpClient.post(uri, headers: _buildHeaders(headers), body: json.encode(body));
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _httpClient.put(uri, headers: _buildHeaders(headers), body: json.encode(body));
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _httpClient.delete(uri, headers: _buildHeaders(headers));
    return _handleResponse(response);
  }

  Future<dynamic> query(String query, {Map<String, dynamic>? variables}) async {
        final uri = Uri.parse('https://api.chanomhub.online/api/graphql');
    final body = {
      'query': query,
      'variables': variables,
    };
    final response = await _httpClient.post(uri, headers: _buildHeaders(null), body: json.encode(body));
    return _handleResponse(response);
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

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      } else {
        return {};
      }
    } else {
      // You can handle different error codes here
      throw Exception('Failed to load data: ${response.statusCode} ${response.body}');
    }
  }
}
