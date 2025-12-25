import 'package:flutter/material.dart';
import 'package:acms_app/services/post_service.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/widgets/comment_bottom_sheet.dart';
import 'package:acms_app/widgets/share_bottom_sheet.dart';

/// Screen to display a single post from a deep link
class PostDetailScreen extends StatefulWidget {
  final String shareToken;

  const PostDetailScreen({super.key, required this.shareToken});

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
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final post = await _postService.getPostByShareToken(widget.shareToken);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
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

        // Image
        if (imageUrl != null) ...[
          const SizedBox(height: 12),
          Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover),
        ],

        // Actions
        _buildActionButtons(isDark),
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

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildActionButton(
            icon: _post!['is_liked'] == true
                ? Icons.favorite
                : Icons.favorite_border,
            label: '${_post!['likes_count'] ?? 0}',
            color: _post!['is_liked'] == true ? Colors.red : null,
            isDark: isDark,
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
