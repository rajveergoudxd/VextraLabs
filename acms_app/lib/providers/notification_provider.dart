import 'package:flutter/foundation.dart';
import 'package:acms_app/services/notification_service.dart';

/// Model for a notification item
class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String message;
  final int? relatedId;
  final String? relatedType;
  final String? contentImageUrl;
  final bool isRead;
  final String timeAgo;
  final NotificationActor? actor;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.relatedType,
    this.contentImageUrl,
    required this.isRead,
    required this.timeAgo,
    this.actor,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      type: json['type'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      relatedId: json['related_id'],
      relatedType: json['related_type'],
      contentImageUrl: json['content_image_url'],
      isRead: json['is_read'] ?? false,
      timeAgo: json['time_ago'] ?? 'Just now',
      actor: json['actor'] != null
          ? NotificationActor.fromJson(json['actor'])
          : null,
    );
  }
}

/// Model for notification actor (user who triggered it)
class NotificationActor {
  final int id;
  final String username;
  final String fullName;
  final String? profilePicture;

  NotificationActor({
    required this.id,
    required this.username,
    required this.fullName,
    this.profilePicture,
  });

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      id: json['id'],
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      profilePicture: json['profile_picture'],
    );
  }
}

/// Provider for managing notifications state
class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  bool _hasMore = false;

  // Filter state
  // 0: All, 1: Mentions, 2: System
  int _selectedFilterIndex = 0;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get selectedFilterIndex => _selectedFilterIndex;

  /// Load notifications (initial load or refresh)
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _isLoading = true;
      notifyListeners();
    } else if (_notifications.isEmpty) {
      _isLoading = true;
    }

    try {
      String? typeFilter;
      if (_selectedFilterIndex == 1) {
        typeFilter = 'mentions';
      } else if (_selectedFilterIndex == 2) {
        typeFilter = 'system';
      }

      final response = await _notificationService.getNotifications(
        skip: refresh ? 0 : _notifications.length,
        limit: 20,
        type: typeFilter,
      );

      final List<dynamic> results = response['notifications'];
      final newNotifications = results
          .map((json) => NotificationItem.fromJson(json))
          .toList();

      if (refresh) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      _unreadCount = response['unread_count'] ?? 0;
      _hasMore = response['has_more'] ?? false;
      _error = null;
    } catch (e) {
      _error = 'Failed to load notifications';
      debugPrint('Notification load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change filter and reload
  void setFilter(int index) {
    if (_selectedFilterIndex == index) return;
    _selectedFilterIndex = index;
    _notifications = [];
    loadNotifications(refresh: true);
  }

  /// Load more notifications (pagination)
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    loadNotifications(refresh: false);
  }

  /// Mark notification as read
  Future<void> markAsRead(int id) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      // We can't easily update valid objects in Dart if final, so we replace
      // Or we can just ignore UI update if we don't carry mutable state inside model
      // But we should update unread count
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      notifyListeners(); // Update badge essentially

      // Update the item in list to look read (we need copyWith or recreate)
      // Since our model has final fields, we assume it's read for UI purposes by re-fetching or
      // just letting it be until refresh.
      // A better way is to make isRead mutable or use copyWith. Let's assume refreshing or socket update for now,
      // or implement copyWith.
    }

    try {
      await _notificationService.markAsRead(id);
      // Ensure specific item is marked read in local state
      if (index != -1) {
        // Create a modified copy (manual copyWith logic since I didn't add it)
        final old = _notifications[index];
        final updated = NotificationItem(
          id: old.id,
          type: old.type,
          title: old.title,
          message: old.message,
          relatedId: old.relatedId,
          relatedType: old.relatedType,
          contentImageUrl: old.contentImageUrl,
          isRead: true, // Marked read
          timeAgo: old.timeAgo,
          actor: old.actor,
        );
        _notifications[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark read error: $e');
      // Revert optimistic update if needed, but for read status it's usually fine
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final prevCount = _unreadCount;
    _unreadCount = 0;

    // Update all local items
    _notifications = _notifications.map((n) {
      if (!n.isRead) {
        return NotificationItem(
          id: n.id,
          type: n.type,
          title: n.title,
          message: n.message,
          relatedId: n.relatedId,
          relatedType: n.relatedType,
          contentImageUrl: n.contentImageUrl,
          isRead: true,
          timeAgo: n.timeAgo,
          actor: n.actor,
        );
      }
      return n;
    }).toList();

    notifyListeners();

    try {
      await _notificationService.markAllAsRead();
    } catch (e) {
      debugPrint('Mark all read error: $e');
      _unreadCount = prevCount; // Revert
      notifyListeners();
    }
  }

  /// Update unread count specifically (e.g. for polling)
  Future<void> updateUnreadCount() async {
    try {
      final response = await _notificationService.getUnreadCount();
      _unreadCount = response['count'] ?? 0;
      notifyListeners();
    } catch (e) {
      // Silent error
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final removed = _notifications.removeAt(index);
    if (!removed.isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    }
    notifyListeners();

    try {
      await _notificationService.deleteNotification(id);
    } catch (e) {
      debugPrint('Delete error: $e');
      _notifications.insert(index, removed); // Revert
      if (!removed.isRead) _unreadCount++;
      notifyListeners();
    }
  }
}
