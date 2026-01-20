import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:acms_app/core/database/database_service.dart';
import 'package:acms_app/core/database/isar_schemas.dart';
import 'package:acms_app/services/chat_service.dart';
import 'package:acms_app/services/sync_service.dart';
import 'package:acms_app/providers/chat_provider.dart';

/// Repository for chat data implementing cache-first pattern.
///
/// This repository abstracts the data source (local cache vs remote API)
/// and provides a unified interface for chat operations.
class ChatRepository {
  final ChatService _remoteService = ChatService();
  final SyncService _syncService = SyncService.instance;

  /// Get conversations with cache-first strategy.
  /// Returns cached data immediately, then syncs with server.
  Stream<List<Conversation>> getConversationsStream() async* {
    if (!DatabaseService.isInitialized) {
      // Fallback to remote only if DB not ready
      final response = await _remoteService.getConversations();
      yield _parseConversations(response);
      return;
    }

    final db = DatabaseService.instance;

    // Step 1: Return cached data immediately
    final cachedEntities = await db.getConversations();
    if (cachedEntities.isNotEmpty) {
      final conversations = await _entitiesToConversations(cachedEntities);
      yield conversations;
    }

    // Step 2: Fetch from server if online
    if (_syncService.isOnline) {
      try {
        final response = await _remoteService.getConversations();
        final conversations = _parseConversations(response);

        // Update cache
        await _cacheConversations(conversations);

        yield conversations;
      } catch (e) {
        debugPrint('ChatRepository: Error fetching conversations: $e');
        // Already yielded cached data, so just log the error
      }
    }
  }

  /// Get conversations once (for initial load or refresh).
  Future<List<Conversation>> getConversations({
    bool forceRefresh = false,
  }) async {
    if (!DatabaseService.isInitialized) {
      final response = await _remoteService.getConversations();
      return _parseConversations(response);
    }

    final db = DatabaseService.instance;

    // Check cache freshness
    final isStale = await db.isCacheStale(
      'conversations',
      DatabaseService.messageCacheExpiry,
    );

    if (!forceRefresh && !isStale) {
      final cachedEntities = await db.getConversations();
      if (cachedEntities.isNotEmpty) {
        return await _entitiesToConversations(cachedEntities);
      }
    }

    // Fetch from server
    if (_syncService.isOnline) {
      try {
        final response = await _remoteService.getConversations();
        final conversations = _parseConversations(response);
        await _cacheConversations(conversations);
        return conversations;
      } catch (e) {
        debugPrint('ChatRepository: Error fetching: $e');
        // Fall back to cache
      }
    }

    // Return cached data as fallback
    final cachedEntities = await db.getConversations();
    return await _entitiesToConversations(cachedEntities);
  }

  /// Get messages for a conversation with cache-first strategy.
  Stream<List<ChatMessage>> getMessagesStream(int conversationId) async* {
    if (!DatabaseService.isInitialized) {
      final messages = await _remoteService.getMessages(conversationId);
      yield messages.map((m) => ChatMessage.fromJson(m)).toList();
      return;
    }

    final db = DatabaseService.instance;

    // Step 1: Return cached messages immediately
    final cachedEntities = await db.getMessages(conversationId);
    if (cachedEntities.isNotEmpty) {
      yield _entitiesToMessages(cachedEntities);
    }

    // Step 2: Fetch from server if online
    if (_syncService.isOnline) {
      try {
        final response = await _remoteService.getMessages(conversationId);
        final messages = response.map((m) => ChatMessage.fromJson(m)).toList();

        // Update cache
        await _cacheMessages(conversationId, messages);

        yield messages;
      } catch (e) {
        debugPrint('ChatRepository: Error fetching messages: $e');
      }
    }
  }

  /// Get messages once.
  Future<List<ChatMessage>> getMessages(
    int conversationId, {
    bool forceRefresh = false,
  }) async {
    if (!DatabaseService.isInitialized) {
      final messages = await _remoteService.getMessages(conversationId);
      return messages.map((m) => ChatMessage.fromJson(m)).toList();
    }

    final db = DatabaseService.instance;

    // Check cache freshness
    final cacheKey = 'messages_$conversationId';
    final isStale = await db.isCacheStale(
      cacheKey,
      DatabaseService.messageCacheExpiry,
    );

    if (!forceRefresh && !isStale) {
      final cachedEntities = await db.getMessages(conversationId);
      if (cachedEntities.isNotEmpty) {
        return _entitiesToMessages(cachedEntities);
      }
    }

    // Fetch from server
    if (_syncService.isOnline) {
      try {
        final response = await _remoteService.getMessages(conversationId);
        final messages = response.map((m) => ChatMessage.fromJson(m)).toList();
        await _cacheMessages(conversationId, messages);
        return messages;
      } catch (e) {
        debugPrint('ChatRepository: Error fetching: $e');
      }
    }

    // Return cached data
    final cachedEntities = await db.getMessages(conversationId);
    return _entitiesToMessages(cachedEntities);
  }

  /// Send a message with offline support.
  /// Returns the local message immediately, syncs in background.
  Future<ChatMessage> sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    int? sharedPostId,
    required int senderId,
    String? senderUsername,
    String? senderFullName,
    String? senderProfilePicture,
  }) async {
    final now = DateTime.now();

    // Create local message immediately
    final localMessage = ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch, // Negative ID for pending
      conversationId: conversationId,
      senderId: senderId,
      senderUsername: senderUsername,
      senderFullName: senderFullName,
      senderProfilePicture: senderProfilePicture,
      content: content,
      messageType: messageType,
      mediaUrl: mediaUrl,
      createdAt: now,
      isRead: false,
    );

    // Cache locally with pending status
    if (DatabaseService.isInitialized) {
      final entity = _messageToEntity(localMessage, conversationId)
        ..syncStatus = SyncStatus.pending;
      await DatabaseService.instance.saveMessage(entity);
    }

    // If online, send immediately
    if (_syncService.isOnline) {
      try {
        Map<String, dynamic> response;

        if (messageType == 'text') {
          response = await _remoteService.sendTextMessage(
            conversationId,
            content,
          );
        } else if (messageType == 'post_share' && sharedPostId != null) {
          response = await _remoteService.sendPostShareMessage(
            conversationId,
            sharedPostId,
            caption: content,
          );
        } else {
          response = await _remoteService.sendMediaMessage(
            conversationId,
            mediaUrl!,
            messageType,
            caption: content,
          );
        }

        final serverMessage = ChatMessage.fromJson(response);

        // Update local cache with server response
        if (DatabaseService.isInitialized) {
          final entity = _messageToEntity(serverMessage, conversationId)
            ..syncStatus = SyncStatus.synced;
          await DatabaseService.instance.saveMessage(entity);
        }

        return serverMessage;
      } catch (e) {
        debugPrint('ChatRepository: Error sending message: $e');
        // Mark as failed and queue for retry
        if (DatabaseService.isInitialized) {
          await DatabaseService.instance.updateMessageSyncStatus(
            localMessage.id,
            SyncStatus.failed,
          );
        }
        rethrow;
      }
    } else {
      // Queue for later sync
      await _syncService.queueOperation(
        operationType: 'send_message',
        payload: {
          'conversation_id': conversationId,
          'content': content,
          'message_type': messageType,
          'media_url': mediaUrl,
          'shared_post_id': sharedPostId,
          'local_id': localMessage.id,
        },
      );

      return localMessage;
    }
  }

  /// Mark messages as read locally and sync.
  Future<void> markMessagesRead(
    int conversationId,
    List<int> messageIds,
  ) async {
    // Update local cache immediately for instant UI feedback
    if (DatabaseService.isInitialized) {
      if (messageIds.isEmpty) {
        // Mark all messages in conversation as read
        await DatabaseService.instance.markConversationMessagesRead(
          conversationId,
        );
      } else {
        // Mark specific messages as read
        await DatabaseService.instance.markMessagesRead(
          conversationId,
          messageIds,
        );
      }
    }

    // Sync with server
    if (_syncService.isOnline) {
      try {
        await _remoteService.markConversationRead(conversationId);
      } catch (e) {
        // Queue for later
        await _syncService.queueOperation(
          operationType: 'mark_read',
          payload: {
            'conversation_id': conversationId,
            'message_ids': messageIds,
          },
        );
      }
    } else {
      await _syncService.queueOperation(
        operationType: 'mark_read',
        payload: {'conversation_id': conversationId, 'message_ids': messageIds},
      );
    }
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  List<Conversation> _parseConversations(Map<String, dynamic> response) {
    return (response['conversations'] as List)
        .map((json) => Conversation.fromJson(json))
        .toList();
  }

  Future<void> _cacheConversations(List<Conversation> conversations) async {
    final db = DatabaseService.instance;
    final entities = <ConversationEntity>[];
    final allParticipants = <ConversationParticipantEntity>[];

    for (final conv in conversations) {
      entities.add(_conversationToEntity(conv));

      for (final p in conv.participants) {
        allParticipants.add(
          ConversationParticipantEntity()
            ..remoteUserId = p.id
            ..conversationRemoteId = conv.id
            ..username = p.username
            ..fullName = p.fullName
            ..profilePicture = p.profilePicture
            ..lastReadAt = p.lastReadAt,
        );
      }
    }

    await db.saveConversations(entities);
    await db.saveParticipants(allParticipants);

    // Update cache metadata
    await db.updateCacheMetadata(
      CacheMetadataEntity()
        ..cacheKey = 'conversations'
        ..lastSyncAt = DateTime.now()
        ..isSyncing = false,
    );
  }

  ConversationEntity _conversationToEntity(Conversation conv) {
    return ConversationEntity()
      ..remoteId = conv.id
      ..lastMessageContent = conv.lastMessage?.content
      ..lastMessageType = conv.lastMessage?.messageType
      ..lastMessageAt = conv.lastMessageAt
      ..unreadCount = conv.unreadCount
      ..createdAt = conv.createdAt
      ..updatedAt = conv.updatedAt
      ..cachedAt = DateTime.now();
  }

  Future<List<Conversation>> _entitiesToConversations(
    List<ConversationEntity> entities,
  ) async {
    final db = DatabaseService.instance;
    final conversations = <Conversation>[];

    for (final entity in entities) {
      final participantEntities = await db.getParticipants(entity.remoteId);

      final participants = participantEntities
          .map(
            (p) => ConversationParticipant(
              id: p.remoteUserId,
              username: p.username,
              fullName: p.fullName,
              profilePicture: p.profilePicture,
              lastReadAt: p.lastReadAt,
            ),
          )
          .toList();

      ChatMessage? lastMessage;
      if (entity.lastMessageContent != null) {
        lastMessage = ChatMessage(
          id: 0, // Placeholder
          conversationId: entity.remoteId,
          content: entity.lastMessageContent,
          messageType: entity.lastMessageType ?? 'text',
          createdAt: entity.lastMessageAt ?? entity.updatedAt,
        );
      }

      conversations.add(
        Conversation(
          id: entity.remoteId,
          participants: participants,
          lastMessage: lastMessage,
          lastMessageAt: entity.lastMessageAt,
          unreadCount: entity.unreadCount,
          createdAt: entity.createdAt,
          updatedAt: entity.updatedAt,
        ),
      );
    }

    return conversations;
  }

  Future<void> _cacheMessages(
    int conversationId,
    List<ChatMessage> messages,
  ) async {
    final db = DatabaseService.instance;

    final entities = messages
        .map((m) => _messageToEntity(m, conversationId))
        .toList();

    await db.saveMessages(entities);
    await db.trimMessages(conversationId);

    // Update cache metadata
    await db.updateCacheMetadata(
      CacheMetadataEntity()
        ..cacheKey = 'messages_$conversationId'
        ..lastSyncAt = DateTime.now()
        ..isSyncing = false,
    );
  }

  MessageEntity _messageToEntity(ChatMessage msg, int conversationId) {
    return MessageEntity()
      ..remoteId = msg.id
      ..conversationRemoteId = conversationId
      ..senderId = msg.senderId
      ..senderUsername = msg.senderUsername
      ..senderFullName = msg.senderFullName
      ..senderProfilePicture = msg.senderProfilePicture
      ..content = msg.content
      ..messageType = msg.messageType
      ..mediaUrl = msg.mediaUrl
      ..createdAt = msg.createdAt
      ..isRead = msg.isRead
      ..readAt = msg.readAt
      ..syncStatus = SyncStatus.synced
      ..cachedAt = DateTime.now();
  }

  List<ChatMessage> _entitiesToMessages(List<MessageEntity> entities) {
    return entities
        .map(
          (e) => ChatMessage(
            id: e.remoteId,
            conversationId: e.conversationRemoteId,
            senderId: e.senderId,
            senderUsername: e.senderUsername,
            senderFullName: e.senderFullName,
            senderProfilePicture: e.senderProfilePicture,
            content: e.content,
            messageType: e.messageType,
            mediaUrl: e.mediaUrl,
            createdAt: e.createdAt,
            isRead: e.isRead,
            readAt: e.readAt,
          ),
        )
        .toList();
  }
}
