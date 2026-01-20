import 'package:isar/isar.dart';

part 'isar_schemas.g.dart';

// ==============================================================================
// CONVERSATION ENTITIES
// ==============================================================================

/// Isar collection for caching conversations locally
@collection
class ConversationEntity {
  Id id = Isar.autoIncrement;

  /// Remote ID from the backend
  @Index(unique: true)
  late int remoteId;

  /// Last message content preview
  String? lastMessageContent;

  /// Type of last message (text, image, video, post_share)
  String? lastMessageType;

  /// Timestamp of last message
  DateTime? lastMessageAt;

  /// Number of unread messages
  late int unreadCount;

  /// When conversation was created
  late DateTime createdAt;

  /// When conversation was last updated
  late DateTime updatedAt;

  /// When this was cached locally (for cache invalidation)
  late DateTime cachedAt;

  /// Links to participants
  final participants = IsarLinks<ConversationParticipantEntity>();
}

/// Isar collection for conversation participants
@collection
class ConversationParticipantEntity {
  Id id = Isar.autoIncrement;

  /// Remote user ID
  @Index()
  late int remoteUserId;

  /// Conversation this participant belongs to
  @Index()
  late int conversationRemoteId;

  String? username;
  String? fullName;
  String? profilePicture;
  DateTime? lastReadAt;
}

// ==============================================================================
// MESSAGE ENTITIES
// ==============================================================================

/// Isar collection for caching chat messages locally
@collection
class MessageEntity {
  Id id = Isar.autoIncrement;

  /// Remote ID from the backend (-1 if pending sync)
  @Index()
  late int remoteId;

  /// Conversation this message belongs to
  @Index()
  late int conversationRemoteId;

  /// Sender user ID (null for system messages)
  int? senderId;

  /// Sender details cached for offline display
  String? senderUsername;
  String? senderFullName;
  String? senderProfilePicture;

  /// Message content
  String? content;

  /// Type: text, image, video, post_share
  late String messageType;

  /// Media URL if applicable
  String? mediaUrl;

  /// Shared post ID if messageType is post_share
  int? sharedPostId;

  /// When message was created
  late DateTime createdAt;

  /// Read status
  late bool isRead;
  DateTime? readAt;

  /// Sync status for offline queue
  @enumerated
  late SyncStatus syncStatus;

  /// When this was cached locally
  late DateTime cachedAt;
}

/// Sync status for offline operations
enum SyncStatus {
  synced, // Synced with server
  pending, // Waiting to be synced (created offline)
  failed, // Sync failed, needs retry
}

// ==============================================================================
// NOTIFICATION ENTITIES
// ==============================================================================

/// Isar collection for caching notifications locally
@collection
class NotificationEntity {
  Id id = Isar.autoIncrement;

  /// Remote ID from the backend
  @Index(unique: true)
  late int remoteId;

  /// Notification type (like, comment, follow, mention, system, etc.)
  late String type;

  /// Notification title
  late String title;

  /// Notification message/body
  late String message;

  /// Related entity ID (post ID, comment ID, etc.)
  int? relatedId;

  /// Related entity type
  String? relatedType;

  /// Image URL for content preview
  String? contentImageUrl;

  /// Read status
  late bool isRead;

  /// Relative time string (cached for display)
  late String timeAgo;

  /// Actor details (user who triggered the notification)
  int? actorId;
  String? actorUsername;
  String? actorFullName;
  String? actorProfilePicture;

  /// When this was cached locally
  late DateTime cachedAt;
}

// ==============================================================================
// POST/FEED ENTITIES
// ==============================================================================

/// Isar collection for caching feed posts locally
@collection
class PostEntity {
  Id id = Isar.autoIncrement;

  /// Remote ID from the backend
  @Index(unique: true)
  late int remoteId;

  /// Post content/caption
  String? content;

  /// Author details
  late int authorId;
  String? authorUsername;
  String? authorFullName;
  String? authorProfilePicture;

  /// Media URLs (stored as JSON string)
  String? mediaUrlsJson;

  /// Platforms this was posted to (stored as JSON string)
  String? platformsJson;

  /// Engagement counts
  late int likesCount;
  late int commentsCount;

  /// Current user's interaction status
  late bool isLiked;
  late bool isSaved;

  /// Post status
  late String status;

  /// Share token for deep links
  String? shareToken;

  /// Timestamps
  late DateTime createdAt;
  DateTime? updatedAt;

  /// When this was cached locally
  late DateTime cachedAt;

  /// Feed position for maintaining order
  @Index()
  late int feedPosition;

  /// Is this from user's own posts or general feed
  @Index()
  late bool isOwnPost;
}

// ==============================================================================
// DRAFT POST ENTITIES
// ==============================================================================

/// Isar collection for storing draft posts locally
@collection
class DraftPostEntity {
  Id id = Isar.autoIncrement;

  /// Remote draft ID (if saved to server, -1 if local only)
  late int remoteId;

  /// Draft content
  String? content;

  /// Draft title
  String? title;

  /// Local media paths (not yet uploaded)
  String? localMediaPathsJson;

  /// Uploaded media URLs (if any)
  String? mediaUrlsJson;

  /// Target platforms
  String? platformsJson;

  /// Sync status
  @enumerated
  late SyncStatus syncStatus;

  /// When draft was created
  late DateTime createdAt;

  /// When draft was last modified
  late DateTime updatedAt;
}

// ==============================================================================
// SYNC QUEUE ENTITIES
// ==============================================================================

/// Isar collection for queuing operations when offline
@collection
class SyncQueueEntity {
  Id id = Isar.autoIncrement;

  /// Type of operation (send_message, mark_read, etc.)
  late String operationType;

  /// Serialized operation data as JSON
  late String payloadJson;

  /// Number of retry attempts
  late int retryCount;

  /// Max retries before giving up
  late int maxRetries;

  /// When this was queued
  late DateTime queuedAt;

  /// Last attempt timestamp
  DateTime? lastAttemptAt;

  /// Error message from last failed attempt
  String? lastError;
}

// ==============================================================================
// CACHE METADATA
// ==============================================================================

/// Isar collection for tracking cache state
@collection
class CacheMetadataEntity {
  Id id = Isar.autoIncrement;

  /// Cache key (e.g., "conversations", "notifications", "feed")
  @Index(unique: true)
  late String cacheKey;

  /// When this cache was last fully synced
  DateTime? lastSyncAt;

  /// Is a sync currently in progress
  late bool isSyncing;

  /// Total count from server (for pagination awareness)
  int? serverTotalCount;
}
