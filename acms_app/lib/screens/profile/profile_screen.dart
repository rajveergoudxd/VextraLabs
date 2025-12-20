import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;

  const ProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedPlatform = 'Instagram';

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

    Widget content = CustomScrollView(
      slivers: [
        // Sticky Header
        SliverAppBar(
          pinned: true,
          backgroundColor: (isDark ? AppColors.backgroundDark : Colors.white)
              .withValues(alpha: 0.95),
          elevation: 0,
          leading: widget.isEmbedded
              ? null
              : IconButton(
                  // Hide back button if embedded
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/home'),
                ),
          automaticallyImplyLeading: !widget.isEmbedded,
          title: Text(
            user?.username ?? user?.fullName ?? 'Profile',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textMain,
              fontWeight: FontWeight.bold,
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
                        color: isDark ? AppColors.backgroundDark : Colors.white,
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
                    Stack(
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
                            image: user?.profilePicture != null
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      user!.profilePicture!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          child: user?.profilePicture == null
                              ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                )
                              : null,
                        ),
                      ],
                    ),
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
                          ),
                          _buildStatItem(
                            '${user?.followingCount ?? 0}',
                            'Following',
                            isDark,
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
                    user!.bio!,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildPlatformChip(
                    'Instagram',
                    Icons.camera_alt,
                    _selectedPlatform == 'Instagram',
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPlatformChip(
                    'LinkedIn',
                    Icons.work,
                    _selectedPlatform == 'LinkedIn',
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPlatformChip(
                    'Twitter',
                    Icons.chat_bubble,
                    _selectedPlatform == 'Twitter',
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPlatformChip(
                    'Facebook',
                    Icons.public,
                    _selectedPlatform == 'Facebook',
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Grid Content (Conditionally Empty)
        if (user?.postsCount == 0 || user?.postsCount == null)
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
                  const SizedBox(height: 24),
                  if (_selectedPlatform != 'Instagram') // Just a hint for demo
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Tap on 'Instagram' to see demo layout (if implemented) or use specific tab logic.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(
              left: 2,
              right: 2,
              bottom: 100,
            ), // Bottom padding for nav bar
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              delegate: SliverChildListDelegate([
                // This is where real posts would go if posts_count > 0
                // For now, if count is > 0 but we don't have list, we can show skeletons or empty.
                // Assuming logic: if count > 0 we should have data.
                // But since we are cleaning mock data, and we don't have a posts API yet,
                // we should probably just show empty unless we want to keep one demo item?
                // The requirement said "removing mock data", so defaulting to empty state logic above
                // is correct as most new users have 0 posts.

                // However, for visualization, if you want to see the grid,
                // we'd need real post objects.
                // I'll stick to the "No posts yet" for the initial clean state.
              ]),
            ),
          ),
      ],
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

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Column(
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
            Icon(
              icon,
              size: 18,
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
