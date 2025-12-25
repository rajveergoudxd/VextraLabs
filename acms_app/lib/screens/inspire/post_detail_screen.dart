import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:acms_app/services/post_service.dart';
import 'package:acms_app/providers/auth_provider.dart';
import 'package:acms_app/providers/inspire_provider.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/widgets/comment_bottom_sheet.dart';
import 'package:acms_app/widgets/share_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Screen to display a single post.
/// Can be opened via deep link (shareToken) or directly with post data.
class PostDetailScreen extends StatefulWidget {
  final String? shareToken;
  final Map<String, dynamic>? post;

  const PostDetailScreen({super.key, this.shareToken, this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();

  Map<String, dynamic>? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _post = widget.post;
      _isLoading = false;
    } else if (widget.shareToken != null) {
      _loadPost();
    } else {
      _error = "Invalid post parameters";
      _isLoading = false;
    }
  }

  Future<void> _loadPost() async {
    try {
      final post = await _postService.getPostByShareToken(widget.shareToken!);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && _post != null) {
      try {
        await context.read<InspireProvider>().deletePost(_post!['id']);
        if (mounted) {
          context.pop(); // Go back
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Post deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.read<AuthProvider>().user;
    final isOwner =
        _post != null &&
        currentUser != null &&
        (_post!['user']['id'] == currentUser.id ||
            _post!['user_id'] ==
                currentUser.id); // Check both fields just in case

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          if (isOwner && !_isLoading && _post != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _handleDelete();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Delete Post',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Post not found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The post may have been deleted',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(child: _buildPostContent(isDark)),
    );
  }

  Widget _buildPostContent(bool isDark) {
    if (_post == null) return const SizedBox.shrink();

    final user = _post!['user'] ?? {};
    final mediaUrls = _post!['media_urls'] as List?;
    final imageUrl = mediaUrls != null && mediaUrls.isNotEmpty
        ? mediaUrls[0]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(user),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['username'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(_post!['created_at']),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        if (_post!['content'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _post!['content'],
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

        // Quote
        if (_post!['quote'] != null) ...[
          const SizedBox(height: 12),
          _buildQuoteCard(_post!['quote'], isDark),
        ],

        // Image
        if (imageUrl != null) ...[
          const SizedBox(height: 12),
          CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 300,
              color: isDark ? Colors.grey[900] : Colors.grey[200],
            ),
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              child: const Icon(Icons.error),
            ),
          ),
        ],

        // Actions
        _buildActionButtons(isDark),

        const Divider(),

        // Maybe some stats or comments preview here
      ],
    );
  }

  Widget _buildAvatar(Map<String, dynamic> user) {
    final profilePicture = user['profile_picture'];
    final username = user['username'] ?? '';

    return Container(
      width: 44,
      height: 44,
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[850]!, Colors.grey[900]!]
              : [const Color(0xFFFEF2F2), const Color(0xFFFFF7ED)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        children: [
          Text(
            quote['text'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white : Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              quote['author'],
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildActionButton(
                icon: _post!['is_liked'] == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                label: '${_post!['likes_count'] ?? 0}',
                color: _post!['is_liked'] == true ? Colors.red : null,
                isDark: isDark,
                onTap: () =>
                    context.read<InspireProvider>().likePost(_post!['id']),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${_post!['comments_count'] ?? 0}',
                isDark: isDark,
                onTap: () => CommentBottomSheet.show(
                  context,
                  _post!['id'],
                  _post!['comments_count'] ?? 0,
                ),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.send_outlined,
                isDark: isDark,
                onTap: () {
                  final mediaUrls = _post!['media_urls'] as List?;
                  ShareBottomSheet.show(
                    context,
                    postId: _post!['id'],
                    postContent: _post!['content'],
                    postImageUrl: mediaUrls != null && mediaUrls.isNotEmpty
                        ? mediaUrls[0]
                        : null,
                  );
                },
              ),
            ],
          ),
          IconButton(
            onPressed: () =>
                context.read<InspireProvider>().toggleSavePost(_post!['id']),
            icon: Icon(
              _post!['is_saved'] == true
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: _post!['is_saved'] == true
                  ? (isDark ? Colors.white : Colors.grey[900])
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    Color? color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final defaultColor = isDark ? Colors.grey[500] : Colors.grey[600];
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? defaultColor, size: 22),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color ?? defaultColor, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
