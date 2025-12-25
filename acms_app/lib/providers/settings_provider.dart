import 'package:flutter/material.dart';
import 'package:acms_app/services/settings_service.dart';
import 'package:acms_app/theme/theme_manager.dart';
import 'package:acms_app/services/push_notification_service.dart';

class UserSettings {
  final int id;
  final int userId;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final String themePreference;

  UserSettings({
    required this.id,
    required this.userId,
    required this.pushNotificationsEnabled,
    required this.emailNotificationsEnabled,
    required this.themePreference,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      pushNotificationsEnabled: json['push_notifications_enabled'] ?? false,
      emailNotificationsEnabled: json['email_notifications_enabled'] ?? true,
      themePreference: json['theme_preference'] ?? 'system',
    );
  }

  factory UserSettings.defaults() {
    return UserSettings(
      id: 0,
      userId: 0,
      pushNotificationsEnabled: false,
      emailNotificationsEnabled: true,
      themePreference: 'system',
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  final PushNotificationService _pushService = PushNotificationService();

  UserSettings _settings = UserSettings.defaults();
  bool _isLoading = false;
  String? _error;

  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get pushNotificationsEnabled => _settings.pushNotificationsEnabled;
  bool get emailNotificationsEnabled => _settings.emailNotificationsEnabled;
  String get themePreference => _settings.themePreference;

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _settingsService.getSettings();
      _settings = UserSettings.fromJson(data);
      _syncThemeMode(_settings.themePreference);
    } catch (e) {
      _error = e.toString();
      _settings = UserSettings.defaults();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePushNotifications(bool enabled) async {
    _isLoading = true;
    notifyListeners();

    try {
      // If enabling, request permission process first
      if (enabled) {
        final granted = await _pushService.requestPermission();
        if (!granted) {
          // Permission denied, don't update settings
          _error =
              'Permission denied. Please enable notifications in system settings.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final data = await _settingsService.updateSettings(
        pushNotificationsEnabled: enabled,
      );
      _settings = UserSettings.fromJson(data);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmailNotifications(bool enabled) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _settingsService.updateSettings(
        emailNotificationsEnabled: enabled,
      );
      _settings = UserSettings.fromJson(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateThemePreference(String theme) async {
    themeManager.setThemeMode(_getThemeMode(theme));

    try {
      final data = await _settingsService.updateSettings(
        themePreference: theme,
      );
      _settings = UserSettings.fromJson(data);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String current, String newPass) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _settingsService.changePassword(current, newPass);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _settingsService.deleteAccount();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _syncThemeMode(String themePreference) {
    themeManager.setThemeMode(_getThemeMode(themePreference));
  }

  ThemeMode _getThemeMode(String preference) {
    switch (preference) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _settings = UserSettings.defaults();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
