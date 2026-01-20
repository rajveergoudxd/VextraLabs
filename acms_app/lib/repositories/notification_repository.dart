import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:acms_app/core/database/database_service.dart';
import 'package:acms_app/core/database/isar_schemas.dart';
import 'package:acms_app/services/notification_service.dart';
import 'package:acms_app/services/sync_service.dart';
import 'package:acms_app/providers/notification_provider.dart';

/// Repository for notification data implementing cache-first pattern.
class NotificationRepository {
  final NotificationService _remoteService = NotificationService();
  final SyncService _syncService = SyncService.instance;

  /// Get notifications with cache-first strategy.
  Stream<List<NotificationItem>> getNotificationsStream({
    int limit = 50,
    String? typeFilter,
  }) async* {
    if (!DatabaseService.isInitialized) {
      final response = await _remoteService.getNotifications(
        skip: 0,
        limit: limit,
        type: typeFilter,
      );
      yield _parseNotifications(response);
      return;
    }

    final db = DatabaseService.instance;

    // Step 1: Return cached data immediately
    final cachedEntities = await db.getNotifications(limit: limit);
    if (cachedEntities.isNotEmpty) {
      yield _entitiesToNotifications(cachedEntities);
    }

    // Step 2: Fetch from server if online
    if (_syncService.isOnline) {
      try {
        final response = await _remoteService.getNotifications(
          skip: 0,
          limit: limit,
          type: typeFilter,
        );
        final notifications = _parseNotifications(response);

        await _cacheNotifications(notifications);

        yield notifications;
      } catch (e) {
        debugPrint('NotificationRepository: Error fetching: $e');
      }
    }
  }

  /// Get notifications once.
  Future<Map<String, dynamic>> getNotifications({
    int skip = 0,
    int limit = 50,
    String? typeFilter,
    bool forceRefresh = false,
  }) async {
    if (!DatabaseService.isInitialized) {
      return await _remoteService.getNotifications(
        skip: skip,
        limit: limit,
        type: typeFilter,
      );
    }

    final db = DatabaseService.instance;

    // Check cache freshness
    final isStale = await db.isCacheStale(
      'notifications',
      DatabaseService.notificationCacheExpiry,
    );

    if (!forceRefresh && !isStale && skip == 0) {
      final cachedEntities = await db.getNotifications(limit: limit);
      if (cachedEntities.isNotEmpty) {
        return {
          'notifications': _entitiesToNotifications(
            cachedEntities,
          ).map((n) => _notificationToJson(n)).toList(),
          'unread_count': cachedEntities.where((n) => !n.isRead).length,
          'has_more': cachedEntities.length == limit,
        };
      }
    }

    // Fetch from server
    if (_syncService.isOnline) {
      try {
        final response = await _remoteService.getNotifications(
          skip: skip,
          limit: limit,
          type: typeFilter,
        );

        if (skip == 0) {
          final notifications = _parseNotifications(response);
          await _cacheNotifications(notifications);
        }

        return response;
      } catch (e) {
        debugPrint('NotificationRepository: Error fetching: $e');
      }
    }

    // Return cached data as fallback
    final cachedEntities = await db.getNotifications(limit: limit);
    return {
      'notifications': _entitiesToNotifications(
        cachedEntities,
      ).map((n) => _notificationToJson(n)).toList(),
      'unread_count': cachedEntities.where((n) => !n.isRead).length,
      'has_more': false,
    };
  }

  /// Mark notification as read with local update.
  Future<void> markAsRead(int id) async {
    // Update locally first
    if (DatabaseService.isInitialized) {
      await DatabaseService.instance.markNotificationRead(id);
    }

    // Sync with server
    if (_syncService.isOnline) {
      try {
        await _remoteService.markAsRead(id);
      } catch (e) {
        await _syncService.queueOperation(
          operationType: 'mark_notification_read',
          payload: {'id': id},
        );
      }
    } else {
      await _syncService.queueOperation(
        operationType: 'mark_notification_read',
        payload: {'id': id},
      );
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    // This should sync immediately when online
    if (_syncService.isOnline) {
      await _remoteService.markAllAsRead();
    } else {
      await _syncService.queueOperation(
        operationType: 'mark_all_notifications_read',
        payload: {},
      );
    }
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  List<NotificationItem> _parseNotifications(Map<String, dynamic> response) {
    final List<dynamic> results = response['notifications'];
    return results.map((json) => NotificationItem.fromJson(json)).toList();
  }

  Future<void> _cacheNotifications(List<NotificationItem> notifications) async {
    final db = DatabaseService.instance;

    final entities = notifications
        .map((n) => _notificationToEntity(n))
        .toList();
    await db.saveNotifications(entities);

    await db.updateCacheMetadata(
      CacheMetadataEntity()
        ..cacheKey = 'notifications'
        ..lastSyncAt = DateTime.now()
        ..isSyncing = false,
    );
  }

  NotificationEntity _notificationToEntity(NotificationItem n) {
    return NotificationEntity()
      ..remoteId = n.id
      ..type = n.type
      ..title = n.title
      ..message = n.message
      ..relatedId = n.relatedId
      ..relatedType = n.relatedType
      ..contentImageUrl = n.contentImageUrl
      ..isRead = n.isRead
      ..timeAgo = n.timeAgo
      ..actorId = n.actor?.id
      ..actorUsername = n.actor?.username
      ..actorFullName = n.actor?.fullName
      ..actorProfilePicture = n.actor?.profilePicture
      ..cachedAt = DateTime.now();
  }

  List<NotificationItem> _entitiesToNotifications(
    List<NotificationEntity> entities,
  ) {
    return entities
        .map(
          (e) => NotificationItem(
            id: e.remoteId,
            type: e.type,
            title: e.title,
            message: e.message,
            relatedId: e.relatedId,
            relatedType: e.relatedType,
            contentImageUrl: e.contentImageUrl,
            isRead: e.isRead,
            timeAgo: e.timeAgo,
            actor: e.actorId != null
                ? NotificationActor(
                    id: e.actorId!,
                    username: e.actorUsername ?? '',
                    fullName: e.actorFullName ?? '',
                    profilePicture: e.actorProfilePicture,
                  )
                : null,
          ),
        )
        .toList();
  }

  Map<String, dynamic> _notificationToJson(NotificationItem n) {
    return {
      'id': n.id,
      'type': n.type,
      'title': n.title,
      'message': n.message,
      'related_id': n.relatedId,
      'related_type': n.relatedType,
      'content_image_url': n.contentImageUrl,
      'is_read': n.isRead,
      'time_ago': n.timeAgo,
      'actor': n.actor != null
          ? {
              'id': n.actor!.id,
              'username': n.actor!.username,
              'full_name': n.actor!.fullName,
              'profile_picture': n.actor!.profilePicture,
            }
          : null,
    };
  }
}
