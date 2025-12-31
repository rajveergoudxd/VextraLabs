import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';

class CraftPostScreen extends StatefulWidget {
  const CraftPostScreen({super.key});

  @override
  State<CraftPostScreen> createState() => _CraftPostScreenState();
}

class _CraftPostScreenState extends State<CraftPostScreen> {
  String _activePlatform = 'Inspire';
  late TextEditingController _captionController;

  // Inspire and LinkedIn are active, others coming soon
  final List<String> _platforms = [
    'Inspire',
    'LinkedIn',
    'Instagram',
    'Facebook',
    'Twitter',
  ];

  bool _isPlatformAvailable(String platform) =>
      platform == 'Inspire' || platform == 'LinkedIn' || platform == 'Twitter';

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();

    // Initialize with existing caption if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CreationProvider>(context, listen: false);
      _captionController.text = provider.captions[_activePlatform] ?? '';
    });

    _captionController.addListener(() {
      final provider = Provider.of<CreationProvider>(context, listen: false);
      provider.setCaption(_activePlatform, _captionController.text);
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _switchPlatform(String platform) {
    // Only allow switching to LinkedIn - others are coming soon
    if (!_isPlatformAvailable(platform)) {
      _showComingSoonSnackbar(platform);
      return;
    }
    setState(() {
      _activePlatform = platform;
    });
    final provider = Provider.of<CreationProvider>(context, listen: false);
    _captionController.text = provider.captions[platform] ?? '';
  }

  void _showComingSoonSnackbar(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('$platform support coming soon!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final creationProvider = Provider.of<CreationProvider>(context);
    final selectedMedia = creationProvider.selectedMedia;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Text(
                        'Craft Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Platform Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _platforms
                      .map((p) => _buildPlatformTab(p))
                      .toList(),
                ),
              ),
              const Divider(height: 1),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Caption Area
                      _buildSectionHeader(
                        context,
                        '$_activePlatform Caption',
                        isDark,
                        action: 'Rewrite',
                        icon: Icons.auto_awesome,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _captionController,
                              maxLines: 6,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Write a catchy caption for $_activePlatform...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[400],
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildIconButton(
                                    Icons.emoji_emotions_outlined,
                                    isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildIconButton(
                                    Icons.mic,
                                    isDark,
                                    isPrimary: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ideally 130-150 chars',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text(
                              '${_captionController.text.length} / 2200',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Hashtags
                      _buildSectionHeader(
                        context,
                        'Hashtags',
                        isDark,
                        action: 'Generate',
                        icon: Icons.tag,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tag, color: Colors.grey[400], size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Add hashtags...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['#picoftheday', '#visuals', '#creative']
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                backgroundColor: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                side: BorderSide(color: Colors.grey[300]!),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 24),

                      // Attached Media Preview
                      _buildSectionHeader(context, 'Attached Media', isDark),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedMedia.length + 1,
                          itemBuilder: (context, index) {
                            if (index == selectedMedia.length) {
                              return Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_photo_alternate,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildMediaImage(selectedMedia[index]),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        foregroundColor: isDark ? Colors.white : Colors.black,
                      ),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => context.push('/create/review'),
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
                            'Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
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

  Widget _buildPlatformTab(String title) {
    // Basic mapping for icons
    IconData icon;
    if (title == 'Inspire') {
      icon = Icons.auto_awesome;
    } else if (title == 'Instagram') {
      icon = Icons.camera_alt;
    } else if (title == 'Facebook') {
      icon = Icons.public;
    } else if (title == 'Twitter') {
      icon = Icons.flutter_dash;
    } else if (title == 'LinkedIn') {
      icon = Icons.business_center;
    } else {
      icon = Icons.public;
    }

    final isActive = _activePlatform == title;
    final isAvailable = _isPlatformAvailable(title);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors based on availability
    final Color iconColor;
    final Color textColor;

    if (!isAvailable) {
      // Greyed out for unavailable platforms
      iconColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
      textColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
    } else if (isActive) {
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    } else {
      iconColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
      textColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }

    return GestureDetector(
      onTap: () => _switchPlatform(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive && isAvailable
                  ? AppColors.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor, size: 20),
                // "Soon" badge for unavailable platforms
                if (!isAvailable)
                  Positioned(
                    right: -20,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive && isAvailable
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    bool isDark, {
    String? action,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
            letterSpacing: 1,
          ),
        ),
        if (action != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: 14),
                  const SizedBox(width: 4),
                ],
                Text(
                  action,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildIconButton(
    IconData icon,
    bool isDark, {
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primary.withValues(alpha: 0.1)
            : (isDark ? Colors.grey[800] : Colors.grey[100]),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isPrimary ? AppColors.primary : Colors.grey[600],
        size: 20,
      ),
    );
  }

  /// Helper to display media from either local file path or network URL
  Widget _buildMediaImage(String path) {
    // Check if it's a local file path
    if (path.startsWith('/') || path.startsWith('file://')) {
      return Image.file(
        File(path.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      // Network URL
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }
}
