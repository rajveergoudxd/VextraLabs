import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/social_provider.dart';
import 'package:acms_app/providers/auth_provider.dart';

/// Screen showing followers or following list with tab switching
class FollowListScreen extends StatefulWidget {
  final int userId;
  final String initialTab; // 'followers' or 'following'

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.initialTab,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'following' ? 1 : 0,
    );
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
  }

  void _loadInitialData() {
    final socialProvider = context.read<SocialProvider>();

    // Load both lists initially
    socialProvider.loadFollowers(widget.userId);
    socialProvider.loadFollowing(widget.userId);

    // Get username for title if viewing another user
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id != widget.userId) {
      // Fetch the user's profile to get username
      socialProvider.loadProfileById(widget.userId);
    }
  }

  void _onTabChanged() {
    // Refresh the list when tab changes
    final socialProvider = context.read<SocialProvider>();
    if (_tabController.index == 0) {
      socialProvider.loadFollowers(widget.userId);
    } else {
      socialProvider.loadFollowing(widget.userId);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final isOwnProfile = authProvider.user?.id == widget.userId;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.surfaceLight,
      appBar: AppBar(
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
        title: Consumer<SocialProvider>(
          builder: (context, provider, _) {
            String title;
            if (isOwnProfile) {
              title = authProvider.user?.username ?? 'Profile';
            } else {
              title = provider.currentProfile?.username ?? 'User';
            }
            return Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : Colors.grey[900],
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            Consumer<SocialProvider>(
              builder: (context, provider, _) {
                return Tab(text: 'Followers (${provider.followersTotal})');
              },
            ),
            Consumer<SocialProvider>(
              builder: (context, provider, _) {
                return Tab(text: 'Following (${provider.followingTotal})');
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFollowersList(isDark), _buildFollowingList(isDark)],
      ),
    );
  }

  Widget _buildFollowersList(bool isDark) {
    return Consumer<SocialProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingFollowList && provider.followers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.followListError != null && provider.followers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  provider.followListError!,
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadFollowers(widget.userId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.followers.isEmpty) {
          return _buildEmptyState(isDark, 'No followers yet');
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadFollowers(widget.userId),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.followers.length,
            itemBuilder: (context, index) {
              final user = provider.followers[index];
              return _buildUserTile(user, isDark, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildFollowingList(bool isDark) {
    return Consumer<SocialProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingFollowList && provider.following.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.followListError != null && provider.following.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  provider.followListError!,
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadFollowing(widget.userId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.following.isEmpty) {
          return _buildEmptyState(isDark, 'Not following anyone');
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadFollowing(widget.userId),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.following.length,
            itemBuilder: (context, index) {
              final user = provider.following[index];
              return _buildUserTile(user, isDark, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(
    UserSearchResult user,
    bool isDark,
    SocialProvider provider,
  ) {
    final authProvider = context.read<AuthProvider>();
    final isOwnProfile = authProvider.user?.id == user.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildAvatar(user, isDark),
      title: Text(
        user.fullName ?? user.username ?? 'User',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.grey[900],
        ),
      ),
      subtitle: user.username != null
          ? Text(
              '@${user.username}',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            )
          : null,
      trailing: isOwnProfile
          ? null
          : _buildFollowButton(user, isDark, provider),
      onTap: () {
        if (!isOwnProfile && user.username != null) {
          context.push('/user/${user.username}');
        }
      },
    );
  }

  Widget _buildAvatar(UserSearchResult user, bool isDark) {
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: user.profilePicture!,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: isDark ? Colors.grey[800] : Colors.grey[200]),
            errorWidget: (context, url, error) =>
                _buildInitialsAvatar(user, isDark),
          ),
        ),
      );
    }
    return _buildInitialsAvatar(user, isDark);
  }

  Widget _buildInitialsAvatar(UserSearchResult user, bool isDark) {
    final initials = _getInitials(user);
    return Container(
      width: 50,
      height: 50,
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

  String _getInitials(UserSearchResult user) {
    if (user.fullName != null && user.fullName!.isNotEmpty) {
      final parts = user.fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return user.fullName![0].toUpperCase();
    }
    if (user.username != null && user.username!.isNotEmpty) {
      return user.username![0].toUpperCase();
    }
    return '?';
  }

  Widget _buildFollowButton(
    UserSearchResult user,
    bool isDark,
    SocialProvider provider,
  ) {
    final isFollowing = user.isFollowing;

    return SizedBox(
      width: 100,
      height: 32,
      child: ElevatedButton(
        onPressed: provider.isFollowActionLoading
            ? null
            : () async {
                await provider.toggleFollow(user.id, isFollowing);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing
              ? (isDark ? Colors.grey[800] : Colors.grey[200])
              : AppColors.primary,
          foregroundColor: isFollowing
              ? (isDark ? Colors.white : Colors.grey[900])
              : Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
