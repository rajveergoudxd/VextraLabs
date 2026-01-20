import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:acms_app/core/database/isar_schemas.dart';

/// Singleton service for managing the Isar database instance.
///
/// This service handles database initialization, schema migrations,
/// and provides access to Isar collections throughout the app.
class DatabaseService {
  static DatabaseService? _instance;
  static Isar? _isar;

  // Cache configuration constants
  static const int maxMessagesPerConversation = 100;
  static const int maxNotifications = 50;
  static const int maxFeedPosts = 50;
  static const Duration messageCacheExpiry = Duration(hours: 1);
  static const Duration feedCacheExpiry = Duration(minutes: 30);
  static const Duration notificationCacheExpiry = Duration(minutes: 30);

  DatabaseService._();

  /// Get the singleton instance of DatabaseService.
  /// Must call [initialize] before accessing this.
  static DatabaseService get instance {
    if (_instance == null) {
      throw StateError(
        'DatabaseService not initialized. Call DatabaseService.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initialize the database. Should be called once at app startup.
  static Future<DatabaseService> initialize() async {
    if (_instance != null) {
      return _instance!;
    }

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        ConversationEntitySchema,
        ConversationParticipantEntitySchema,
        MessageEntitySchema,
        NotificationEntitySchema,
        PostEntitySchema,
        DraftPostEntitySchema,
        SyncQueueEntitySchema,
        CacheMetadataEntitySchema,
      ],
      directory: dir.path,
      name: 'acms_offline_db',
    );

    _instance = DatabaseService._();
    debugPrint('DatabaseService: Isar database initialized');

    return _instance!;
  }

  /// Get the Isar instance.
  Isar get isar {
    if (_isar == null) {
      throw StateError('Database not initialized');
    }
    return _isar!;
  }

  /// Check if the database is initialized.
  static bool get isInitialized => _isar != null;

  // ===========================================================================
  // CONVERSATIONS
  // ===========================================================================

  /// Get all cached conversations sorted by last message time.
  Future<List<ConversationEntity>> getConversations() async {
    return isar.conversationEntitys.where().sortByLastMessageAtDesc().findAll();
  }

  /// Get a single conversation by remote ID.
  Future<ConversationEntity?> getConversation(int remoteId) async {
    return isar.conversationEntitys
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();
  }

  /// Save or update a conversation.
  Future<void> saveConversation(ConversationEntity conversation) async {
    await isar.writeTxn(() async {
      await isar.conversationEntitys.put(conversation);
    });
  }

  /// Save multiple conversations.
  Future<void> saveConversations(List<ConversationEntity> conversations) async {
    await isar.writeTxn(() async {
      await isar.conversationEntitys.putAll(conversations);
    });
  }

  /// Get participants for a conversation.
  Future<List<ConversationParticipantEntity>> getParticipants(
    int conversationRemoteId,
  ) async {
    return isar.conversationParticipantEntitys
        .filter()
        .conversationRemoteIdEqualTo(conversationRemoteId)
        .findAll();
  }

  /// Save participants.
  Future<void> saveParticipants(
    List<ConversationParticipantEntity> participants,
  ) async {
    await isar.writeTxn(() async {
      await isar.conversationParticipantEntitys.putAll(participants);
    });
  }

  // ===========================================================================
  // MESSAGES
  // ===========================================================================

  /// Get messages for a conversation, with cache limit.
  Future<List<MessageEntity>> getMessages(
    int conversationRemoteId, {
    int limit = maxMessagesPerConversation,
  }) async {
    return isar.messageEntitys
        .filter()
        .conversationRemoteIdEqualTo(conversationRemoteId)
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
  }

  /// Get pending messages that need to be synced.
  Future<List<MessageEntity>> getPendingMessages() async {
    return isar.messageEntitys
        .filter()
        .syncStatusEqualTo(SyncStatus.pending)
        .findAll();
  }

  /// Save or update a message.
  Future<void> saveMessage(MessageEntity message) async {
    await isar.writeTxn(() async {
      await isar.messageEntitys.put(message);
    });
  }

  /// Save multiple messages.
  Future<void> saveMessages(List<MessageEntity> messages) async {
    await isar.writeTxn(() async {
      await isar.messageEntitys.putAll(messages);
    });
  }

  /// Update message sync status.
  Future<void> updateMessageSyncStatus(
    int localId,
    SyncStatus status, {
    int? remoteId,
  }) async {
    await isar.writeTxn(() async {
      final message = await isar.messageEntitys.get(localId);
      if (message != null) {
        message.syncStatus = status;
        if (remoteId != null) {
          message.remoteId = remoteId;
        }
        await isar.messageEntitys.put(message);
      }
    });
  }

  /// Trim old messages to keep cache size manageable.
  Future<void> trimMessages(int conversationRemoteId) async {
    final messages = await isar.messageEntitys
        .filter()
        .conversationRemoteIdEqualTo(conversationRemoteId)
        .sortByCreatedAtDesc()
        .findAll();

    if (messages.length > maxMessagesPerConversation) {
      final toDelete = messages.skip(maxMessagesPerConversation).toList();
      await isar.writeTxn(() async {
        await isar.messageEntitys.deleteAll(toDelete.map((m) => m.id).toList());
      });
    }
  }

  /// Mark messages as read locally by their remote IDs.
  Future<void> markMessagesRead(
    int conversationRemoteId,
    List<int> messageRemoteIds,
  ) async {
    final now = DateTime.now();
    await isar.writeTxn(() async {
      for (final remoteId in messageRemoteIds) {
        final message = await isar.messageEntitys
            .filter()
            .remoteIdEqualTo(remoteId)
            .conversationRemoteIdEqualTo(conversationRemoteId)
            .findFirst();
        if (message != null && !message.isRead) {
          message.isRead = true;
          message.readAt = now;
          await isar.messageEntitys.put(message);
        }
      }
    });
  }

  /// Mark all messages in a conversation as read locally.
  Future<void> markConversationMessagesRead(int conversationRemoteId) async {
    final now = DateTime.now();
    await isar.writeTxn(() async {
      final messages = await isar.messageEntitys
          .filter()
          .conversationRemoteIdEqualTo(conversationRemoteId)
          .isReadEqualTo(false)
          .findAll();

      for (final message in messages) {
        message.isRead = true;
        message.readAt = now;
        await isar.messageEntitys.put(message);
      }

      // Also update conversation unread count
      final conversation = await isar.conversationEntitys
          .filter()
          .remoteIdEqualTo(conversationRemoteId)
          .findFirst();
      if (conversation != null) {
        conversation.unreadCount = 0;
        await isar.conversationEntitys.put(conversation);
      }
    });
  }

  // ===========================================================================
  // NOTIFICATIONS
  // ===========================================================================

  /// Get cached notifications.
  Future<List<NotificationEntity>> getNotifications({
    int limit = maxNotifications,
  }) async {
    return isar.notificationEntitys
        .where()
        .sortByCachedAtDesc()
        .limit(limit)
        .findAll();
  }

  /// Save notifications.
  Future<void> saveNotifications(List<NotificationEntity> notifications) async {
    await isar.writeTxn(() async {
      await isar.notificationEntitys.putAll(notifications);

      // Trim old notifications
      final all = await isar.notificationEntitys
          .where()
          .sortByCachedAtDesc()
          .findAll();
      if (all.length > maxNotifications) {
        final toDelete = all.skip(maxNotifications).toList();
        await isar.notificationEntitys.deleteAll(
          toDelete.map((n) => n.id).toList(),
        );
      }
    });
  }

  /// Mark notification as read locally.
  Future<void> markNotificationRead(int remoteId) async {
    await isar.writeTxn(() async {
      final notification = await isar.notificationEntitys
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();
      if (notification != null) {
        notification.isRead = true;
        await isar.notificationEntitys.put(notification);
      }
    });
  }

  // ===========================================================================
  // POSTS / FEED
  // ===========================================================================

  /// Get cached feed posts.
  Future<List<PostEntity>> getFeedPosts({int limit = maxFeedPosts}) async {
    return isar.postEntitys
        .filter()
        .isOwnPostEqualTo(false)
        .sortByFeedPositionDesc()
        .limit(limit)
        .findAll();
  }

  /// Get user's own posts.
  Future<List<PostEntity>> getOwnPosts({int limit = maxFeedPosts}) async {
    return isar.postEntitys
        .filter()
        .isOwnPostEqualTo(true)
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
  }

  /// Save posts.
  Future<void> savePosts(List<PostEntity> posts) async {
    await isar.writeTxn(() async {
      await isar.postEntitys.putAll(posts);
    });
  }

  /// Update post like status locally.
  Future<void> updatePostLike(
    int remoteId,
    bool isLiked,
    int likesCount,
  ) async {
    await isar.writeTxn(() async {
      final post = await isar.postEntitys
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();
      if (post != null) {
        post.isLiked = isLiked;
        post.likesCount = likesCount;
        await isar.postEntitys.put(post);
      }
    });
  }

  // ===========================================================================
  // DRAFT POSTS
  // ===========================================================================

  /// Get all draft posts.
  Future<List<DraftPostEntity>> getDrafts() async {
    return isar.draftPostEntitys.where().sortByUpdatedAtDesc().findAll();
  }

  /// Save a draft post.
  Future<int> saveDraft(DraftPostEntity draft) async {
    int id = 0;
    await isar.writeTxn(() async {
      id = await isar.draftPostEntitys.put(draft);
    });
    return id;
  }

  /// Delete a draft.
  Future<void> deleteDraft(int localId) async {
    await isar.writeTxn(() async {
      await isar.draftPostEntitys.delete(localId);
    });
  }

  // ===========================================================================
  // SYNC QUEUE
  // ===========================================================================

  /// Add an operation to the sync queue.
  Future<void> queueOperation(SyncQueueEntity operation) async {
    await isar.writeTxn(() async {
      await isar.syncQueueEntitys.put(operation);
    });
  }

  /// Get all pending operations.
  Future<List<SyncQueueEntity>> getPendingOperations() async {
    return isar.syncQueueEntitys.where().sortByQueuedAt().findAll();
  }

  /// Remove an operation from the queue.
  Future<void> removeOperation(int localId) async {
    await isar.writeTxn(() async {
      await isar.syncQueueEntitys.delete(localId);
    });
  }

  /// Update operation retry count.
  Future<void> updateOperationRetry(
    int localId, {
    required int retryCount,
    String? error,
  }) async {
    await isar.writeTxn(() async {
      final op = await isar.syncQueueEntitys.get(localId);
      if (op != null) {
        op.retryCount = retryCount;
        op.lastAttemptAt = DateTime.now();
        op.lastError = error;
        await isar.syncQueueEntitys.put(op);
      }
    });
  }

  // ===========================================================================
  // CACHE METADATA
  // ===========================================================================

  /// Get cache metadata for a key.
  Future<CacheMetadataEntity?> getCacheMetadata(String cacheKey) async {
    return isar.cacheMetadataEntitys
        .filter()
        .cacheKeyEqualTo(cacheKey)
        .findFirst();
  }

  /// Update cache metadata.
  Future<void> updateCacheMetadata(CacheMetadataEntity metadata) async {
    await isar.writeTxn(() async {
      await isar.cacheMetadataEntitys.put(metadata);
    });
  }

  /// Check if cache is stale based on expiry duration.
  Future<bool> isCacheStale(String cacheKey, Duration expiry) async {
    final metadata = await getCacheMetadata(cacheKey);
    if (metadata?.lastSyncAt == null) {
      return true;
    }
    return DateTime.now().difference(metadata!.lastSyncAt!) > expiry;
  }

  // ===========================================================================
  // CLEANUP
  // ===========================================================================

  /// Clear all data (call on logout).
  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.conversationEntitys.clear();
      await isar.conversationParticipantEntitys.clear();
      await isar.messageEntitys.clear();
      await isar.notificationEntitys.clear();
      await isar.postEntitys.clear();
      await isar.draftPostEntitys.clear();
      await isar.syncQueueEntitys.clear();
      await isar.cacheMetadataEntitys.clear();
    });
    debugPrint('DatabaseService: All cached data cleared');
  }

  /// Clear data for a specific user (for multi-account support if needed).
  Future<void> clearUserData() async {
    await clearAllData();
  }

  /// Close the database (call on app dispose).
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
    _instance = null;
  }
}
