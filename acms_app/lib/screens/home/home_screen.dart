import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/providers/notification_provider.dart';

// Shell Scafold for Persistent Bottom Navigation
class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: navigationShell, // The current branch content
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: () => context.push('/voice-chat'),
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 10,
        padding: EdgeInsets.zero,
        height: 70,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left Side - with equal spacing
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context,
                    activeIcon: Icons.home_rounded,
                    inactiveIcon: Icons.home_outlined,
                    label: 'Home',
                    index: 0,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context,
                    activeIcon: Icons.explore_rounded,
                    inactiveIcon: Icons.explore_outlined,
                    label: 'Inspire',
                    index: 1,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Center space for FAB
            const SizedBox(width: 72),

            // Right Side - with equal spacing
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context,
                    activeIcon: Icons.chat_bubble_rounded,
                    inactiveIcon: Icons.chat_bubble_outline_rounded,
                    label: 'Chats',
                    index: 2,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context,
                    activeIcon: Icons.person_rounded,
                    inactiveIcon: Icons.person_outline_rounded,
                    label: 'Profile',
                    index: 3,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isActive = navigationShell.currentIndex == index;
    return InkWell(
      onTap: () => _onTap(context, index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                key: ValueKey(isActive),
                color: isActive
                    ? AppColors.primary
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Load drafts and posts when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreationProvider>().loadRecentActivity();
      context.read<NotificationProvider>().updateUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<CreationProvider>();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header (Sticky-ish)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  (isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight)
                      .withValues(alpha: 0.9),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Vextra Logo
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset(
                    isDark
                        ? 'assets/images/vextra_logo_dark.png'
                        : 'assets/images/vextra_logo_light.png',
                    height: 32, // Adjust height as needed
                    fit: BoxFit.contain,
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () => context.push('/notifications'),
                      icon: Icon(Icons.notifications, color: Colors.grey[600]),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    Consumer<NotificationProvider>(
                      builder: (context, notifProvider, _) {
                        if (notifProvider.unreadCount == 0) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
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
                                    : AppColors.backgroundLight,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'QUICK ACTIONS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  // Action Grid
                  SizedBox(
                    height: 190,
                    child: Column(
                      children: [
                        // Create with AI (Full Width)
                        Expanded(
                          flex: 1,
                          child: InkWell(
                            onTap: () => context.push('/coming-soon'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Create with AI',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Generate posts instantly',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -30,
                                    bottom: -30,
                                    child: Container(
                                      width: 128,
                                      height: 128,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Bottom Row
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionBtn(
                                  context,
                                  'Upload Media',
                                  Icons.upload_file,
                                  isDark,
                                  onTap: () =>
                                      context.push('/create/upload-media'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionBtn(
                                  context,
                                  'Write Text',
                                  Icons.edit_note,
                                  isDark,
                                  onTap: () =>
                                      context.push('/create/write-text'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Activity Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECENT ACTIVITY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                            letterSpacing: 1,
                          ),
                        ),
                        Row(
                          children: [
                            if (provider.drafts.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${provider.drafts.length} draft${provider.drafts.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            if (provider.myPosts.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${provider.myPosts.length} post${provider.myPosts.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Drafts or Empty State
                  if (provider.isLoadingDrafts || provider.isLoadingMyPosts)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (provider.drafts.isEmpty && provider.myPosts.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    _buildActivityList(provider, isDark),

                  const SizedBox(height: 80), // Space for scroll
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                color: Colors.grey[400],
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your published posts and drafts will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(CreationProvider provider, bool isDark) {
    return Column(
      children: [
        // Published posts first
        ...provider.myPosts.map((post) => _buildPostCard(post, isDark)),
        // Then drafts
        ...provider.drafts.map(
          (draft) => _buildDraftCard(draft, isDark, provider),
        ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, bool isDark) {
    final mediaUrls = List<String>.from(post['media_urls'] ?? []);
    final content = post['content'] as String? ?? '';
    final createdAt = DateTime.tryParse(post['created_at'] ?? '');
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/post-detail', extra: post);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: mediaUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            mediaUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_outlined,
                              color: Colors.green[600],
                              size: 24,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.article_outlined,
                          color: Colors.green[600],
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PUBLISHED',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              _formatTimeAgo(createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content.isNotEmpty
                            ? (content.length > 60
                                  ? '${content.substring(0, 60)}...'
                                  : content)
                            : 'No caption',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$likesCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$commentsCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => _showDeleteConfirmation(
                              context,
                              isPost: true,
                              id: post['id'],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftCard(Draft draft, bool isDark, CreationProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _continueDraft(draft),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: draft.mediaUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            draft.mediaUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_outlined,
                              color: Colors.orange[700],
                              size: 24,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.edit_note_rounded,
                          color: Colors.orange[700],
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DRAFT',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              draft.title ?? 'Untitled',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textMain,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        draft.content?.isNotEmpty == true
                            ? (draft.content!.length > 50
                                  ? '${draft.content!.substring(0, 50)}...'
                                  : draft.content!)
                            : 'No content',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimeAgo(draft.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Horizontal Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSmallActionButton(
                      icon: Icons.edit_rounded,
                      color: AppColors.primary,
                      onTap: () => _continueDraft(draft),
                      tooltip: 'Continue',
                    ),
                    const SizedBox(width: 4),
                    _buildSmallActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.grey[400]!,
                      onTap: () => _showDeleteConfirmation(
                        context,
                        isPost: false,
                        id: draft.id,
                      ),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  void _continueDraft(Draft draft) async {
    final provider = context.read<CreationProvider>();
    final success = await provider.loadDraft(draft.id);
    if (success && mounted) {
      context.push('/create/craft-post');
    }
  }

  void _showDeleteConfirmation(
    BuildContext context, {
    required bool isPost,
    required int id,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPost ? 'Delete Post' : 'Delete Draft'),
        content: Text(
          isPost
              ? 'Are you sure you want to delete this post? This action cannot be undone.'
              : 'Are you sure you want to delete this draft?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final provider = context.read<CreationProvider>();
              bool success;

              if (isPost) {
                success = await provider.deletePost(id);
              } else {
                success = await provider.deleteDraft(id);
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (isPost ? 'Post deleted' : 'Draft deleted')
                          : 'Failed to delete',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildQuickActionBtn(
    BuildContext context,
    String label,
    IconData icon,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.grey[700], size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
