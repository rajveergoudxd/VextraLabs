import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/chat_provider.dart';
import 'package:acms_app/providers/auth_provider.dart';
import 'package:acms_app/providers/presence_provider.dart';
import 'package:acms_app/widgets/online_users_bar.dart';

/// Main chats screen showing conversation list (Instagram-style)
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  void initState() {
    super.initState();
    // Load conversations when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
      // Initialize presence tracking
      context.read<PresenceProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(isDark),
          // Online users section
          Consumer<PresenceProvider>(
            builder: (context, presenceProvider, _) {
              if (presenceProvider.onlineFollowing.isEmpty) {
                return const SizedBox.shrink();
              }
              return OnlineUsersBar(
                onlineUsers: presenceProvider.onlineFollowing,
              );
            },
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.isLoadingConversations) {
                  return _buildLoadingState();
                }

                if (chatProvider.conversationsError != null) {
                  return _buildErrorState(
                    isDark,
                    chatProvider.conversationsError!,
                  );
                }

                if (chatProvider.conversations.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return _buildConversationList(isDark, chatProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.backgroundDark : AppColors.surfaceLight)
            .withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Messages',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          Row(
            children: [
              // New message button
              IconButton(
                onPressed: () {
                  context.push('/chats/new');
                },
                icon: Icon(
                  Icons.edit_square,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().loadConversations();
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with someone!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/chats/new');
            },
            icon: const Icon(Icons.add),
            label: const Text('New Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(bool isDark, ChatProvider chatProvider) {
    final currentUserId = context.read<AuthProvider>().user?.id;

    return RefreshIndicator(
      onRefresh: () => chatProvider.loadConversations(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: chatProvider.conversations.length,
        itemBuilder: (context, index) {
          final conversation = chatProvider.conversations[index];
          final otherUser = conversation.getOtherParticipant(
            currentUserId ?? 0,
          );

          return _ConversationTile(
            conversation: conversation,
            otherUser: otherUser,
            isDark: isDark,
            isOnline: chatProvider.onlineUsers.contains(otherUser?.id),
            onTap: () {
              context.push('/chats/${conversation.id}');
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final ConversationParticipant? otherUser;
  final bool isDark;
  final bool isOnline;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.otherUser,
    required this.isDark,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          _buildAvatar(),
          if (isOnline)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.backgroundDark : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUser?.fullName ?? otherUser?.username ?? 'Unknown',
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
          ),
          Text(
            _formatTime(conversation.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color: hasUnread ? AppColors.primary : Colors.grey[500],
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              _getLastMessagePreview(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: hasUnread
                    ? (isDark ? Colors.grey[300] : Colors.grey[700])
                    : Colors.grey[500],
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (otherUser?.profilePicture != null &&
        otherUser!.profilePicture!.isNotEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: otherUser!.profilePicture!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) => _buildInitialsAvatar(),
          ),
        ),
      );
    }
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    final initials = _getInitials();
    return Container(
      width: 56,
      height: 56,
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
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (otherUser?.fullName != null && otherUser!.fullName!.isNotEmpty) {
      final parts = otherUser!.fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return otherUser!.fullName![0].toUpperCase();
    }
    if (otherUser?.username != null && otherUser!.username!.isNotEmpty) {
      return otherUser!.username![0].toUpperCase();
    }
    return '?';
  }

  String _getLastMessagePreview() {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) return 'Start a conversation';

    if (lastMessage.messageType == 'image') {
      return '📷 Photo';
    } else if (lastMessage.messageType == 'video') {
      return '🎬 Video';
    }

    return lastMessage.content ?? '';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}
