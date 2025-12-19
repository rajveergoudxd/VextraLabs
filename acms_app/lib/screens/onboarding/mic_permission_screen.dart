import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:acms_app/theme/app_theme.dart';

class MicPermissionScreen extends StatelessWidget {
  const MicPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: () => context.push('/connect-social'),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFf87171)
                              : AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Animated Mic
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                    width: 256,
                                    height: 256,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: isDark ? 0.1 : 0.05,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                  .animate(
                                    onPlay: (controller) => controller.repeat(),
                                  )
                                  .scale(
                                    duration: 2.seconds,
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1.1, 1.1),
                                  )
                                  .fadeIn(duration: 1.seconds)
                                  .fadeOut(
                                    delay: 1.seconds,
                                    duration: 1.seconds,
                                  ),

                              Container(
                                width: 192,
                                height: 192,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: isDark ? 0.2 : 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),

                              Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF331f1f)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF211111)
                                        : Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.mic,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          'Unlock Voice Power',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Control your social media workflow hands-free. Dictate ideas, schedule posts, and command your AI assistant.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? const Color(0xFFc4aead)
                                  : const Color(0xFF6b4e4e),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Features List
                        Column(
                          children: [
                            _buildFeatureCard(
                              context,
                              icon: Icons.record_voice_over,
                              title: 'Dictate captions instantly',
                              subtitle: 'Speak your thoughts into posts',
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureCard(
                              context,
                              icon: Icons.bolt,
                              title: 'Execute quick commands',
                              subtitle: '"Schedule for tomorrow at 9"',
                              isDark: isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),

                // Bottom Actions
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => context.push('/connect-social'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic),
                            SizedBox(width: 8),
                            Text(
                              'Enable Microphone',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.push('/connect-social'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? const Color(0xFFc4aead)
                              : const Color(0xFF6b4e4e),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          'Maybe Later',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We value your privacy. The microphone is only active when you tap the mic icon or say the wake word.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2c1a1a) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3d2525) : const Color(0xFFeadddd),
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
              color: isDark ? const Color(0xFF3d2222) : const Color(0xFFfcf2f2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1b0e0e),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFFc4aead)
                        : const Color(0xFF6b4e4e),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
