import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Theme state provider
class ThemeProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Initialize theme from storage
  Future<void> init() async {
    final savedMode = _storageService.getThemeMode();
    _themeMode = _themeModeFromInt(savedMode);
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storageService.saveThemeMode(_themeModeToInt(mode));
    notifyListeners();
  }

  /// Toggle between light and dark
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Check if dark mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Helper methods
  ThemeMode _themeModeFromInt(int value) {
    switch (value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  int _themeModeToInt(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      case ThemeMode.system:
        return 0;
    }
  }
}
