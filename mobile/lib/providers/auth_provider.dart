import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

/// Authentication state provider
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Initialize auth state from storage
  Future<void> init() async {
    await _storageService.init();
    
    final token = _storageService.getToken();
    if (token != null) {
      _apiService.setAuthToken(token);
      
      final userData = _storageService.getUserData();
      if (userData != null) {
        try {
          _user = User.fromJson(jsonDecode(userData));
          notifyListeners();
        } catch (e) {
          // Invalid user data, clear storage
          await logout();
        }
      }
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.login(email, password);
      
      // Save token and user data
      final token = _storageService.getToken();
      if (token != null) {
        await _storageService.saveToken(token);
      }
      await _storageService.saveUserData(jsonEncode(_user!.toJson()));
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? verificationToken,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        verificationToken: verificationToken,
      );
      
      await _storageService.saveUserData(jsonEncode(_user!.toJson()));
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors
    }

    // Clear local data
    await _storageService.removeToken();
    await _storageService.removeUserData();
    _apiService.clearAuthToken();
    _user = null;
    
    _setLoading(false);
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.updateProfile(data);
      await _storageService.saveUserData(jsonEncode(_user!.toJson()));
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
