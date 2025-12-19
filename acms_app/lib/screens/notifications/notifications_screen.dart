import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acms_app/theme/app_theme.dart';

enum NotificationType { like, comment, follow, mention, system, ai }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String username;
  final String avatarUrl;
  final String message;
  final String timeAgo;
  final bool isUnread;
  final String? contentImageUrl;
  final bool isFollowing;

  NotificationItem({
    required this.id,
    required this.type,
    required this.username,
    required this.avatarUrl,
    required this.message,
    required this.timeAgo,
    this.isUnread = false,
    this.contentImageUrl,
    this.isFollowing = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["All", "Mentions", "System"];

  // Dummy Data
  final List<NotificationItem> _allNotifications = [
    NotificationItem(
      id: '1',
      type: NotificationType.ai,
      username: 'Vextra AI',
      avatarUrl: '', // System icon used instead
      message: 'Your "Future of Tech" post generation is ready.',
      timeAgo: '2m',
      isUnread: true,
      contentImageUrl: 'https://picsum.photos/id/48/200/200',
    ),
    NotificationItem(
      id: '2',
      type: NotificationType.like,
      username: 'sarah_design',
      avatarUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026024d',
      message: 'liked your post.',
      timeAgo: '2h',
      isUnread: true,
      contentImageUrl: 'https://picsum.photos/id/237/200/200',
    ),
    NotificationItem(
      id: '3',
      type: NotificationType.follow,
      username: 'tech_daily',
      avatarUrl: 'https://i.pravatar.cc/150?u=a04258a2462d826712d',
      message: 'started following you.',
      timeAgo: '5h',
      isUnread: true,
      isFollowing: false,
    ),
    NotificationItem(
      id: '4',
      type: NotificationType.comment,
      username: 'alex_marketing',
      avatarUrl: 'https://i.pravatar.cc/150?u=a048581f4e29026701d',
      message: 'commented: "Great insights on the new AI trends!"',
      timeAgo: '1d',
      contentImageUrl: 'https://picsum.photos/id/10/200/200',
    ),
    NotificationItem(
      id: '5',
      type: NotificationType.mention,
      username: 'john_doe',
      avatarUrl: 'https://i.pravatar.cc/150?u=2042581f4e29026704d',
      message: 'mentioned you in a story.',
      timeAgo: '1d',
      contentImageUrl: 'https://picsum.photos/id/1015/200/200',
    ),
    NotificationItem(
      id: '6',
      type: NotificationType.system,
      username: 'System',
      avatarUrl: '',
      message: 'Your monthly analytics report is available.',
      timeAgo: '2d',
    ),
    NotificationItem(
      id: '7',
      type: NotificationType.follow,
      username: 'creative_studio',
      avatarUrl: 'https://i.pravatar.cc/150?u=1042581f4e29026704d',
      message: 'started following you.',
      timeAgo: '3d',
      isFollowing: true,
    ),
  ];

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilterIndex == 0) return _allNotifications;
    if (_selectedFilterIndex == 1) {
      return _allNotifications
          .where((n) => n.type == NotificationType.mention)
          .toList();
    }
    if (_selectedFilterIndex == 2) {
      return _allNotifications
          .where(
            (n) =>
                n.type == NotificationType.system ||
                n.type == NotificationType.ai,
          )
          .toList();
    }
    return _allNotifications;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            alignment: Alignment.centerLeft,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedFilterIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilterIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.grey[800] : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                    ),
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.grey[400] : Colors.grey[800]),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 0),
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];
          // Simple date headers logic could be added here
          return _NotificationTile(notification: notification, isDark: isDark);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final bool isDark;

  const _NotificationTile({required this.notification, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isUnread
          ? (isDark
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.05))
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _buildAvatar(),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: notification.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(text: notification.message),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: notification.timeAgo,
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (notification.type == NotificationType.system ||
                    notification.type == NotificationType.ai)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Tap to view details",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action (Follow button or Image)
          if (notification.type == NotificationType.follow)
            _buildFollowButton(context)
          else if (notification.contentImageUrl != null)
            _buildContentImage(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (notification.type == NotificationType.ai) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
      );
    } else if (notification.type == NotificationType.system) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.info_outline,
          color: isDark ? Colors.white : Colors.black,
          size: 24,
        ),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundImage: CachedNetworkImageProvider(notification.avatarUrl),
      backgroundColor: Colors.grey[300],
    );
  }

  Widget _buildFollowButton(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: notification.isFollowing
              ? (isDark ? Colors.grey[800] : Colors.grey[200])
              : AppColors.primary,
          elevation: 0,
          foregroundColor: notification.isFollowing
              ? (isDark ? Colors.white : Colors.black)
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          notification.isFollowing ? 'Following' : 'Follow',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildContentImage() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        image: DecorationImage(
          image: CachedNetworkImageProvider(notification.contentImageUrl!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
