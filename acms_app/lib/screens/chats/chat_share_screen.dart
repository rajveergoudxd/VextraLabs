import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/auth_provider.dart';
import 'package:acms_app/providers/chat_provider.dart';
import 'package:acms_app/services/chat_service.dart';
import 'package:acms_app/theme/app_theme.dart';

/// Screen for selecting a chat conversation to share a post to
class ChatShareScreen extends StatefulWidget {
  final int postId;
  final String? postContent;
  final String? postImageUrl;

  const ChatShareScreen({
    super.key,
    required this.postId,
    this.postContent,
    this.postImageUrl,
  });

  @override
  State<ChatShareScreen> createState() => _ChatShareScreenState();
}

class _ChatShareScreenState extends State<ChatShareScreen> {
  final ChatService _chatService = ChatService();
  bool _isSending = false;
  int? _selectedConversationId;

  @override
  void initState() {
    super.initState();
    // Load conversations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadConversations();
    });
  }

  Future<void> _shareToConversation(int conversationId) async {
    setState(() {
      _isSending = true;
      _selectedConversationId = conversationId;
    });

    try {
      // Send post share message
      await _chatService.sendPostShareMessage(
        conversationId,
        widget.postId,
        caption: widget.postContent,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Post shared successfully!'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[700],
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    } finally {
      setState(() {
        _isSending = false;
        _selectedConversationId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share to Chat'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: chatProvider.isLoadingConversations
          ? const Center(child: CircularProgressIndicator())
          : chatProvider.conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation to share posts',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: chatProvider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = chatProvider.conversations[index];
                return _buildConversationItem(context, conversation, isDark);
              },
            ),
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    Conversation conversation,
    bool isDark,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id ?? 0;
    final participant = conversation.getOtherParticipant(currentUserId);
    final username = participant?.username ?? 'Unknown';
    final fullName = participant?.fullName ?? username;
    final profilePicture = participant?.profilePicture;
    final isSelected = _selectedConversationId == conversation.id;

    return ListTile(
      leading: Stack(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              image: profilePicture != null
                  ? DecorationImage(
                      image: NetworkImage(profilePicture),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profilePicture == null
                ? Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
      title: Text(
        fullName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        '@$username',
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
      ),
      trailing: isSelected && _isSending
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.send_rounded, color: AppColors.primary),
      onTap: _isSending ? null : () => _shareToConversation(conversation.id),
    );
  }
}
