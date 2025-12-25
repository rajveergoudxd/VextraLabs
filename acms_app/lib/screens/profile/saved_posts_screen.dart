import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/saved_posts_provider.dart';
import 'package:acms_app/providers/inspire_provider.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SavedPostsProvider>(
        context,
        listen: false,
      ).loadSavedPosts(refresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<SavedPostsProvider>(context, listen: false).loadSavedPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.backgroundDark : Colors.white)
            .withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Saved Posts',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<SavedPostsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.savedPosts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.savedPosts.isEmpty) {
            return _buildErrorState(isDark, provider);
          }

          if (provider.savedPosts.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadSavedPosts(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 100),
              itemCount:
                  provider.savedPosts.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.savedPosts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final post = provider.savedPosts[index];
                return _buildPostCard(post, isDark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved posts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Posts you save will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, SavedPostsProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load saved posts',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadSavedPosts(refresh: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, bool isDark) {
    final user = post['user'] as Map<String, dynamic>?;
    final mediaUrls = post['media_urls'] as List?;
    final hasMedia = mediaUrls != null && mediaUrls.isNotEmpty;

    return GestureDetector(
      onTap: () {
        context.push('/post-detail', extra: post);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: user?['profile_picture'] != null
                        ? CachedNetworkImageProvider(user!['profile_picture'])
                        : null,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    child: user?['profile_picture'] == null
                        ? Icon(
                            Icons.person,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['full_name'] ?? user?['username'] ?? 'User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        if (user?['username'] != null)
                          Text(
                            '@${user!['username']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.bookmark,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                    onPressed: () {
                      _unsavePost(post['id']);
                    },
                  ),
                ],
              ),
            ),

            // Content
            if (post['content'] != null &&
                (post['content'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  post['content'],
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),

            // Media
            if (hasMedia)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: mediaUrls[0],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _unsavePost(int postId) {
    // Remove from saved posts provider
    Provider.of<SavedPostsProvider>(
      context,
      listen: false,
    ).removeFromSavedPosts(postId);

    // Also update inspire provider if the post is there
    Provider.of<InspireProvider>(context, listen: false).unsavePost(postId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post unsaved'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
