import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/auth_provider.dart';
import 'package:acms_app/services/post_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;

  const ProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedPlatform = 'Inspire';
  final PostService _postService = PostService();

  List<dynamic> _userPosts = [];
  bool _isLoadingPosts = false;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPosts();
    });
  }

  Future<void> _loadUserPosts({bool silent = false}) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    if (!silent) {
      setState(() {
        _isLoadingPosts = true;
        _postsError = null;
      });
    }

    try {
      final data = await _postService.getUserPosts(user.id);
      if (mounted) {
        setState(() {
          _userPosts = data['items'] as List;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postsError = e.toString();
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      Provider.of<AuthProvider>(context, listen: false).refreshUserData(),
      _loadUserPosts(silent: true),
    ]);
  }

  void _showImagePreview(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Vibrant white for dark mode text, standard black for light
    final headingStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : AppColors.textMain,
      letterSpacing: 0.5,
    );

    final subHeadingStyle = TextStyle(
      fontSize: 16,
      color: isDark
          ? const Color(0xFFEEEEEE)
          : Colors.grey[600], // Brighter grey in dark mode
      fontWeight: FontWeight.w500,
    );

    // Determine display name safely using local variable for type promotion
    String displayName = 'Profile';
    final currentUser = user; // Local variable enables type promotion
    if (currentUser != null) {
      // username is String?, fullName is String (non-nullable)
      if (currentUser.username != null && currentUser.username!.isNotEmpty) {
        displayName = currentUser.username!;
      } else if (currentUser.fullName.isNotEmpty) {
        displayName = currentUser.fullName;
      }
    }

    Widget content = RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Sticky Header
          SliverAppBar(
            pinned: true,
            backgroundColor: (isDark ? AppColors.backgroundDark : Colors.white)
                .withValues(alpha: 0.95),
            elevation: 0,
            leading: widget.isEmbedded
                ? IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () => context.push('/saved-posts'),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/home'),
                  ),
            automaticallyImplyLeading: !widget.isEmbedded,
            title: Text(
              displayName,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push('/settings'),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        border: Border.all(
                          color: isDark
                              ? AppColors.backgroundDark
                              : Colors.white,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : AppColors.textMain,
            ),
          ),

          // Profile Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Header Row: Avatar | Stats
                  Row(
                    children: [
                      // Avatar
                      // Avatar
                      _buildProfileAvatar(user?.profilePicture, isDark),
                      const SizedBox(width: 24),
                      // Stats Expanded
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              '${user?.postsCount ?? 0}',
                              'Posts',
                              isDark,
                            ),
                            _buildStatItem(
                              '${user?.followersCount ?? 0}',
                              'Followers',
                              isDark,
                              onTap: () {
                                if (user != null) {
                                  context.push(
                                    '/follow-list/${user.id}/followers',
                                  );
                                }
                              },
                            ),
                            _buildStatItem(
                              '${user?.followingCount ?? 0}',
                              'Following',
                              isDark,
                              onTap: () {
                                if (user != null) {
                                  context.push(
                                    '/follow-list/${user.id}/following',
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Name & Bio
                  Text(
                    user?.fullName ?? 'User',
                    style: headingStyle.copyWith(fontSize: 18),
                  ),
                  if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio ?? '',
                      style: subHeadingStyle.copyWith(fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'Edit Profile',
                          isDark,
                          onTap: () => context.push('/edit-profile'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'Share Profile',
                          isDark,
                          onTap: () {
                            // Share functionality
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Sticky Platform Selector (Tabs)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              isDark: isDark,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _buildPlatformChip(
                      'Inspire',
                      Icons.auto_awesome,
                      _selectedPlatform == 'Inspire',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPlatformChip(
                      'Instagram',
                      FontAwesomeIcons.instagram,
                      _selectedPlatform == 'Instagram',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPlatformChip(
                      'LinkedIn',
                      FontAwesomeIcons.linkedin,
                      _selectedPlatform == 'LinkedIn',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPlatformChip(
                      'Twitter',
                      FontAwesomeIcons.xTwitter,
                      _selectedPlatform == 'Twitter',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPlatformChip(
                      'Facebook',
                      FontAwesomeIcons.facebook,
                      _selectedPlatform == 'Facebook',
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
          ), // End of SliverPersistentHeader
          // Grid Content for Inspire section
          if (_selectedPlatform == 'Inspire')
            ..._buildInspireGrid(isDark)
          else if (user?.postsCount == 0 || user?.postsCount == null) ...[
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.only(top: 80, bottom: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.grid_on,
                      size: 64,
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When you publish content to $_selectedPlatform,\nit will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[700] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.only(top: 80, bottom: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction,
                      size: 64,
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_selectedPlatform posts will appear here soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[700] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    } else {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: content,
      );
    }
  }

  /// Build the Inspire posts grid (returns `List<Widget>` of slivers)
  List<Widget> _buildInspireGrid(bool isDark) {
    // Loading state
    if (_isLoadingPosts) {
      return [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.only(top: 80),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    // Error state
    if (_postsError != null) {
      return [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.only(top: 80, bottom: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load posts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loadUserPosts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // Empty state
    if (_userPosts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.only(top: 80, bottom: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 64,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first post to\nsee it here!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[700] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => context.push('/create/ai'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Post'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // Posts grid
    return [
      SliverPadding(
        padding: const EdgeInsets.only(left: 2, right: 2, bottom: 100),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final post = _userPosts[index];
            final mediaUrls = post['media_urls'] as List?;
            final hasMedia = mediaUrls != null && mediaUrls.isNotEmpty;
            final content = post['content'] as String? ?? '';

            return GestureDetector(
              onTap: () async {
                await context.push('/post-detail', extra: post);
                if (mounted) _loadUserPosts(silent: true);
              },
              child: Container(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                child: hasMedia
                    ? CachedNetworkImage(
                        imageUrl: mediaUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            content.length > 50
                                ? '${content.substring(0, 50)}...'
                                : content,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              ),
            );
          }, childCount: _userPosts.length),
        ),
      ),
    ];
  }

  Widget _buildStatItem(
    String value,
    String label,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textMain,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 38, // Slightly taller for better touch target
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2C2C2C)
              : Colors.grey[100], // Lighter grey for dark mode
          borderRadius: BorderRadius.circular(8),
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.1))
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformChip(
    String label,
    IconData icon,
    bool isActive,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlatform = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : (isDark ? Colors.transparent : Colors.grey[200]!),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white : AppColors.textMain),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.textMain),
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String? profilePicture, bool isDark) {
    return GestureDetector(
      onTap: () => _showImagePreview(context, profilePicture),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
            child: profilePicture != null && profilePicture.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profilePicture,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        size: 40,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 40,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isDark;

  _StickyTabBarDelegate({required this.child, required this.isDark});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
          .withValues(alpha: 0.95),
      child: child,
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
