import 'package:shared_preferences/shared_preferences.dart';

/// Service for local storage using SharedPreferences
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ======== Auth Token Storage ========

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Save auth token
  Future<void> saveToken(String token) async {
    await prefs.setString(_tokenKey, token);
  }

  /// Get auth token
  String? getToken() {
    return prefs.getString(_tokenKey);
  }

  /// Remove auth token
  Future<void> removeToken() async {
    await prefs.remove(_tokenKey);
  }

  /// Check if user is logged in
  bool get isLoggedIn => getToken() != null;

  // ======== User Data Storage ========

  /// Save user data as JSON string
  Future<void> saveUserData(String userData) async {
    await prefs.setString(_userKey, userData);
  }

  /// Get user data JSON string
  String? getUserData() {
    return prefs.getString(_userKey);
  }

  /// Remove user data
  Future<void> removeUserData() async {
    await prefs.remove(_userKey);
  }

  // ======== Theme Preference ========

  static const String _themeKey = 'theme_mode';

  /// Save theme mode (0: system, 1: light, 2: dark)
  Future<void> saveThemeMode(int mode) async {
    await prefs.setInt(_themeKey, mode);
  }

  /// Get theme mode
  int getThemeMode() {
    return prefs.getInt(_themeKey) ?? 0; // Default to system
  }

  // ======== Onboarding ========

  static const String _onboardingKey = 'onboarding_complete';

  /// Set onboarding complete
  Future<void> setOnboardingComplete() async {
    await prefs.setBool(_onboardingKey, true);
  }

  /// Check if onboarding is complete
  bool get isOnboardingComplete {
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // ======== General Methods ========

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    await prefs.clear();
  }

  /// Remove specific key
  Future<void> remove(String key) async {
    await prefs.remove(key);
  }

  /// Save string value
  Future<void> setString(String key, String value) async {
    await prefs.setString(key, value);
  }

  /// Get string value
  String? getString(String key) {
    return prefs.getString(key);
  }

  /// Save bool value
  Future<void> setBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  /// Get bool value
  bool? getBool(String key) {
    return prefs.getBool(key);
  }

  /// Save int value
  Future<void> setInt(String key, int value) async {
    await prefs.setInt(key, value);
  }

  /// Get int value
  int? getInt(String key) {
    return prefs.getInt(key);
  }
}
