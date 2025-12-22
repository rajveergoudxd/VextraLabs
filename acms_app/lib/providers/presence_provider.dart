import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:acms_app/services/presence_service.dart';

/// Provider for managing online user presence across the app
class PresenceProvider extends ChangeNotifier {
  final PresenceService _presenceService = PresenceService();

  List<OnlineUser> _onlineFollowing = [];
  final Set<int> _onlineUserIds = {};
  bool _isConnected = false;
  bool _isLoading = false;

  // Stream subscriptions
  StreamSubscription? _presenceChangeSubscription;
  StreamSubscription? _onlineListSubscription;
  StreamSubscription? _connectionSubscription;

  List<OnlineUser> get onlineFollowing => _onlineFollowing;
  Set<int> get onlineUserIds => _onlineUserIds;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;

  /// Initialize presence tracking - call on app startup
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Setup listeners
    _presenceChangeSubscription = _presenceService.onPresenceChange.listen(
      _handlePresenceChange,
    );
    _onlineListSubscription = _presenceService.onOnlineListUpdate.listen(
      _handleOnlineListUpdate,
    );
    _connectionSubscription = _presenceService.onConnectionStateChange.listen(
      _handleConnectionChange,
    );

    // Connect to WebSocket
    await _presenceService.connect();

    // Also fetch via REST as fallback
    await loadOnlineFollowing();

    _isLoading = false;
    notifyListeners();
  }

  /// Load online following users via REST API
  Future<void> loadOnlineFollowing() async {
    try {
      final users = await _presenceService.getOnlineFollowing();
      _onlineFollowing = users;
      _onlineUserIds.clear();
      for (final user in users) {
        _onlineUserIds.add(user.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('PresenceProvider: Error loading online following: $e');
    }
  }

  /// Check if a specific user is online
  bool isUserOnline(int userId) {
    return _onlineUserIds.contains(userId);
  }

  void _handlePresenceChange(Map<String, dynamic> data) {
    final userId = data['user_id'] as int;
    final isOnline = data['is_online'] as bool;

    if (isOnline) {
      // User came online - add to list if not already there
      if (!_onlineUserIds.contains(userId)) {
        _onlineUserIds.add(userId);
        final user = OnlineUser(
          id: userId,
          username: data['username'],
          fullName: data['full_name'],
          profilePicture: data['profile_picture'],
        );
        _onlineFollowing.insert(0, user);
        notifyListeners();
      }
    } else {
      // User went offline - remove from list
      if (_onlineUserIds.contains(userId)) {
        _onlineUserIds.remove(userId);
        _onlineFollowing.removeWhere((u) => u.id == userId);
        notifyListeners();
      }
    }
  }

  void _handleOnlineListUpdate(List<OnlineUser> users) {
    _onlineFollowing = users;
    _onlineUserIds.clear();
    for (final user in users) {
      _onlineUserIds.add(user.id);
    }
    notifyListeners();
  }

  void _handleConnectionChange(bool connected) {
    _isConnected = connected;
    notifyListeners();

    // Reload on reconnection
    if (connected) {
      loadOnlineFollowing();
    }
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    await _presenceService.disconnect();
    _onlineFollowing.clear();
    _onlineUserIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _presenceChangeSubscription?.cancel();
    _onlineListSubscription?.cancel();
    _connectionSubscription?.cancel();
    _presenceService.disconnect();
    super.dispose();
  }
}
