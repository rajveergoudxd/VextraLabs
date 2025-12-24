import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/social_provider.dart';
import 'package:acms_app/providers/chat_provider.dart';

/// View another user's public profile
class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Store provider reference for safe disposal
  SocialProvider? _socialProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadProfile(widget.username);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference to SocialProvider for safe use in dispose()
    _socialProvider = context.read<SocialProvider>();
  }

  @override
  void dispose() {
    // Use saved reference and silent method to avoid notifyListeners during dispose
    _socialProvider?.clearProfileSilently();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            return Text(
              provider.currentProfile?.username ?? 'User',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Consumer<SocialProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingProfile) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.profileError != null ||
              provider.currentProfile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'User not found',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final profile = provider.currentProfile!;
          return _buildProfileContent(isDark, profile, provider);
        },
      ),
    );
  }

  Widget _buildProfileContent(
    bool isDark,
    PublicProfile profile,
    SocialProvider provider,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Profile header (avatar + stats)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(profile),
                const SizedBox(width: 24),

                // Stats
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('Posts', profile.postsCount, isDark),
                      _buildStat('Followers', profile.followersCount, isDark),
                      _buildStat('Following', profile.followingCount, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Name and bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.fullName != null && profile.fullName!.isNotEmpty)
                  Text(
                    profile.fullName!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.bio!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
                if (profile.isFollowedBy) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Follows you',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(child: _buildFollowButton(isDark, profile, provider)),
                const SizedBox(width: 8),
                Expanded(child: _buildMessageButton(isDark, profile)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Empty posts section
          _buildEmptyPosts(isDark),
        ],
      ),
    );
  }

  Widget _buildAvatar(PublicProfile profile) {
    if (profile.profilePicture != null && profile.profilePicture!.isNotEmpty) {
      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: profile.profilePicture!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) => _buildInitialsAvatar(profile),
          ),
        ),
      );
    }
    return _buildInitialsAvatar(profile);
  }

  Widget _buildInitialsAvatar(PublicProfile profile) {
    final initials = _getInitials(profile);
    return Container(
      width: 86,
      height: 86,
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
            fontSize: 28,
          ),
        ),
      ),
    );
  }

  String _getInitials(PublicProfile profile) {
    if (profile.fullName != null && profile.fullName!.isNotEmpty) {
      final parts = profile.fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return profile.fullName![0].toUpperCase();
    }
    if (profile.username != null && profile.username!.isNotEmpty) {
      return profile.username![0].toUpperCase();
    }
    return '?';
  }

  Widget _buildStat(String label, int count, bool isDark) {
    return Column(
      children: [
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildFollowButton(
    bool isDark,
    PublicProfile profile,
    SocialProvider provider,
  ) {
    final isFollowing = profile.isFollowing;

    return ElevatedButton(
      onPressed: provider.isFollowActionLoading
          ? null
          : () async {
              await provider.toggleFollow(profile.id, isFollowing);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing
            ? (isDark ? Colors.grey[800] : Colors.grey[200])
            : AppColors.primary,
        foregroundColor: isFollowing
            ? (isDark ? Colors.white : Colors.grey[900])
            : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: provider.isFollowActionLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildMessageButton(bool isDark, PublicProfile profile) {
    return ElevatedButton(
      onPressed: () async {
        // Create or get conversation with this user
        final chatProvider = context.read<ChatProvider>();
        final conversation = await chatProvider.openConversationWithUser(
          profile.id,
        );

        if (conversation != null && mounted) {
          context.push('/chats/${conversation.id}');
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        foregroundColor: isDark ? Colors.white : Colors.grey[900],
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: const Text(
        'Message',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyPosts(bool isDark) {
    return Column(
      children: [
        Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        const SizedBox(height: 48),
        Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'No Posts Yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'When they share posts, they\'ll appear here.',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
