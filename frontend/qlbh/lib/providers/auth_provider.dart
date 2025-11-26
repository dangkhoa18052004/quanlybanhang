// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;

  // Initialize (check if logged in) - FIXED
  Future<void> initialize() async {
    // Không set state ngay lập tức
    _isLoading = true;

    try {
      final isLoggedIn = await AuthService.isLoggedIn();

      if (isLoggedIn) {
        _user = await AuthService.getSavedUser();

        // Refresh profile from server
        try {
          _user = await AuthService.getProfile();
        } catch (e) {
          print('Token expired, logging out: $e');
          // If token expired, logout
          await logout();
        }
      }
    } catch (e) {
      _error = e.toString();
      print('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;

      // Sử dụng addPostFrameCallback để tránh lỗi build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Register - FIXED
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;

    try {
      final response = await AuthService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      _user = User.fromJson(response['user']);
      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return false;
    }
  }

  // Login - FIXED
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;

    try {
      final response = await AuthService.login(
        email: email,
        password: password,
      );

      _user = User.fromJson(response['user']);
      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return false;
    }
  }

  // Logout - FIXED
  Future<void> logout() async {
    await AuthService.logout();
    _user = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Update profile - FIXED
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;

    try {
      _user = await AuthService.updateProfile(
        fullName: fullName,
        phone: phone,
        address: address,
      );
      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return false;
    }
  }

  // Clear error - FIXED
  void clearError() {
    _error = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
