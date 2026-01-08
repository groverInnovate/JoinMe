import '../models/user_model.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

/// Authentication service for login, register, logout
class AuthService {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Login user
  Future<User> login(String email, String password) async {
    final response = await _apiService.post(
      ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response['token'] != null) {
      _apiService.setAuthToken(response['token']);
    }

    _currentUser = User.fromJson(response['user']);
    return _currentUser!;
  }

  /// Register new user
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? college,
  }) async {
    final response = await _apiService.post(
      ApiConstants.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        if (college != null) 'college': college,
      },
    );

    if (response['token'] != null) {
      _apiService.setAuthToken(response['token']);
    }

    _currentUser = User.fromJson(response['user']);
    return _currentUser!;
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _apiService.post(ApiConstants.logout);
    } finally {
      _apiService.clearAuthToken();
      _currentUser = null;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Get current user profile
  Future<User> getProfile() async {
    final response = await _apiService.get(ApiConstants.userProfile);
    _currentUser = User.fromJson(response['user']);
    return _currentUser!;
  }

  /// Update user profile
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.put(
      ApiConstants.updateProfile,
      body: data,
    );
    _currentUser = User.fromJson(response['user']);
    return _currentUser!;
  }
}
