import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';

class PublishedSuccessScreen extends StatelessWidget {
  const PublishedSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final creationProvider = Provider.of<CreationProvider>(context);
    final results =
        creationProvider.publishResults?['results'] as Map<String, dynamic>?;

    // Build platform status list
    final platformResults = <Map<String, dynamic>>[];
    if (results != null) {
      results.forEach((platform, result) {
        platformResults.add({
          'name':
              platform.substring(0, 1).toUpperCase() + platform.substring(1),
          'success': result['success'] == true,
          'error': result['error'],
        });
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Animation
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: 2.seconds,
                      ),

                  Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x6622c55e),
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 80,
                      color: Colors.white,
                    ),
                  ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                ],
              ),

              const SizedBox(height: 48),

              Text(
                'Published!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ).animate().fadeIn().moveY(begin: 20, end: 0),

              const SizedBox(height: 24),

              // Platform Results
              if (platformResults.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: platformResults.map((result) {
                      final isSuccess = result['success'] as bool;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              isSuccess ? Icons.check_circle : Icons.error,
                              color: isSuccess ? AppColors.success : Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result['name'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  if (!isSuccess && result['error'] != null)
                                    Text(
                                      result['error'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red[400],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
              ] else
                Text(
                  'Your content is now live!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  creationProvider.reset();
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
