import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';

class ReviewPublishScreen extends StatelessWidget {
  const ReviewPublishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final creationProvider = Provider.of<CreationProvider>(context);
    final isManual = creationProvider.mode == 'manual';
    final captions = creationProvider.captions;
    final selectedMedia = creationProvider.selectedMedia;

    // Default image if none selected (shouldn't happen in manual flow if guarded correctly)
    final displayImage = selectedMedia.isNotEmpty
        ? selectedMedia.first
        : "https://lh3.googleusercontent.com/aida-public/AB6AXuCNMaqYoRJ9KyycTlyzur1QQZ5ZbkhWh4vbPkS3hpwf3Fi8p0dwT5HL6g_ruqCTYO7jiVcHBx2BdlaJ7pVS0YDPDfcRS6tD_L65i1DQoAv98D9iqwAnROFN4qU4lp5HpsPdI_RVIqjCS-ZxGPjYpk77cB0ovfyvEWwRpznWeZe1i2_7wYs2tGBt7DUJTfVvgGCyCk-IVz1rrxbGEHmL8bubYWdDgRacEFHWoUths9575rnYpofgGBhJRA8sEA4InJxUe8OVoJCTfcc";

    // Platforms to show
    final platforms = [
      {
        'name': 'Instagram',
        'icon': Icons.camera_alt,
        'color': const Color(0xFFE1306C),
      },
      {
        'name': 'Facebook',
        'icon': Icons.public,
        'color': const Color(0xFF1877F2),
      },
      {
        'name': 'X (Twitter)',
        'icon': Icons.flutter_dash,
        'color': Colors.black,
        'darkIcon': true,
      },
      {
        'name': 'LinkedIn',
        'icon': Icons.business_center,
        'color': const Color(0xFF0077b5),
      },
    ];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
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
                      Expanded(
                        child: Text(
                          'Review & Publish',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isManual ? Icons.edit : Icons.auto_awesome,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isManual
                                        ? 'Your Manual Drafts'
                                        : 'AI Generated 3 Drafts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    isManual
                                        ? 'Review your final crafted posts.'
                                        : 'Based on your selected media.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        ...platforms.map((platform) {
                          final name = platform['name'] as String;
                          // Simplify platform key matching for captions (e.g. "X (Twitter)" -> "Twitter")
                          String key = name;
                          if (name.contains('Twitter')) key = 'Twitter';

                          final content = captions[key] ?? '';
                          // Only show if there is content or media (for manual mode, usually we show all or selected)
                          // For now layout all, but maybe empty state if no text?
                          // Let's show all for preview consistency.

                          return _buildPostCard(
                            context,
                            platform: name,
                            icon: platform['icon'] as IconData,
                            color: platform['color'] as Color,
                            content: content.isEmpty
                                ? 'No caption drafted.'
                                : content,
                            image:
                                displayImage, // potentially use filter-edited image if I stored it
                            darkIcon: platform['darkIcon'] == true,
                            isDark: isDark,
                            mediaCount: selectedMedia.length,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24,
              ), // Consistent bottom margin
              decoration: BoxDecoration(
                color:
                    (isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight)
                        .withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(), // Go back to edit
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => context.push('/create/success'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Publish All',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.rocket_launch, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context, {
    required String platform,
    required IconData icon,
    required Color color,
    required String content,
    required String image,
    bool darkIcon = false,
    required bool isDark,
    int mediaCount = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: darkIcon && !isDark
                        ? Colors.black
                        : (darkIcon && isDark ? Colors.white : color),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: darkIcon && isDark ? Colors.black : Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  platform,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                Icon(Icons.more_horiz, color: Colors.grey[400]),
              ],
            ),
          ),

          // Image (Carousel indicator if multiple)
          Stack(
            children: [
              ColorFiltered(
                // Simple hack: if there was a filter on this specific image in global state, we would apply it here.
                // For now, raw image.
                colorFilter: const ColorFilter.mode(
                  Colors.transparent,
                  BlendMode.dst,
                ),
                child: CachedNetworkImage(
                  imageUrl: image,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (mediaCount > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.copy, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '1/$mediaCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed:
                          () {}, // Could navigate back to CraftPostScreen with this platform active
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[500],
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.success,
                        ),
                        label: const Text('Ready'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
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
