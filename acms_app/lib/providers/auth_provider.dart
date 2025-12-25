import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:acms_app/services/auth_service.dart';
import 'package:acms_app/services/api_client.dart';
import 'package:acms_app/services/settings_service.dart';
import 'package:acms_app/services/push_notification_service.dart';

class User {
  final int id;
  final String email;
  final String fullName;
  final bool isActive;
  final String? profilePicture;
  final String? username;
  final String? bio;
  final String? instagram;
  final String? linkedin;
  final String? twitter;
  final String? facebook;
  final int postsCount;
  final int followersCount;
  final int followingCount;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    this.profilePicture,
    this.username,
    this.bio,
    this.instagram,
    this.linkedin,
    this.twitter,
    this.facebook,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? '',
      isActive: json['is_active'] ?? true,
      profilePicture: json['profile_picture'],
      username: json['username'],
      bio: json['bio'],
      instagram: json['instagram'],
      linkedin: json['linkedin'],
      twitter: json['twitter'],
      facebook: json['facebook'],
      postsCount: json['posts_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }

  /// Convert User to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'is_active': isActive,
      'profile_picture': profilePicture,
      'username': username,
      'bio': bio,
      'instagram': instagram,
      'linkedin': linkedin,
      'twitter': twitter,
      'facebook': facebook,
      'posts_count': postsCount,
      'followers_count': followersCount,
      'following_count': followingCount,
    };
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'access_token';
  static const String _userCacheKey = 'cached_user_data';

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _isOffline = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  bool get isOffline => _isOffline;

  AuthProvider() {
    _init();
    ApiClient().onLogout.listen((_) => logout());
  }

  /// Initialize auth state with offline-first approach
  Future<void> _init() async {
    final token = await _storage.read(key: _tokenKey);

    if (token != null) {
      // Step 1: Try to load cached user data first (offline-first)
      final cachedUser = await _loadCachedUser();
      if (cachedUser != null) {
        _user = cachedUser;
        notifyListeners();
      }

      // Step 2: Try to refresh user data from the server
      try {
        await _fetchAndCacheUser();
        _isOffline = false;
      } catch (e) {
        // Check if this is a network error or an auth error
        if (_isNetworkError(e)) {
          // Network error - stay logged in with cached data
          _isOffline = true;
          debugPrint('Offline mode: Using cached user data');
        } else if (_isAuthError(e)) {
          // Auth error (401/403) - token is invalid, logout
          debugPrint('Auth error: Token invalid, logging out');
          await logout();
        } else {
          // Other errors - if we have cached data, stay logged in
          if (_user == null) {
            await logout();
          }
        }
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Check if error is a network connectivity error
  bool _isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;
    }
    // Check for common network error messages
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable');
  }

  /// Check if error is an authentication error (401/403)
  bool _isAuthError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode == 401 || statusCode == 403;
    }
    return false;
  }

  /// Load cached user data from secure storage
  Future<User?> _loadCachedUser() async {
    try {
      final cachedData = await _storage.read(key: _userCacheKey);
      if (cachedData != null) {
        final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;
        return User.fromJson(jsonData);
      }
    } catch (e) {
      debugPrint('Error loading cached user: $e');
    }
    return null;
  }

  /// Save user data to secure storage cache
  Future<void> _cacheUser(User user) async {
    try {
      final jsonData = jsonEncode(user.toJson());
      await _storage.write(key: _userCacheKey, value: jsonData);
    } catch (e) {
      debugPrint('Error caching user: $e');
    }
  }

  /// Clear cached user data
  Future<void> _clearCachedUser() async {
    try {
      await _storage.delete(key: _userCacheKey);
    } catch (e) {
      debugPrint('Error clearing cached user: $e');
    }
  }

  /// Fetch user data from server and cache it
  Future<void> _fetchAndCacheUser() async {
    final userData = await _authService.getMe();
    _user = User.fromJson(userData);
    await _cacheUser(_user!);

    // Initialize Push Notifications if enabled in settings
    try {
      final settingsService = SettingsService();
      final settings = await settingsService.getSettings();

      if (settings['push_notifications_enabled'] == true) {
        final pushService = PushNotificationService();
        // initialize() now only proceeds if permission is already granted
        // so it's safe to call without prompting
        await pushService.initialize();
      }
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await _authService.login(email, password);
      final token = data['access_token'];
      await _storage.write(key: _tokenKey, value: token);
      await _fetchAndCacheUser();
      _isOffline = false;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signup(String email, String password, String fullName) async {
    _setLoading(true);
    try {
      await _authService.signup(email, password, fullName);
      // Removed auto-login: User needs to verify OTP first
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.forgotPassword(email, purpose: 'reset_password');
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp(
    String email,
    String code, {
    String purpose = 'signup',
  }) async {
    _setLoading(true);
    try {
      await _authService.verifyOtp(email, code, purpose: purpose);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email, code, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? profilePicture,
    String? username,
    String? bio,
    String? instagram,
    String? linkedin,
    String? twitter,
    String? facebook,
  }) async {
    _setLoading(true);
    try {
      // Calling AuthService with named arguments
      final userData = await _authService.updateProfile(
        fullName: fullName,
        profilePicture: profilePicture,
        username: username,
        bio: bio,
        instagram: instagram,
        linkedin: linkedin,
        twitter: twitter,
        facebook: facebook,
      );
      _user = User.fromJson(userData);
      await _cacheUser(_user!);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<String> uploadImage(dynamic file) async {
    try {
      return await _authService.uploadProfilePicture(file);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _clearCachedUser();
    _user = null;
    _isOffline = false;
    notifyListeners();
  }

  /// Refresh user data from server (call when back online)
  Future<void> refreshUserData() async {
    if (_user == null) return;
    try {
      await _fetchAndCacheUser();
      _isOffline = false;
      notifyListeners();
    } catch (e) {
      if (_isAuthError(e)) {
        await logout();
      }
      // If network error, stay with cached data
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _error = null;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
