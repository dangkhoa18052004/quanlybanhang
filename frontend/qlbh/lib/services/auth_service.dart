// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'dart:convert';

class AuthService {
  // Register
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await ApiService.post(
      '${ApiConfig.auth}/register',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
      },
    );

    // Save token and user
    await _saveAuthData(response['token'], response['user']);

    return response;
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      '${ApiConfig.auth}/login',
      body: {'email': email, 'password': password},
    );

    // Save token and user
    await _saveAuthData(response['token'], response['user']);

    return response;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  // Get profile
  static Future<User> getProfile() async {
    final response = await ApiService.get(
      '${ApiConfig.auth}/profile',
      needsAuth: true,
    );

    return User.fromJson(response['user']);
  }

  // Update profile
  static Future<User> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    final response = await ApiService.put(
      '${ApiConfig.auth}/profile',
      body: {'full_name': fullName, 'phone': phone, 'address': address},
      needsAuth: true,
    );

    // Update saved user
    await _saveUser(response['user']);

    return User.fromJson(response['user']);
  }

  // Change password
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await ApiService.post(
      '${ApiConfig.auth}/change-password',
      body: {'old_password': oldPassword, 'new_password': newPassword},
      needsAuth: true,
    );
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(AppConstants.tokenKey);
  }

  // Get saved user
  static Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);

    if (userJson == null) return null;

    return User.fromJson(jsonDecode(userJson));
  }

  // Save auth data
  static Future<void> _saveAuthData(
    String token,
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userKey, jsonEncode(userData));
  }

  // Save user
  static Future<void> _saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(userData));
  }
}
