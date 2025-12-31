import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acms_app/theme/app_theme.dart';

class ConnectSocialScreen extends StatelessWidget {
  const ConnectSocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.push('/mic-permission'),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  Row(
                    children: [
                      _buildDot(AppColors.primary.withValues(alpha: 0.2)),
                      const SizedBox(width: 4),
                      _buildDot(AppColors.primary),
                      const SizedBox(width: 4),
                      _buildDot(AppColors.primary.withValues(alpha: 0.2)),
                    ],
                  ),
                  const SizedBox(width: 40), // Spacer
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Connect Social Profiles',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Authorize your accounts to let our AI automate your content strategy and enable voice publishing.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Social Items
                    _buildSocialItem(
                      context,
                      name: 'Instagram',
                      desc: 'Post & Stories',
                      icon: Icons.camera_alt,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFfacc15),
                          Color(0xFFef4444),
                          Color(0xFFa855f7),
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      isDark: isDark,
                      comingSoon: true,
                    ),
                    const SizedBox(height: 12),
                    _buildSocialItem(
                      context,
                      name: 'Facebook',
                      desc: 'Pages & Groups',
                      icon: Icons.public,
                      color: const Color(0xFF1877F2),
                      isDark: isDark,
                      comingSoon: true,
                    ),
                    const SizedBox(height: 12),
                    _buildSocialItem(
                      context,
                      name: 'X (Twitter)',
                      desc: 'Tweets & Threads',
                      icon:
                          Icons.close, // Using close as X placeholder or custom
                      color: isDark ? Colors.white : Colors.black,
                      iconColor: isDark ? Colors.black : Colors.white,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildSocialItem(
                      context,
                      name: 'LinkedIn',
                      desc: 'Personal & Company',
                      icon: Icons.business_center,
                      color: const Color(0xFF0077b5),
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Your credentials are encrypted and secure.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
              ),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => context.push('/setup-complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push('/setup-complete'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.6),
                    ),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSocialItem(
    BuildContext context, {
    required String name,
    required String desc,
    required IconData icon,
    Color? color,
    LinearGradient? gradient,
    Color iconColor = Colors.white,
    bool connected = false,
    required bool isDark,
    bool comingSoon = false,
  }) {
    return Opacity(
      opacity: comingSoon ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2c1a1a) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
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
                color: color,
                gradient: gradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textMain,
                    ),
                  ),
                  Text(
                    comingSoon ? 'Coming Soon' : desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: comingSoon
                          ? Colors.orange[400]
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppColors.textMain.withValues(alpha: 0.5)),
                      fontWeight: comingSoon
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (comingSoon)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Soon',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              )
            else if (connected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Linked',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(80, 36),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
