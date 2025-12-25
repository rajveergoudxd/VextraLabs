import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/services/presence_service.dart';
import 'package:acms_app/providers/chat_provider.dart';
import 'package:acms_app/theme/app_theme.dart';

/// Horizontal scrollable bar showing online following users
/// Similar to Instagram's notes/stories section but for online status
class OnlineUsersBar extends StatelessWidget {
  final List<OnlineUser> onlineUsers;

  const OnlineUsersBar({super.key, required this.onlineUsers});

  @override
  Widget build(BuildContext context) {
    if (onlineUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 115,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: onlineUsers.length,
        separatorBuilder: (_, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return OnlineUserAvatar(
            user: onlineUsers[index],
            onTap: () => _openChatWithUser(context, onlineUsers[index]),
          );
        },
      ),
    );
  }

  Future<void> _openChatWithUser(BuildContext context, OnlineUser user) async {
    final chatProvider = context.read<ChatProvider>();

    // Open or create conversation with this user
    final conversation = await chatProvider.openConversationWithUser(user.id);

    if (conversation != null && context.mounted) {
      context.push('/chats/${conversation.id}');
    }
  }
}

/// Individual online user avatar with green dot indicator
class OnlineUserAvatar extends StatelessWidget {
  final OnlineUser user;
  final VoidCallback onTap;

  const OnlineUserAvatar({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                _buildAvatarContainer(isDark),
                // Green online indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF44B700), // Bright green
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.backgroundDark : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF44B700).withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Username
            Text(
              user.username ?? user.fullName ?? 'User',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContainer(bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.backgroundDark : Colors.white,
        ),
        padding: const EdgeInsets.all(2),
        child: _buildAvatar(),
      ),
    );
  }

  Widget _buildAvatar() {
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.profilePicture!,
          fit: BoxFit.cover,
          width: 48,
          height: 48,
          placeholder: (context, url) => Container(color: Colors.grey[300]),
          errorWidget: (context, url, error) => _buildInitialsAvatar(),
        ),
      );
    }
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    final initials = _getInitials();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (user.fullName != null && user.fullName!.isNotEmpty) {
      final parts = user.fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return user.fullName![0].toUpperCase();
    }
    if (user.username != null && user.username!.isNotEmpty) {
      return user.username![0].toUpperCase();
    }
    return '?';
  }
}
