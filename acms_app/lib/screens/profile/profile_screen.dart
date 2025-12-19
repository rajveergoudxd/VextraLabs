import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  final bool isEmbedded;

  const ProfileScreen({super.key, this.isEmbedded = false});

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
          leading: isEmbedded
              ? null
              : IconButton(
                  // Hide back button if embedded
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/home'),
                ),
          automaticallyImplyLeading: !isEmbedded,
          title: Text(
            user?.fullName ?? 'Profile',
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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                "https://lh3.googleusercontent.com/aida-public/AB6AXuDQipIVUemZppesVdq37IgGVR7ygUg661FfHWD7JqCXZmLfXlDhcf0EgsPgJh3a2yuBOlO3ogTJoDigYJxLR4xKxE7xIO4G8h4pYhV5fo64aKENHcIlagx16zgwQrkKbE7URZsd7kGx4pPodAnJHR5657qwILynxfdMAmpTf_pxDTqDxBkgR42vWuBPNgaApqCh-bkpSFQgKw8lTpRUwyI-VE_-WdPt_0dFvn6TiGD97h1Z-hmRa4qW9eJ61L5mT2VVaNaifFYpLTU",
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Stats Expanded
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('1.2k', 'Posts', isDark),
                          _buildStatItem('12k', 'Followers', isDark),
                          _buildStatItem('850', 'Following', isDark),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Name & Bio
                Text(
                  user?.fullName ?? 'Alex Creator',
                  style: headingStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Automating growth 🚀',
                  style: subHeadingStyle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'www.acms.ai/alex',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Edit Profile',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Share Profile',
                        isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Sticky Platform Selector
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
                    true,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPlatformChip('LinkedIn', Icons.work, false, isDark),
                  const SizedBox(width: 8),
                  _buildPlatformChip(
                    'Twitter',
                    Icons.chat_bubble,
                    false,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPlatformChip('Facebook', Icons.public, false, isDark),
                ],
              ),
            ),
          ),
        ),

        // Grid Content
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
              _buildGridItem(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuA473C2S7LOHIJposzEX9ZsL6cOp1J5LX_wtgv9jHz47iXwPmLUiHy8WXtgEY5hSWB7xwCnkD-0liH0of1EbmiY7q04q1oyujVcQvm0I3WA2aiDUHAO8K3qS7Xz44NFuOaDgAGxSFLF0gS6UpaJ7BbCmU6OACrnMDE0zVri2zFRhOVi30A6A9vCgoD1O465CJTE0e4U5GXsmVgHmxcEIcM6iGkC-gkWRHj8bpbCXADw8uxh5CKAUd3NX-wXJCvscIKYZji2-Wee1Ic",
                isDark,
                badge: Icons.check_circle,
              ),
              _buildGridItem(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuATekDdpXIPe5RcFUiWuA7-jhgOnCNeSU244ojcXsFEAbfoFokzKe8GADd8nteM9mdBCNP3dtGDvarL82koiqvP5vrdhK2SOUllLn5OIFOA-u_vfV5g_VJRigV1wGqB4JVHmEnKisWD3AbmzR3MpoRkihSVIz_IZcaRNHHWBVJC3uG1CePJsVw6SyzH0bUVGnZ8OEPQTbU-XgF374J3TipL0Vps5Nsq9isjQvWqfkGXnYIfRfDPiBWrUQqPEa9oHaZ-IXkfag4IL2s",
                isDark,
                badge: Icons.schedule,
                isScheduled: true,
              ),
              _buildDraftItem(isDark),
              _buildGridItem(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuAPwDpqpQWxBVCkSX_x36ssMvMZEc0SYYQdxCROjegdcHCmDNT7UG6JovbUDdTtGkSihaW23WfVPAwGhG2sXnjLpiCR4W-KX8OJt8wXuy31ly8rqBbMv4626djZurWTnfQEJrf204F_gQd0Q_t2U3E4nVcDPZDxSR67Xv8dYPpoVwKThmRtz-bbRNQ8fzg5gL8kbceJCrvQTFIEtybcFSzFjxrGD4X-pZ0LFX9RqDkiKW4D0BhATtRfmTkM5R5oYXr37MJ3ywmxwhc",
                isDark,
              ),
              _buildGridItem(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuBBUMhX1FYynfuSd2Ha11SLemGnSAor65uCBGHcFgVlJMwsFPyuET7tkqFcMKREdtOgjfr1nsXhDVDW8q4f5mv0EkbXAaBCvCqdM-Hm-W8SWYZD8cTfRRSdzOunJOaWg6_ibiPFhOFCkm29GKlkNa9YV55Ajho9QrteLjR-ImnNUtEUrW4EoB4RkGRy7RKdZ7NruzrYTD1aeIErK1eCB8qEglZXUxAWu99LBV4Xnr9c5JJAAd6sLmiS8cyxBMA2mUD9xR_EjzuOvfg",
                isDark,
              ),
              _buildGridItem(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuDmHIbNxeacS863rGs4xuoK4u84TIxCUcFI1HZw2Vxm8ZRoqahbqeYXVjG02DUORG4YDnRDHvPAUGj60Q45aambJfDjFWWtB6Q2pjCRVdH0vJo8sTh4bZ4QDKSH7XiYYWSSEu7OxGH_BicQbJJdlqkTIIDFbrOk_dbvHvcmwZ2Hr24F0SUoU0hVoUqxFzw3c1y-qUXCTHPawlLhu-Au7kDCtn-PxjXUTlFfFFmP-YVkekMWtTttTb4XfozOsJqKmkI4K6inA86uRHM",
                isDark,
                badge: Icons.schedule,
                isScheduled: true,
              ),
            ]),
          ),
        ),
      ],
    );

    if (isEmbedded) {
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

  Widget _buildActionButton(BuildContext context, String text, bool isDark) {
    return InkWell(
      onTap: () {},
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
    return Container(
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
    );
  }

  Widget _buildGridItem(
    String imageUrl,
    bool isDark, {
    IconData? badge,
    bool isScheduled = false,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(imageUrl),
              fit: BoxFit.cover,
              colorFilter: isScheduled
                  ? ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.1),
                      BlendMode.darken,
                    )
                  : null,
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isScheduled
                    ? AppColors.primary
                    : Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(badge, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildDraftItem(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.7,
            child: CachedNetworkImage(
              imageUrl:
                  "https://lh3.googleusercontent.com/aida-public/AB6AXuCBbvVDb5Pzwq0rGqbAWz0zgbnbABJ-_trUNg1-QgN53XIrO_Z0Cz_8lAPMYaTqgZLe61qPyeboHBntLYfJy8HwVPpsBVvb-z32KZ5QQ3hVEnANppKK_RSbN-G0SK2i9LSGZN6zqASi1jvkBW_G2RY1HthYWBDYLO8t66VX65NcvHhOfjxqDT8JRCYFrKhY6AnBHGMpLB2jRtDyGDcEq_msyUNo2wOjblSwm5aCG3XlPgNgW3rMEU1w3r8iToadg56gJAY1x1-1aNU",
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'DRAFT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.grey[600]!.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_note, color: Colors.white, size: 14),
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
