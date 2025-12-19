import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:acms_app/services/auth_service.dart';
import 'package:acms_app/services/api_client.dart';

class User {
  final int id;
  final String email;
  final String fullName;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _init();
    ApiClient().onLogout.listen((_) => logout());
  }

  Future<void> _init() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        await _fetchUser();
      } catch (e) {
        await logout();
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _fetchUser() async {
    try {
      final userData = await _authService.getMe();
      _user = User.fromJson(userData);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await _authService.login(email, password);
      final token = data['access_token'];
      await _storage.write(key: 'access_token', value: token);
      await _fetchUser();
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
      // Auto login after signup
      return await login(email, password);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    _user = null;
    notifyListeners();
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
