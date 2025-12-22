import 'package:flutter/material.dart';
import 'package:acms_app/services/oauth_service.dart';

/// Provider for managing social platform connections
class SocialConnectionsProvider extends ChangeNotifier {
  final OAuthService _oauthService = OAuthService();

  List<SocialConnection> _connections = [];
  bool _isLoading = false;
  String? _error;

  List<SocialConnection> get connections => _connections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Check if a platform is connected
  bool isConnected(String platform) {
    return _connections.any((c) => c.platform == platform && c.isTokenValid);
  }

  /// Get connection for a specific platform
  SocialConnection? getConnection(String platform) {
    try {
      return _connections.firstWhere((c) => c.platform == platform);
    } catch (e) {
      return null;
    }
  }

  /// Load all connections from backend
  Future<void> loadConnections() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _connections = await _oauthService.getConnections();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get OAuth authorization URL
  Future<OAuthAuthorizeResponse?> getAuthorizationUrl(String platform) async {
    try {
      return await _oauthService.getAuthorizationUrl(platform);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Handle OAuth callback
  Future<bool> handleCallback(
    String platform,
    String code,
    String state,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _oauthService.handleCallback(platform, code, state);
      if (success) {
        await loadConnections(); // Refresh connections
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Disconnect a platform
  Future<bool> disconnect(String platform) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _oauthService.disconnect(platform);
      if (success) {
        _connections.removeWhere((c) => c.platform == platform);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Publish content to platforms
  Future<PublishResult?> publish({
    required List<String> platforms,
    required String content,
    List<String>? mediaUrls,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _oauthService.publish(
        platforms: platforms,
        content: content,
        mediaUrls: mediaUrls,
      );
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear state (for logout)
  void reset() {
    _connections = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
