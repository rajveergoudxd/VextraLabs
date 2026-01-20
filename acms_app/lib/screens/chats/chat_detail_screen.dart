import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/chat_provider.dart';
import 'package:acms_app/providers/auth_provider.dart';

/// Chat detail screen (Instagram-style messaging)
class ChatDetailScreen extends StatefulWidget {
  final int conversationId;

  const ChatDetailScreen({super.key, required this.conversationId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _showEmojiPicker = false;
  Timer? _typingTimer;

  // Store provider reference for safe disposal
  ChatProvider? _chatProvider;

  // Typing indicator keep-alive
  final FocusNode _focusNode = FocusNode();
  Timer? _typingKeepAliveTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().enterChat(widget.conversationId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference to ChatProvider for safe use in dispose()
    _chatProvider = context.read<ChatProvider>();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    // Use saved reference instead of context.read()
    _chatProvider?.leaveChat();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _typingKeepAliveTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    final chatProvider = context.read<ChatProvider>();

    if (_focusNode.hasFocus) {
      // User focused input - send typing and start keep-alive
      chatProvider.sendTyping(true);
      _typingKeepAliveTimer?.cancel();
      _typingKeepAliveTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted && _focusNode.hasFocus) {
          chatProvider.sendTyping(true);
        }
      });
    } else {
      // User unfocused - stop typing immediately
      _typingKeepAliveTimer?.cancel();
      chatProvider.sendTyping(false);
    }
  }

  void _checkAndMarkRead(List<ChatMessage> messages, int currentUserId) {
    if (messages.isEmpty) return;

    // Find unread messages from others
    final unreadIds = messages
        .where((m) => m.senderId != currentUserId && !m.isRead)
        .map((m) => m.id)
        .toList();

    if (unreadIds.isNotEmpty) {
      // Mark as read immediately
      context.read<ChatProvider>().markMessagesAsRead(unreadIds);
    }
  }

  void _onTextChanged(String text) {
    // We handle typing primarily via focus now,
    // but we can still ensure typing is true when text changes
    if (_typingKeepAliveTimer == null || !_typingKeepAliveTimer!.isActive) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.sendTyping(true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendTyping(false);

    // Check if this is a reply
    if (chatProvider.replyingTo != null) {
      await chatProvider.sendReply(text);
    } else {
      await chatProvider.sendMessage(text);
    }
  }

  Future<void> _pickAndSendImage() async {
    final chatProvider = context.read<ChatProvider>();
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      final success = await chatProvider.sendMediaMessage(File(image.path));
      if (success && mounted) {
        // _scrollToBottom() not needed with reverse: true
      }
    }
  }

  Future<void> _takeAndSendPhoto() async {
    final chatProvider = context.read<ChatProvider>();
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null && mounted) {
      final success = await chatProvider.sendMediaMessage(File(photo.path));
      if (success && mounted) {
        // _scrollToBottom() not needed with reverse: true
      }
    }
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    _messageController.text += emoji.emoji;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.surfaceLight,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.isLoadingMessages) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatProvider.messagesError != null) {
                  return Center(
                    child: Text(
                      chatProvider.messagesError!,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return _buildMessagesList(
                  isDark,
                  chatProvider.messages,
                  currentUserId ?? 0,
                  chatProvider.typingUsers,
                );
              },
            ),
          ),
          _buildTypingIndicator(isDark),
          // Reply bar (when replying to a message)
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.replyingTo == null) {
                return const SizedBox.shrink();
              }
              return _buildReplyBar(isDark, chatProvider.replyingTo!);
            },
          ),
          _buildMessageInput(isDark),
          if (_showEmojiPicker) _buildEmojiPicker(isDark),
        ],
      ),
    );
  }

  Widget _buildReplyBar(bool isDark, ChatMessage replyingTo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${replyingTo.senderFullName ?? replyingTo.senderUsername ?? "message"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyingTo.content ??
                      (replyingTo.messageType == 'image'
                          ? '📷 Photo'
                          : '📎 Media'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<ChatProvider>().clearReply();
            },
            icon: Icon(Icons.close, size: 20, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.surfaceLight,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? Colors.white : Colors.grey[900],
        ),
        onPressed: () => context.pop(),
      ),
      title: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          final currentUserId = context.read<AuthProvider>().user?.id;
          final conversation = chatProvider.conversations.firstWhere(
            (c) => c.id == widget.conversationId,
            orElse: () => chatProvider.conversations.first,
          );
          final otherUser = conversation.getOtherParticipant(
            currentUserId ?? 0,
          );
          final isOnline = chatProvider.onlineUsers.contains(otherUser?.id);

          return GestureDetector(
            onTap: () {
              if (otherUser?.username != null) {
                context.push('/user/${otherUser!.username}');
              }
            },
            child: Row(
              children: [
                Stack(
                  children: [
                    _buildSmallAvatar(otherUser?.profilePicture),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUser?.fullName ?? otherUser?.username ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      Text(
                        isOnline ? 'Active now' : 'Tap to view profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.green : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.phone_outlined,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          onPressed: () {
            // Future: Voice call
          },
        ),
        IconButton(
          icon: Icon(
            Icons.videocam_outlined,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          onPressed: () {
            // Future: Video call
          },
        ),
      ],
    );
  }

  Widget _buildSmallAvatar(String? profilePicture) {
    if (profilePicture != null && profilePicture.isNotEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: profilePicture,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) => _buildInitialsAvatar('?'),
          ),
        ),
      );
    }
    return _buildInitialsAvatar('?');
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 36,
      height: 36,
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
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(
    bool isDark,
    List<ChatMessage> messages,
    int currentUserId,
    Map<int, bool> typingUsers,
  ) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Start from bottom
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        // Inverted index for data access
        // When reversed, index 0 is at the bottom visually
        // We want messages.last (newest) to be at index 0
        final dataIndex = messages.length - 1 - index;
        final message = messages[dataIndex];
        final isMe = message.senderId == currentUserId;

        // Check for read status update on build (check on first visual item, which is last data item)
        if (index == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _checkAndMarkRead(messages, currentUserId);
          });
        }

        // Check if we should show date separator
        // Visually, the separator is ABOVE the message.
        // In a reversed list, "above" is index + 1 (next item in list)
        // So we compare current message (dataIndex) with the one *before* it in time (dataIndex - 1)
        bool showDateSeparator = false;
        if (dataIndex == 0) {
          // Oldest message (first in data list) always gets a separator
          showDateSeparator = true;
        } else {
          final prevMessage = messages[dataIndex - 1];
          final dayDiff = message.createdAt
              .difference(prevMessage.createdAt)
              .inDays;
          showDateSeparator =
              dayDiff > 0 || message.createdAt.day != prevMessage.createdAt.day;
        }

        return Column(
          children: [
            if (showDateSeparator)
              _buildDateSeparator(message.createdAt, isDark),
            _MessageBubble(message: message, isMe: isMe, isDark: isDark),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date, bool isDark) {
    final now = DateTime.now();
    String dateText;

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      dateText = 'Today';
    } else if (date.day == now.day - 1 &&
        date.month == now.month &&
        date.year == now.year) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final typingUserIds = chatProvider.typingUsers.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

        if (typingUserIds.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildTypingDots(),
              const SizedBox(width: 8),
              Text(
                'typing...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingDots() {
    return Row(
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 600 + (index * 200)),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[400]?.withValues(alpha: 0.5 + value * 0.5),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Camera button
          IconButton(
            onPressed: _takeAndSendPhoto,
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      onChanged: _onTextChanged,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  // Emoji button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                      });
                    },
                    icon: Icon(
                      _showEmojiPicker
                          ? Icons.keyboard
                          : Icons.emoji_emotions_outlined,
                      color: Colors.grey[500],
                    ),
                  ),
                  // Gallery button
                  IconButton(
                    onPressed: _pickAndSendImage,
                    icon: Icon(Icons.image_outlined, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button - ValueListenableBuilder ensures UI updates as user types
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, textValue, _) {
              final hasText = textValue.text.trim().isNotEmpty;

              return Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  return IconButton(
                    onPressed: hasText && !chatProvider.isSending
                        ? _sendMessage
                        : null,
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasText ? AppColors.primary : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: chatProvider.isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker(bool isDark) {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: _onEmojiSelected,
        config: Config(
          height: 250,
          emojiViewConfig: EmojiViewConfig(
            columns: 7,
            emojiSizeMax: 28,
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            indicatorColor: AppColors.primary,
            iconColorSelected: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Message bubble widget with reactions, reply preview, edit indicator, and long-press menu
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  // Available reaction emojis
  static const List<String> reactionEmojis = [
    '❤️',
    '👍',
    '😂',
    '😮',
    '😢',
    '🙏',
  ];

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;

    return Dismissible(
      key: ValueKey('swipe_${message.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        // Trigger reply
        context.read<ChatProvider>().setReplyingTo(message);
        return false; // Don't dismiss
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Icon(Icons.reply, color: Colors.grey[400]),
      ),
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(context, currentUserId),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.primary
                            : (isDark ? Colors.grey[800] : Colors.grey[200]),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isMe ? 20 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reply preview (if this message is a reply)
                          if (message.replyTo != null)
                            _buildReplyPreview(context),
                          // Main content
                          Padding(
                            padding: message.messageType == 'text'
                                ? const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  )
                                : const EdgeInsets.all(4),
                            child: _buildContent(),
                          ),
                        ],
                      ),
                    ),
                    // Reactions display
                    if (message.reactions.isNotEmpty)
                      _buildReactionsDisplay(context, currentUserId),
                    const SizedBox(height: 2),
                    // Timestamp and read indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            'edited',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildReadIndicator(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    final reply = message.replyTo!;
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white70 : AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.senderName ?? 'Message',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isMe ? Colors.white70 : AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            reply.content ??
                (reply.messageType == 'image' ? '📷 Photo' : '📎 Media'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsDisplay(BuildContext context, int currentUserId) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: message.reactions.map((reaction) {
          final isMine = reaction.hasUserReacted(currentUserId);
          return GestureDetector(
            onTap: () {
              context.read<ChatProvider>().toggleReaction(
                message.id,
                reaction.emoji,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isMine
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(12),
                border: isMine
                    ? Border.all(color: AppColors.primary, width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(reaction.emoji, style: const TextStyle(fontSize: 12)),
                  if (reaction.count > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${reaction.count}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, int currentUserId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reaction picker row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: reactionEmojis.map((emoji) {
                  final existingReaction = message.reactions
                      .where((r) => r.emoji == emoji)
                      .firstOrNull;
                  final isMine =
                      existingReaction?.hasUserReacted(currentUserId) ?? false;

                  return GestureDetector(
                    onTap: () {
                      context.read<ChatProvider>().toggleReaction(
                        message.id,
                        emoji,
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMine
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            // Reply option
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().setReplyingTo(message);
              },
            ),
            // Edit option (sender only, text messages)
            if (isMe && message.messageType == 'text')
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
            // Copy option (text messages)
            if (message.messageType == 'text' && message.content != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  // Copy to clipboard
                  if (message.content != null) {
                    // Using services
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Enter new message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                context.read<ChatProvider>().editMessage(
                  message.id,
                  newContent,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (message.messageType == 'image' || message.messageType == 'video') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: message.mediaUrl ?? '',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(width: 200, height: 200, color: Colors.grey[300]),
              errorWidget: (context, url, error) => Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
            if (message.messageType == 'video')
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Text(
      message.content ?? '',
      style: TextStyle(
        fontSize: 15,
        color: isMe ? Colors.white : (isDark ? Colors.white : Colors.grey[900]),
      ),
    );
  }

  /// Aesthetic read receipt indicator (subtle glow instead of checkmarks)
  Widget _buildReadIndicator() {
    if (message.isRead) {
      // Seen - subtle glow/pulse effect
      return Container(
        width: 16,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.6),
              AppColors.primary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    } else {
      // Sent but not read - muted indicator
      return Container(
        width: 16,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[400]?.withValues(alpha: 0.5),
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
