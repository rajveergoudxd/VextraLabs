import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/inspire_provider.dart';
import 'package:acms_app/widgets/comment_bottom_sheet.dart';
import 'package:acms_app/widgets/share_bottom_sheet.dart';

class InspireScreen extends StatefulWidget {
  const InspireScreen({super.key});

  @override
  State<InspireScreen> createState() => _InspireScreenState();
}

class _InspireScreenState extends State<InspireScreen> {
  int _selectedFilter = 0;
  final ScrollController _scrollController = ScrollController();
  final List<String> _filters = [
    'For You',
    'Following',
    'Trending',
    'Design',
    'AI Art',
  ];

  @override
  void initState() {
    super.initState();
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InspireProvider>(context, listen: false).loadFeed();
    });

    // Infinite scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        Provider.of<InspireProvider>(context, listen: false).loadFeed();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<InspireProvider>(context);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Sticky Header
          _buildHeader(isDark),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadFeed(refresh: true),
              child: provider.posts.isEmpty && provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.posts.isEmpty && provider.error != null
                  ? _buildErrorState(isDark, provider)
                  : provider.posts.isEmpty && !provider.isLoading
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        Center(
                          child: Text(
                            'No posts yet. Be the first to inspire!',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount:
                          provider.posts.length + (provider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.posts.length) {
                          return _buildLoadingIndicator();
                        }
                        return _buildPostCard(provider.posts[index], isDark);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppColors.backgroundDark : AppColors.surfaceLight)
            .withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        children: [
          // Title Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inspire',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Row(
                  children: [
                    _buildHeaderIcon(
                      Icons.search,
                      isDark,
                      onTap: () => context.push('/search'),
                    ),
                    const SizedBox(width: 4),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () => context.push('/notifications'),
                          icon: Icon(
                            Icons.notifications,
                            color: Colors.grey[600],
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : AppColors.surfaceLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.grey[900])
                            : (isDark ? Colors.grey[800] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? (isDark ? Colors.grey[900] : Colors.white)
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, bool isDark, {VoidCallback? onTap}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap ?? () {},
          child: Icon(
            icon,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, bool isDark) {
    final user = post['user'] ?? {};
    final mediaUrls = post['media_urls'] as List?;
    final imageUrl = mediaUrls != null && mediaUrls.isNotEmpty
        ? mediaUrls[0]
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(post),
                const SizedBox(width: 12),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user['username'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,

                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          if (post['isVerified'] == true) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '@${user['username']} • ${_formatTimeAgo(post['created_at'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // More Button or Follow Button
                if (post['isVerified'] == true)
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                  )
                else
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Follow',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildContentText(post['content'], isDark),
          ),
          const SizedBox(height: 12),

          // Image or Quote
          if (imageUrl != null) _buildMediaContent(imageUrl, isDark),

          if (post['quote'] != null) _buildQuoteCard(post['quote'], isDark),

          // Action Buttons
          _buildActionButtons(post, isDark),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> post) {
    final user = post['user'] ?? {};
    final avatarUrl = user['profile_picture'];

    if (avatarUrl != null) {
      return Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              image: DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),

          if (post['isVerified'] == true)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 8),
              ),
            ),
        ],
      );
    } else {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
        ),
        child: Center(
          child: Text(
            (user['username'] as String?)?.isNotEmpty == true
                ? (user['username'] as String)[0].toUpperCase()
                : '?',

            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildContentText(String content, bool isDark) {
    // Simple hashtag highlighting
    final words = content.split(' ');
    return Text.rich(
      TextSpan(
        children: words.map((word) {
          if (word.startsWith('#')) {
            return TextSpan(
              text: '$word ',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            );
          }
          return TextSpan(
            text: '$word ',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey[800],
              fontSize: 14,
              height: 1.4,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMediaContent(String imageUrl, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio:
              4 / 3, // Default aspect ratio since we don't store it yet
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildActionButtons(Map<String, dynamic> post, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildActionButton(
                icon: post['is_liked'] == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                label: '${post['likes_count'] ?? 0}',
                color: post['is_liked'] == true ? Colors.red : null,
                isDark: isDark,
                onTap: () => Provider.of<InspireProvider>(
                  context,
                  listen: false,
                ).likePost(post['id']),
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${post['comments_count'] ?? 0}',
                isDark: isDark,
                onTap: () => CommentBottomSheet.show(
                  context,
                  post['id'],
                  post['comments_count'] ?? 0,
                ),
              ),

              _buildActionButton(
                icon: Icons.send_outlined,
                isDark: isDark,
                onTap: () {
                  final mediaUrls = post['media_urls'] as List?;
                  ShareBottomSheet.show(
                    context,
                    postId: post['id'],
                    postContent: post['content'],
                    postImageUrl: mediaUrls != null && mediaUrls.isNotEmpty
                        ? mediaUrls[0]
                        : null,
                  );
                },
              ),
            ],
          ),
          IconButton(
            onPressed: () => Provider.of<InspireProvider>(
              context,
              listen: false,
            ).toggleSavePost(post['id']),
            icon: Icon(
              post['is_saved'] == true ? Icons.bookmark : Icons.bookmark_border,
              color: post['is_saved'] == true
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
    return TextButton.icon(
      onPressed: onTap ?? () {},

      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, color: color ?? defaultColor, size: 22),
      label: label != null
          ? Text(
              label,
              style: TextStyle(
                color: color ?? defaultColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, InspireProvider provider) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Failed to load feed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh or tap retry',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => provider.loadFeed(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
