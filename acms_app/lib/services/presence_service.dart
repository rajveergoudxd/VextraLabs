import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:acms_app/core/config.dart';
import 'package:acms_app/services/api_client.dart';

/// Model for an online user
class OnlineUser {
  final int id;
  final String? username;
  final String? fullName;
  final String? profilePicture;

  OnlineUser({
    required this.id,
    this.username,
    this.fullName,
    this.profilePicture,
  });

  factory OnlineUser.fromJson(Map<String, dynamic> json) {
    return OnlineUser(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      profilePicture: json['profile_picture'],
    );
  }
}

/// Service for global presence tracking via WebSocket
/// Manages online status of users the current user is following
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final ApiClient _apiClient = ApiClient();
  WebSocketChannel? _channel;
  final _storage = const FlutterSecureStorage();

  // Stream controllers for presence events
  final _presenceChangeController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onlineListController = StreamController<List<OnlineUser>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get onPresenceChange =>
      _presenceChangeController.stream;
  Stream<List<OnlineUser>> get onOnlineListUpdate =>
      _onlineListController.stream;
  Stream<bool> get onConnectionStateChange => _connectionStateController.stream;

  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  bool get isConnected => _isConnected;

  /// Connect to presence WebSocket for global online tracking
  Future<void> connect() async {
    if (_isConnected) return;

    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint('PresenceService: No access token available');
      return;
    }

    // Build WebSocket URL
    final wsBaseUrl = Config.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final wsUrl = '$wsBaseUrl/presence/ws?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);
      _startHeartbeat();
      debugPrint('PresenceService: Connected');
    } catch (e) {
      debugPrint('PresenceService: Connection error: $e');
      _scheduleReconnect();
    }
  }

  /// Disconnect from presence WebSocket
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _connectionStateController.add(false);
    debugPrint('PresenceService: Disconnected');
  }

  /// Fetch online following users via REST API (for initial load)
  Future<List<OnlineUser>> getOnlineFollowing() async {
    try {
      final response = await _apiClient.dio.get('/presence/following/online');
      final data = response.data;
      final users = (data['online_users'] as List)
          .map((json) => OnlineUser.fromJson(json))
          .toList();
      return users;
    } catch (e) {
      debugPrint('PresenceService: Error fetching online following: $e');
      return [];
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(),
    );
  }

  void _sendHeartbeat() {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'heartbeat'}));
    } catch (e) {
      debugPrint('PresenceService: Heartbeat error: $e');
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);
      final type = message['type'] as String?;
      final eventData = message['data'] as Map<String, dynamic>? ?? {};

      switch (type) {
        case 'initial_online_list':
          final users = (eventData['online_users'] as List)
              .map((json) => OnlineUser.fromJson(json))
              .toList();
          _onlineListController.add(users);
          break;
        case 'presence_change':
          _presenceChangeController.add(eventData);
          break;
        case 'heartbeat_ack':
          // Heartbeat acknowledged, connection is alive
          break;
        default:
          debugPrint('PresenceService: Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('PresenceService: Error parsing message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('PresenceService: Error: $error');
    _isConnected = false;
    _connectionStateController.add(false);
    _scheduleReconnect();
  }

  void _handleDone() {
    debugPrint('PresenceService: Connection closed');
    _isConnected = false;
    _connectionStateController.add(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('PresenceService: Max reconnect attempts reached');
      return;
    }

    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    final delay = Duration(seconds: 2 << _reconnectAttempts);
    _reconnectAttempts++;

    debugPrint(
      'PresenceService: Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => connect());
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _presenceChangeController.close();
    _onlineListController.close();
    _connectionStateController.close();
  }
}
