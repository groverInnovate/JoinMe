import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

/// Authentication service for login, register, logout
class AuthService {
  final ApiService _apiService = ApiService();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Initialize service (check for stored token)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    // TODO: Load user data from prefs if needed
    if (token != null) {
      _apiService.setAuthToken(token);
      try {
        await getProfile(); // Verify token and get fresh user data
      } catch (e) {
        // Token invalid or expired
        await logout(); 
      }
    }
  }

  /// Login user
  Future<User> login(String email, String password) async {
    final response = await _apiService.post(
      ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response['data'] != null && response['data']['token'] != null) {
      final token = response['data']['token'] as String;
      _apiService.setAuthToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }
    
    // API returns {success: true, data: { ...user, token }}
    _currentUser = User.fromJson(response['data']);
    return _currentUser!;
  }

  /// Register new user
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? verificationToken, // From Aadhaar verification
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
      if (verificationToken != null) 'verificationToken': verificationToken,
    };
    
    final response = await _apiService.post(
      ApiConstants.register,
      body: body,
    );

    if (response['data'] != null && response['data']['token'] != null) {
      final token = response['data']['token'] as String;
      _apiService.setAuthToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }

    _currentUser = User.fromJson(response['data']);
    return _currentUser!;
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Optional: Call server logout if endpoint exists
      // await _apiService.post(ApiConstants.logout);
    } catch (e) {
      // Ignore network errors on logout
    } finally {
      _apiService.clearAuthToken();
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Get current user profile
  Future<User> getProfile() async {
    final response = await _apiService.get('/auth/me'); // Updated endpoint to match backend
    
    if (response['data'] != null) {
       _currentUser = User.fromJson(response['data']);
       return _currentUser!;
    }
    throw Exception('Failed to load profile');
  }

  /// Update user profile
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.put(
      ApiConstants.updateProfile,
      body: data,
    );
     // Backend returns updated user in 'data'
    if (response['data'] != null) {
       _currentUser = User.fromJson(response['data']);
       return _currentUser!;
    }
     // Fallback for some response structures
    if (response['user'] != null) {
        _currentUser = User.fromJson(response['user']);
       return _currentUser!;
    }
    
    // If no user object returned, fetch profile again
    return getProfile();
  }
}
