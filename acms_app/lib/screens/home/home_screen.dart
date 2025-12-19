import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:acms_app/theme/app_theme.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        height: 70,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Side
            Row(
              children: [
                _buildNavItem(
                  context,
                  Icons.home_rounded,
                  'Home',
                  index: 0,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context,
                  Icons.calendar_month_rounded,
                  'Calendar',
                  index: 1,
                  isDark: isDark,
                ),
              ],
            ),

            // Right Side
            Row(
              children: [
                _buildNavItem(
                  context,
                  Icons.smart_toy_rounded,
                  'AI Tools',
                  index: 2,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context,
                  Icons.person_rounded,
                  'Profile',
                  index: 3,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label, {
    required int index,
    required bool isDark,
  }) {
    final isActive = navigationShell.currentIndex == index;
    return InkWell(
      onTap: () => _onTap(context, index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.primary
                  : (isDark ? Colors.grey[600] : Colors.grey[400]),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
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

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    height: 40, // Adjust height as needed
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
                                : AppColors.backgroundLight,
                          ),
                        ),
                      ),
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
                            onTap: () => context.push('/create/select-mode'),
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
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionBtn(
                                  context,
                                  'Write Text',
                                  Icons.edit_note,
                                  isDark,
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
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Activity List
                  Column(
                    children: [
                      _buildActivityItem(
                        context,
                        title: "LinkedIn: 'The Future of AI'",
                        status: "Published",
                        time: "2m ago",
                        icon: Icons.work,
                        statusColor: Colors.green,
                        color: Colors.green,
                        imageUrl:
                            "https://lh3.googleusercontent.com/aida-public/AB6AXuCQe9xTdd5QEKj1sYcln5gNaJ0Jt8svJWPtqbtRgrP5pi0MJ0vh4fMis3xubV37vfALXete49F_xximC-1yWM2AhEMPQi112UXfv_Zjp7O80zo-24cFtZRNjPtNJ4l0RKlaR6ENx7nsIFRcfnPsGVUEjOBzjuTnAU2bh2wqEK2xIx3myw87-MLRj3pTOjVYkbLmeGtvdHAVx1U_EBIEkuqaB2oj9TDzcF25v6xtYIM5eqLGK-1py3a74sNREYMjsl_be6U_2H7b6ro",
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildActivityItem(
                        context,
                        title: "Instagram: Image Gen",
                        status: "Generating...",
                        time: "Processing",
                        icon: Icons.photo_camera,
                        statusColor: AppColors.primary,
                        color: AppColors.primary,
                        imageUrl:
                            "https://lh3.googleusercontent.com/aida-public/AB6AXuAVuKUxQZoi0KnGUCtydYnLSTFZrWnDUQW3nQcYQ8HKgGPwMp0d7o9dx6yETZiVFg16dbGn7IOhtsbhiDKP2s07xVZdNmZ-POmDpel6g6KP68muUIVZhBXIU8JG4wLkj9u_U8ICnHZVY7Kcty4plhQprpk6Ma9d_kGTJilAPZ463zG9ELOe2TzyMijvy2ND2d81WVdvyt9488-uD6ftQxqSvdAsTSDo3vERrGHqshuu5ITsmlaEv8T8xepr4Nnv2ZNhcyFNvx6xxd0",
                        isDark: isDark,
                        shouldPulse: true,
                      ),
                      const SizedBox(height: 12),
                      _buildActivityItem(
                        context,
                        title: "Twitter Thread Draft",
                        status: "Awaiting Approval",
                        time: "1h ago",
                        icon: Icons.flutter_dash, // Bird icon
                        statusColor: Colors.orange,
                        color: Colors.orange,
                        isDark: isDark,
                        darkIcon: true,
                      ),
                      const SizedBox(height: 80), // Space for scroll
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(
    BuildContext context,
    String label,
    IconData icon,
    bool isDark,
  ) {
    return Container(
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
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required String title,
    required String status,
    required String time,
    required IconData icon,
    required Color statusColor,
    Color? color,
    String? imageUrl,
    bool darkIcon = false,
    bool isDark = false,
    bool shouldPulse = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: darkIcon
                  ? Colors.grey[800]
                  : (isDark ? Colors.grey[700] : Colors.grey[100]),
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    )
                  : null,
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
