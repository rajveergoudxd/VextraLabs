import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:acms_app/services/chat_service.dart';
import 'package:acms_app/services/websocket_service.dart';

/// Model for a chat message
class ChatMessage {
  final int id;
  final int conversationId;
  final int? senderId;
  final String? senderUsername;
  final String? senderFullName;
  final String? senderProfilePicture;
  final String? content;
  final String messageType; // text, image, video
  final String? mediaUrl;
  final DateTime createdAt;
  bool isRead;
  DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    this.senderId,
    this.senderUsername,
    this.senderFullName,
    this.senderProfilePicture,
    this.content,
    required this.messageType,
    this.mediaUrl,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      senderUsername: sender?['username'],
      senderFullName: sender?['full_name'],
      senderProfilePicture: sender?['profile_picture'],
      content: json['content'],
      messageType: json['message_type'] ?? 'text',
      mediaUrl: json['media_url'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }
}

/// Model for a conversation participant
class ConversationParticipant {
  final int id;
  final String? username;
  final String? fullName;
  final String? profilePicture;
  final DateTime? lastReadAt;

  ConversationParticipant({
    required this.id,
    this.username,
    this.fullName,
    this.profilePicture,
    this.lastReadAt,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      profilePicture: json['profile_picture'],
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'])
          : null,
    );
  }
}

/// Model for a conversation
class Conversation {
  final int id;
  final List<ConversationParticipant> participants;
  ChatMessage? lastMessage;
  DateTime? lastMessageAt;
  int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      participants: (json['participants'] as List)
          .map((p) => ConversationParticipant.fromJson(p))
          .toList(),
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Get the other participant (for 1:1 chats)
  ConversationParticipant? getOtherParticipant(int currentUserId) {
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }
}

/// Provider for chat functionality
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final WebSocketService _wsService = WebSocketService();

  // Conversations list state
  List<Conversation> _conversations = [];
  bool _isLoadingConversations = false;
  String? _conversationsError;

  // Current chat state
  int? _currentConversationId;
  List<ChatMessage> _messages = [];
  bool _isLoadingMessages = false;
  String? _messagesError;

  // Typing state
  final Map<int, bool> _typingUsers = {}; // userId -> isTyping

  // Online status
  final Set<int> _onlineUsers = {};

  // Sending state
  bool _isSending = false;

  // Subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _onlineSubscription;

  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get conversationsError => _conversationsError;

  int? get currentConversationId => _currentConversationId;
  List<ChatMessage> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get messagesError => _messagesError;

  Map<int, bool> get typingUsers => _typingUsers;
  Set<int> get onlineUsers => _onlineUsers;
  bool get isSending => _isSending;
  bool get isConnected => _wsService.isConnected;

  int get totalUnreadCount =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  ChatProvider() {
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    _messageSubscription = _wsService.onMessage.listen(_handleNewMessage);
    _readReceiptSubscription = _wsService.onReadReceipt.listen(
      _handleReadReceipt,
    );
    _typingSubscription = _wsService.onTyping.listen(_handleTyping);
    _onlineSubscription = _wsService.onOnlineStatus.listen(_handleOnlineStatus);
  }

  /// Load all conversations for current user
  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    _conversationsError = null;
    notifyListeners();

    try {
      final response = await _chatService.getConversations();
      _conversations = (response['conversations'] as List)
          .map((json) => Conversation.fromJson(json))
          .toList();
    } catch (e) {
      _conversationsError = 'Failed to load conversations';
      debugPrint('Load conversations error: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  /// Open a conversation (creates if doesn't exist)
  Future<Conversation?> openConversationWithUser(int userId) async {
    try {
      final response = await _chatService.getOrCreateConversation(userId);
      final conversation = Conversation.fromJson(response);

      // Add to list if not already there
      final existingIndex = _conversations.indexWhere(
        (c) => c.id == conversation.id,
      );
      if (existingIndex == -1) {
        _conversations.insert(0, conversation);
        notifyListeners();
      }

      return conversation;
    } catch (e) {
      debugPrint('Open conversation error: $e');
      return null;
    }
  }

  /// Enter a chat (load messages and connect WebSocket)
  Future<void> enterChat(int conversationId) async {
    _currentConversationId = conversationId;
    _messages = [];
    _isLoadingMessages = true;
    _messagesError = null;
    notifyListeners();

    try {
      // Load messages
      final response = await _chatService.getConversationDetail(conversationId);
      _messages = (response['messages'] as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();

      // Connect WebSocket
      await _wsService.connect(conversationId);

      // Mark as read
      final conversationIndex = _conversations.indexWhere(
        (c) => c.id == conversationId,
      );
      if (conversationIndex != -1) {
        _conversations[conversationIndex].unreadCount = 0;
      }
    } catch (e) {
      _messagesError = 'Failed to load messages';
      debugPrint('Enter chat error: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Leave current chat
  Future<void> leaveChat() async {
    await _wsService.disconnect();
    _currentConversationId = null;
    _messages = [];
    _typingUsers.clear();
    notifyListeners();
  }

  /// Send a text message
  Future<bool> sendMessage(String content) async {
    if (_currentConversationId == null || content.trim().isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      // Send via WebSocket for real-time delivery
      _wsService.sendMessage(content: content);
      return true;
    } catch (e) {
      debugPrint('Send message error: $e');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Send a media message
  Future<bool> sendMediaMessage(File file, {String? caption}) async {
    if (_currentConversationId == null) return false;

    _isSending = true;
    notifyListeners();

    try {
      // Upload file first
      final mediaUrl = await _chatService.uploadMedia(file);
      if (mediaUrl == null) {
        throw Exception('Failed to upload media');
      }

      // Determine message type
      final extension = file.path.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'avi', 'webm'].contains(extension);
      final messageType = isVideo ? 'video' : 'image';

      // Send via WebSocket
      _wsService.sendMessage(
        content: caption ?? '',
        messageType: messageType,
        mediaUrl: mediaUrl,
      );

      return true;
    } catch (e) {
      debugPrint('Send media error: $e');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Send typing indicator
  void sendTyping(bool isTyping) {
    _wsService.sendTypingIndicator(isTyping);
  }

  /// Mark messages as read
  void markMessagesAsRead(List<int> messageIds) {
    if (messageIds.isEmpty) return;
    _wsService.sendReadReceipt(messageIds);
  }

  // WebSocket handlers
  void _handleNewMessage(Map<String, dynamic> data) {
    final message = ChatMessage.fromJson(data);

    // Add to current chat if we're in this conversation
    if (_currentConversationId == message.conversationId) {
      _messages.add(message);
      notifyListeners();
    }

    // Update conversation in list
    _updateConversationWithMessage(message);
  }

  void _handleReadReceipt(Map<String, dynamic> data) {
    final messageIds = (data['message_ids'] as List).cast<int>();
    final readAt = DateTime.parse(data['read_at']);

    for (final message in _messages) {
      if (messageIds.contains(message.id)) {
        message.isRead = true;
        message.readAt = readAt;
      }
    }
    notifyListeners();
  }

  void _handleTyping(Map<String, dynamic> data) {
    final userId = data['user_id'] as int;
    final isTyping = data['is_typing'] as bool;

    _typingUsers[userId] = isTyping;
    notifyListeners();

    // Auto-clear typing after 5 seconds
    if (isTyping) {
      Future.delayed(const Duration(seconds: 5), () {
        if (_typingUsers[userId] == true) {
          _typingUsers[userId] = false;
          notifyListeners();
        }
      });
    }
  }

  void _handleOnlineStatus(Map<String, dynamic> data) {
    final userId = data['user_id'] as int;
    final isOnline = data['is_online'] as bool;

    if (isOnline) {
      _onlineUsers.add(userId);
    } else {
      _onlineUsers.remove(userId);
    }
    notifyListeners();
  }

  void _updateConversationWithMessage(ChatMessage message) {
    final index = _conversations.indexWhere(
      (c) => c.id == message.conversationId,
    );

    if (index != -1) {
      _conversations[index].lastMessage = message;
      _conversations[index].lastMessageAt = message.createdAt;

      // Increment unread if not in this chat
      if (_currentConversationId != message.conversationId) {
        _conversations[index].unreadCount++;
      }

      // Move to top
      final conversation = _conversations.removeAt(index);
      _conversations.insert(0, conversation);

      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _typingSubscription?.cancel();
    _onlineSubscription?.cancel();
    _wsService.disconnect();
    super.dispose();
  }
}
