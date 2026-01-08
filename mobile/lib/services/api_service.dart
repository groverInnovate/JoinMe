import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

/// API Service for making HTTP requests
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  /// Set auth token for authenticated requests
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear auth token on logout
  void clearAuthToken() {
    _authToken = null;
  }

  /// Get default headers
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Build full URL
  String _buildUrl(String endpoint) {
    return '${ApiConstants.baseUrl}${ApiConstants.apiVersion}$endpoint';
  }

  /// GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse(_buildUrl(endpoint)),
            headers: _headers,
          )
          .timeout(const Duration(milliseconds: ApiConstants.connectionTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_buildUrl(endpoint)),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(milliseconds: ApiConstants.connectionTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(_buildUrl(endpoint)),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(milliseconds: ApiConstants.connectionTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse(_buildUrl(endpoint)),
            headers: _headers,
          )
          .timeout(const Duration(milliseconds: ApiConstants.connectionTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['message'] ?? 'Request failed');
    }
  }
}
