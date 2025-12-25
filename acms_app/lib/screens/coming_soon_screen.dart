import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:acms_app/theme/app_theme.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Icon
                      Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.2),
                                  AppColors.primary.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 56,
                              color: AppColors.primary,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                            duration: 1500.ms,
                            curve: Curves.easeInOut,
                          )
                          .shimmer(
                            duration: 2000.ms,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),

                      const SizedBox(height: 40),

                      // Title
                      Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textMain,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                            'AI-Powered Creation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 200.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 24),

                      // Description
                      Text(
                            'We\'re working on something amazing! Our AI-powered content creation feature will help you generate stunning posts effortlessly.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 400.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 48),

                      // Feature Pills
                      Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildFeaturePill(
                                'Smart Captions',
                                Icons.text_fields,
                                isDark,
                              ),
                              _buildFeaturePill(
                                'Auto Hashtags',
                                Icons.tag,
                                isDark,
                              ),
                              _buildFeaturePill(
                                'Content Ideas',
                                Icons.lightbulb_outline,
                                isDark,
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 600.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 48),

                      // Go Back Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                          label: Text(
                            'Go Back',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePill(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
