import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:acms_app/core/database/database_service.dart';
import 'package:acms_app/core/database/isar_schemas.dart';
import 'package:acms_app/services/post_service.dart';
import 'package:acms_app/services/sync_service.dart';

/// Model for a cached post (simplified from API response)
class CachedPost {
  final int id;
  final String? content;
  final int authorId;
  final String? authorUsername;
  final String? authorFullName;
  final String? authorProfilePicture;
  final List<String> mediaUrls;
  final List<String> platforms;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;
  final String status;
  final String? shareToken;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CachedPost({
    required this.id,
    this.content,
    required this.authorId,
    this.authorUsername,
    this.authorFullName,
    this.authorProfilePicture,
    this.mediaUrls = const [],
    this.platforms = const [],
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isSaved,
    required this.status,
    this.shareToken,
    required this.createdAt,
    this.updatedAt,
  });

  factory CachedPost.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return CachedPost(
      id: json['id'],
      content: json['content'],
      authorId: author?['id'] ?? json['author_id'] ?? 0,
      authorUsername: author?['username'],
      authorFullName: author?['full_name'],
      authorProfilePicture: author?['profile_picture'],
      mediaUrls: (json['media_urls'] as List?)?.cast<String>() ?? [],
      platforms: (json['platforms'] as List?)?.cast<String>() ?? [],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
      status: json['status'] ?? 'published',
      shareToken: json['share_token'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': {
        'id': authorId,
        'username': authorUsername,
        'full_name': authorFullName,
        'profile_picture': authorProfilePicture,
      },
      'media_urls': mediaUrls,
      'platforms': platforms,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'is_saved': isSaved,
      'status': status,
      'share_token': shareToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Repository for post/feed data implementing cache-first pattern.
class PostRepository {
  final PostService _remoteService = PostService();
  final SyncService _syncService = SyncService.instance;

  /// Get feed posts with cache-first strategy.
  Stream<List<CachedPost>> getFeedStream({int page = 1, int size = 20}) async* {
    if (!DatabaseService.isInitialized) {
      final response = await _remoteService.getFeed(page: page, size: size);
      yield _parsePosts(response);
      return;
    }

    final db = DatabaseService.instance;

    // Step 1: Return cached data for first page
    if (page == 1) {
      final cachedEntities = await db.getFeedPosts(limit: size);
      if (cachedEntities.isNotEmpty) {
        yield _entitiesToPosts(cachedEntities);
      }
    }

    // Step 2: Fetch from server if online
    if (_syncService.isOnline) {
      try {
        final response = await _remoteService.getFeed(page: page, size: size);
        final posts = _parsePosts(response);

        if (page == 1) {
          await _cacheFeedPosts(posts);
        }

        yield posts;
      } catch (e) {
        debugPrint('PostRepository: Error fetching feed: $e');
      }
    }
  }

  /// Get feed once with pagination support.
  Future<Map<String, dynamic>> getFeed({
    int page = 1,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    if (!DatabaseService.isInitialized) {
      return await _remoteService.getFeed(page: page, size: size);
    }

    final db = DatabaseService.instance;

    // Check cache freshness for first page
    if (page == 1 && !forceRefresh) {
      final isStale = await db.isCacheStale(
        'feed',
        DatabaseService.feedCacheExpiry,
      );

      if (!isStale) {
        final cachedEntities = await db.getFeedPosts(limit: size);
        if (cachedEntities.isNotEmpty) {
          return {
            'items': _entitiesToPosts(
              cachedEntities,
            ).map((p) => p.toJson()).toList(),
            'page': 1,
            'size': size,
            'total': cachedEntities.length,
          };
        }
      }
    }

    // Fetch from server
    if (_syncService.isOnline) {
      try {
        final response = await _remoteService.getFeed(page: page, size: size);

        if (page == 1) {
          final posts = _parsePosts(response);
          await _cacheFeedPosts(posts);
        }

        return response;
      } catch (e) {
        debugPrint('PostRepository: Error fetching: $e');
      }
    }

    // Return cached data as fallback
    if (page == 1) {
      final cachedEntities = await db.getFeedPosts(limit: size);
      return {
        'items': _entitiesToPosts(
          cachedEntities,
        ).map((p) => p.toJson()).toList(),
        'page': 1,
        'size': size,
        'total': cachedEntities.length,
      };
    }

    return {'items': [], 'page': page, 'size': size, 'total': 0};
  }

  /// Get user's own posts with caching.
  Future<Map<String, dynamic>> getMyPosts({
    int page = 1,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    if (!DatabaseService.isInitialized) {
      return await _remoteService.getMyPosts(page: page, size: size);
    }

    final db = DatabaseService.instance;

    // Check cache for first page
    if (page == 1 && !forceRefresh) {
      final isStale = await db.isCacheStale(
        'my_posts',
        DatabaseService.feedCacheExpiry,
      );

      if (!isStale) {
        final cachedEntities = await db.getOwnPosts(limit: size);
        if (cachedEntities.isNotEmpty) {
          return {
            'items': _entitiesToPosts(
              cachedEntities,
            ).map((p) => p.toJson()).toList(),
            'page': 1,
            'size': size,
            'total': cachedEntities.length,
          };
        }
      }
    }

    // Fetch from server
    if (_syncService.isOnline) {
      try {
        final response = await _remoteService.getMyPosts(
          page: page,
          size: size,
        );

        if (page == 1) {
          final posts = _parsePosts(response);
          await _cacheOwnPosts(posts);
        }

        return response;
      } catch (e) {
        debugPrint('PostRepository: Error fetching my posts: $e');
      }
    }

    // Return cached data
    if (page == 1) {
      final cachedEntities = await db.getOwnPosts(limit: size);
      return {
        'items': _entitiesToPosts(
          cachedEntities,
        ).map((p) => p.toJson()).toList(),
        'page': 1,
        'size': size,
        'total': cachedEntities.length,
      };
    }

    return {'items': [], 'page': page, 'size': size, 'total': 0};
  }

  /// Toggle like with optimistic update.
  Future<Map<String, dynamic>> toggleLike(int postId) async {
    // If online, do it directly
    if (_syncService.isOnline) {
      final response = await _remoteService.toggleLike(postId);

      // Update local cache
      if (DatabaseService.isInitialized) {
        await DatabaseService.instance.updatePostLike(
          postId,
          response['is_liked'],
          response['likes_count'],
        );
      }

      return response;
    }

    // Queue for later
    await _syncService.queueOperation(
      operationType: 'toggle_like',
      payload: {'post_id': postId},
    );

    // Return optimistic response
    return {
      'is_liked': true, // Assume toggling to liked
      'likes_count': 0, // Unknown
      'message': 'Will sync when online',
    };
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  List<CachedPost> _parsePosts(Map<String, dynamic> response) {
    final items = response['items'] as List? ?? [];
    return items.map((json) => CachedPost.fromJson(json)).toList();
  }

  Future<void> _cacheFeedPosts(List<CachedPost> posts) async {
    final db = DatabaseService.instance;

    final entities = <PostEntity>[];
    for (int i = 0; i < posts.length; i++) {
      entities.add(_postToEntity(posts[i], feedPosition: i, isOwnPost: false));
    }

    await db.savePosts(entities);

    await db.updateCacheMetadata(
      CacheMetadataEntity()
        ..cacheKey = 'feed'
        ..lastSyncAt = DateTime.now()
        ..isSyncing = false,
    );
  }

  Future<void> _cacheOwnPosts(List<CachedPost> posts) async {
    final db = DatabaseService.instance;

    final entities = <PostEntity>[];
    for (int i = 0; i < posts.length; i++) {
      entities.add(_postToEntity(posts[i], feedPosition: i, isOwnPost: true));
    }

    await db.savePosts(entities);

    await db.updateCacheMetadata(
      CacheMetadataEntity()
        ..cacheKey = 'my_posts'
        ..lastSyncAt = DateTime.now()
        ..isSyncing = false,
    );
  }

  PostEntity _postToEntity(
    CachedPost post, {
    required int feedPosition,
    required bool isOwnPost,
  }) {
    return PostEntity()
      ..remoteId = post.id
      ..content = post.content
      ..authorId = post.authorId
      ..authorUsername = post.authorUsername
      ..authorFullName = post.authorFullName
      ..authorProfilePicture = post.authorProfilePicture
      ..mediaUrlsJson = jsonEncode(post.mediaUrls)
      ..platformsJson = jsonEncode(post.platforms)
      ..likesCount = post.likesCount
      ..commentsCount = post.commentsCount
      ..isLiked = post.isLiked
      ..isSaved = post.isSaved
      ..status = post.status
      ..shareToken = post.shareToken
      ..createdAt = post.createdAt
      ..updatedAt = post.updatedAt
      ..cachedAt = DateTime.now()
      ..feedPosition = feedPosition
      ..isOwnPost = isOwnPost;
  }

  List<CachedPost> _entitiesToPosts(List<PostEntity> entities) {
    return entities
        .map(
          (e) => CachedPost(
            id: e.remoteId,
            content: e.content,
            authorId: e.authorId,
            authorUsername: e.authorUsername,
            authorFullName: e.authorFullName,
            authorProfilePicture: e.authorProfilePicture,
            mediaUrls: e.mediaUrlsJson != null
                ? (jsonDecode(e.mediaUrlsJson!) as List).cast<String>()
                : [],
            platforms: e.platformsJson != null
                ? (jsonDecode(e.platformsJson!) as List).cast<String>()
                : [],
            likesCount: e.likesCount,
            commentsCount: e.commentsCount,
            isLiked: e.isLiked,
            isSaved: e.isSaved,
            status: e.status,
            shareToken: e.shareToken,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
          ),
        )
        .toList();
  }
}
