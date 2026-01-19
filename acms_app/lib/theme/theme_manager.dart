import 'package:flutter/material.dart';

class ThemeManager extends ChangeNotifier {
  // Default to dark theme
  ThemeMode _themeMode = ThemeMode.dark;

  String _themeColor = 'red';

  ThemeMode get themeMode => _themeMode;
  String get themeColor => _themeColor;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void setThemeColor(String color) {
    if (_themeColor != color) {
      _themeColor = color;
      notifyListeners();
    }
  }
}

final themeManager = ThemeManager();
