// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../utils/constants.dart';

class ApiService {
  // Get token from storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // Get headers
  static Future<Map<String, String>> _getHeaders({
    bool needsAuth = false,
  }) async {
    final headers = {'Content-Type': 'application/json'};

    if (needsAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET request
  static Future<dynamic> get(
    String endpoint, {
    bool needsAuth = false,
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse(endpoint);

      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _getHeaders(needsAuth: needsAuth);

      print('[API GET] $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse(response);
    } catch (e) {
      print('[API ERROR] $e');
      throw _handleError(e);
    }
  }

  // POST request
  static Future<dynamic> post(
    String endpoint, {
    required dynamic body,
    bool needsAuth = false,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final headers = await _getHeaders(needsAuth: needsAuth);

      print('[API POST] $uri');
      print('[API BODY] $body');

      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse(response);
    } catch (e) {
      print('[API ERROR] $e');
      throw _handleError(e);
    }
  }

  // PUT request
  static Future<dynamic> put(
    String endpoint, {
    required dynamic body,
    bool needsAuth = true,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final headers = await _getHeaders(needsAuth: needsAuth);

      final response = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  static Future<dynamic> delete(
    String endpoint, {
    bool needsAuth = true,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final headers = await _getHeaders(needsAuth: needsAuth);

      final response = await http
          .delete(uri, headers: headers)
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Handle response
  static dynamic _handleResponse(http.Response response) {
    print('[API RESPONSE] ${response.statusCode}');
    print('[API BODY] ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw errorBody['error'] ?? 'Something went wrong';
    }
  }

  // Handle error
  static String _handleError(dynamic error) {
    if (error is String) return error;
    return 'Network error. Please check your connection.';
  }
}
