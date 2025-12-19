import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acms_app/theme/app_theme.dart';

class GalleryPermissionScreen extends StatelessWidget {
  const GalleryPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go('/create-account'),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      foregroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Hero Icon
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              transform: Matrix4.diagonal3Values(
                                1.25,
                                1.25,
                                1,
                              ), // Scale
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.photo_library,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[100]!,
                              ),
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mic,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Unlock Automated Content',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'We need access to your gallery to let our voice-activated AI draft posts for you instantly. Your photos remain private until you choose to publish.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Features Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2a1a1a) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildFeatureItem(
                            context,
                            'Auto-select best shots for engagement',
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(
                            context,
                            'Sync video clips for smart editing',
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(
                            context,
                            'No manual uploading required',
                            isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Gallery Preview Grid
                    Opacity(
                      opacity:
                          0.6, // Base opacity (hover effect not implemented on mobile, maybe on tap)
                      child: Column(
                        children: [
                          Text(
                            'YOUR FUTURE FEED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildGalleryItem(
                                  "https://lh3.googleusercontent.com/aida-public/AB6AXuAVVEJVApA_yu9SCBEKnZNiYyVSsCX-ZwSyjPOzrNPuKaOJoxPkybXLWWQAaVyOtzReT-zJbUNkK_aP3g4KbjRKPnBpLIYP-gUeLGi-xn78DGVud6h8gPPiubpWhHhC5w4TxKqMB-E8V1nvolzfkSBE--g9Dej5TUUNzhatY8eSMAS7APzA4PHa3Z1X6zSD8iJmz6M3VLOj9Vb_CQjniZk_QygD7rBXr9OuTP-w6u4DUU32BGoLRsbVXtu21lpJON6AZMqtBnwNQQE",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildGalleryItem(
                                  "https://lh3.googleusercontent.com/aida-public/AB6AXuDZQf6xekVAbx90fGZF5SNVD-O2a1d1w1kctrmtx8DQv4W2P7AJO4hngoxy7lBgX9gAOpZQdnLUIRYSdKwUmDoVKZksXjAvOVuJKqV4D8G8ymJCUtJmabOkDfTPBESR0TpCSSgRC6DX5EAsS5CQ421iUlo4vPIfE4v43Y64akZNRcdprPUU0lYH6upnynt_2qzp2V54whKblwaIfHMqqDT5piCNPk-ILvlHGe3hZ_W-8iJ8P63Z5DNda3Tur-wesTdSqz_lD5U-P_A",
                                  isVideo: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildGalleryItem(
                                  "https://lh3.googleusercontent.com/aida-public/AB6AXuDR9tQEiUmrGyFQl62VjofcqYr0c_fNHCE79dpOhPR0oZbuIu3jTeR82B1wj5HkKE5tcvArltJJcXvLf3Fn6chhgWCFSEQxvELrqZB4ttEP02V7S5C2o3t5XdSP5RkLnNo1lBtPeVfUBpPpPiFjuGSB3f_g92BzTxP0wKf6thddYGM8URF0MNMlzQlNY0EjrjUVPO1oAuf7LwXtOUaxApCXjX3wtQExzPYsHgrRkyzTXONiO2weXhrkHXItoJnC4IR7ER8gUXWhn3Q",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), // Bottom padding for buttons
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
                  .withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/mic-permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.red.withValues(alpha: 0.3),
              ),
              child: const Text(
                'Allow Gallery Access',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/mic-permission'),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.grey[400] : Colors.grey[500],
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text(
                'Maybe Later',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'Your data is encrypted and never shared without permission.',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text, bool isDark) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[200] : AppColors.textMain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryItem(String url, {bool isVideo = false}) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
            if (isVideo)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Center(
                  child: Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
