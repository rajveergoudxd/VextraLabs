import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<String> _filters = ["All", "Mentions", "System"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
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
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: textColor),
            tooltip: 'Mark all as read',
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            alignment: Alignment.centerLeft,
            child: Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = provider.selectedFilterIndex == index;
                    return GestureDetector(
                      onTap: () => provider.setFilter(index),
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
                                : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[800]),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  TextButton(
                    onPressed: () => provider.loadNotifications(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadNotifications(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 0),
              itemCount:
                  provider.notifications.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.notifications.length) {
                  provider.loadMore();
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final notification = provider.notifications[index];
                return _NotificationTile(
                  notification: notification,
                  isDark: isDark,
                  onTap: () {
                    // Mark as read
                    if (!notification.isRead) {
                      provider.markAsRead(notification.id);
                    }

                    // Handle navigation based on type
                    if (notification.type == 'follow' &&
                        notification.actor != null) {
                      context.push('/user/${notification.actor!.username}');
                    }
                    // Handle post/comment navigation etc if implemented
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: !notification.isRead
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
                        if (notification.actor != null) ...[
                          TextSpan(
                            text: notification.actor!.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' '),
                        ],
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
                  if (notification.type == 'system' ||
                      notification.type == 'ai')
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
            if (notification.type == 'follow' && notification.actor != null)
              _buildFollowButton(context)
            else if (notification.contentImageUrl != null)
              _buildContentImage(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (notification.type == 'ai') {
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
    } else if (notification.type == 'system') {
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

    final avatarUrl = notification.actor?.profilePicture;
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
        backgroundColor: Colors.grey[300],
      );
    }

    // Initials fallback
    final name = notification.actor?.username ?? '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context) {
    // This button needs real state, but for now we won't implement full follow toggle inside notification list
    // unless we wire up SocialProvider. For now, we can just show a button that navigates or shows status if we knew it.
    // The notification doesn't inherently carry "am I following them back" state unless we computed it.
    // Given the complexity, let's look at the original design.
    // The original dummy data had 'isFollowing'. Our backend response doesn't strictly have this yet in NotificationResponse -> ActorInfo.
    // We would need to join that info. For now, let's omit the sensitive toggle button or just keep it simple.
    // Let's just create a generic "View" button or omit it if we don't have the state.
    // Actually, users prefer to follow back right there. I'd need to check SocialProvider.

    // We can use a FutureBuilder or Consumer to check if we follow this user, but that's heavy for a list.
    // Let's simplified to just show "View Profile".

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onTap, // Handled in parent to navigate
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          elevation: 0,
          foregroundColor: isDark ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'View',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
