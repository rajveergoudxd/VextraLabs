import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:acms_app/core/config.dart';

/// Message types for WebSocket communication
enum WSMessageType { message, readReceipt, typing, onlineStatus }

/// WebSocket service for real-time chat functionality
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final _storage = const FlutterSecureStorage();

  // Stream controllers for different event types
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _onlineStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onReadReceipt =>
      _readReceiptController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onOnlineStatus =>
      _onlineStatusController.stream;
  Stream<bool> get onConnectionStateChange => _connectionStateController.stream;

  int? _currentConversationId;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  bool get isConnected => _isConnected;
  int? get currentConversationId => _currentConversationId;

  /// Connect to a conversation's WebSocket
  Future<void> connect(int conversationId) async {
    // Disconnect from previous conversation if any
    if (_currentConversationId != null &&
        _currentConversationId != conversationId) {
      await disconnect();
    }

    if (_isConnected && _currentConversationId == conversationId) {
      return; // Already connected to this conversation
    }

    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint('WebSocket: No access token available');
      return;
    }

    // Build WebSocket URL
    final wsBaseUrl = Config.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final wsUrl = '$wsBaseUrl/ws/chat/$conversationId?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _currentConversationId = conversationId;

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
      debugPrint('WebSocket: Connected to conversation $conversationId');
    } catch (e) {
      debugPrint('WebSocket: Connection error: $e');
      _scheduleReconnect(conversationId);
    }
  }

  /// Disconnect from current conversation
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _currentConversationId = null;
    _connectionStateController.add(false);
    debugPrint('WebSocket: Disconnected');
  }

  /// Send a chat message
  void sendMessage({
    required String content,
    String messageType = 'text',
    String? mediaUrl,
  }) {
    if (!_isConnected || _channel == null) {
      debugPrint('WebSocket: Cannot send message - not connected');
      return;
    }

    final payload = {
      'type': 'message',
      'data': {
        'content': content,
        'message_type': messageType,
        if (mediaUrl != null) 'media_url': mediaUrl,
      },
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  /// Send read receipt for messages
  void sendReadReceipt(List<int> messageIds) {
    if (!_isConnected || _channel == null) return;

    final payload = {
      'type': 'read_receipt',
      'data': {'message_ids': messageIds},
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  /// Send typing indicator
  void sendTypingIndicator(bool isTyping) {
    if (!_isConnected || _channel == null) return;

    final payload = {
      'type': 'typing',
      'data': {'is_typing': isTyping},
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);
      final type = message['type'] as String?;
      final eventData = message['data'] as Map<String, dynamic>? ?? {};

      switch (type) {
        case 'message':
          _messageController.add(eventData);
          break;
        case 'read_receipt':
          _readReceiptController.add(eventData);
          break;
        case 'typing':
          _typingController.add(eventData);
          break;
        case 'online_status':
          _onlineStatusController.add(eventData);
          break;
        default:
          debugPrint('WebSocket: Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('WebSocket: Error parsing message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket: Error: $error');
    _isConnected = false;
    _connectionStateController.add(false);

    if (_currentConversationId != null) {
      _scheduleReconnect(_currentConversationId!);
    }
  }

  void _handleDone() {
    debugPrint('WebSocket: Connection closed');
    _isConnected = false;
    _connectionStateController.add(false);

    if (_currentConversationId != null) {
      _scheduleReconnect(_currentConversationId!);
    }
  }

  void _scheduleReconnect(int conversationId) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnect attempts reached');
      return;
    }

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delay = Duration(seconds: 1 << _reconnectAttempts);
    _reconnectAttempts++;

    debugPrint(
      'WebSocket: Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect(conversationId);
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _readReceiptController.close();
    _typingController.close();
    _onlineStatusController.close();
    _connectionStateController.close();
  }
}
