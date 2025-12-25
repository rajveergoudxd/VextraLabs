import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class WriteTextScreen extends StatefulWidget {
  const WriteTextScreen({super.key});

  @override
  State<WriteTextScreen> createState() => _WriteTextScreenState();
}

class _WriteTextScreenState extends State<WriteTextScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _processingAction;
  final ImagePicker _picker = ImagePicker();

  // Platform state
  String _activePlatform = 'Inspire';
  final List<String> _platforms = [
    'Inspire',
    'LinkedIn',
    'Instagram',
    'Facebook',
    'Twitter',
  ];

  final List<Map<String, dynamic>> _aiActions = [
    {'id': 'expand', 'label': 'Expand', 'icon': Icons.unfold_more_rounded},
    {'id': 'shorten', 'label': 'Shorten', 'icon': Icons.unfold_less_rounded},
    {'id': 'hashtags', 'label': 'Hashtags', 'icon': Icons.tag_rounded},
    {'id': 'emoji', 'label': 'Emoji', 'icon': Icons.emoji_emotions_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CreationProvider>();

      // Don't reset if we have content (e.g. returning from review)
      // But user requested "Write Text" workflow usually starts fresh.
      // However, if we just selected media internally, we don't want to reset.
      // For now, assuming entry from Home resets, but staying here preserves state.
      if (provider.captions.isEmpty) {
        provider.reset();
        provider.setMode('manual');
      }

      // Initialize text from provider for active platform
      _textController.text = provider.captions[_activePlatform] ?? '';
      _focusNode.requestFocus();
    });

    _textController.addListener(_syncCaption);
  }

  @override
  void dispose() {
    _textController.removeListener(_syncCaption);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncCaption() {
    final provider = context.read<CreationProvider>();
    provider.setCaption(_activePlatform, _textController.text);
  }

  bool _isPlatformAvailable(String platform) =>
      platform == 'Inspire' || platform == 'LinkedIn';

  void _switchPlatform(String platform) {
    if (!_isPlatformAvailable(platform)) {
      _showComingSoonSnackbar(platform);
      return;
    }

    setState(() {
      _activePlatform = platform;
    });

    // Update text field with caption for the new platform
    final provider = context.read<CreationProvider>();
    _textController.text = provider.captions[platform] ?? '';
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

  void _handleAiAction(String actionId) async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write some text first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _processingAction = actionId;
    });

    // Simulate AI processing
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    String currentText = _textController.text;

    switch (actionId) {
      case 'expand':
        _textController.text =
            '$currentText\n\nThis is a fascinating topic that continues to shape our digital landscape. The implications are far-reaching and worth exploring further.';
        break;
      case 'shorten':
        final words = currentText.split(' ');
        if (words.length > 10) {
          _textController.text = '${words.take(10).join(' ')}...';
        }
        break;
      case 'hashtags':
        _textController.text =
            '$currentText\n\n#ContentCreation #AI #SocialMedia #Trending #Digital';
        break;
      case 'emoji':
        _textController.text = '✨ $currentText 🚀';
        break;
    }

    setState(() {
      _processingAction = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && mounted) {
        final provider = context.read<CreationProvider>();
        provider.toggleMediaSelection(image.path);
        // Force rebuild to show media
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showMediaSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _continueToPreview() {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write some content first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Ensure current text is saved
    final provider = context.read<CreationProvider>();
    provider.setCaption(_activePlatform, _textController.text);

    // Also save for other available platforms if empty?
    // Usually good UX to propagate to other active platforms if they are empty
    if (_isPlatformAvailable('LinkedIn') &&
        (provider.captions['LinkedIn']?.isEmpty ?? true)) {
      provider.setCaption('LinkedIn', _textController.text);
    }
    if (_isPlatformAvailable('Inspire') &&
        (provider.captions['Inspire']?.isEmpty ?? true)) {
      provider.setCaption('Inspire', _textController.text);
    }

    context.push('/create/review');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textMain;

    final provider = context.watch<CreationProvider>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () {
            // Reset checking?
            context.pop();
          },
        ),
        title: Text(
          'Write Post',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _continueToPreview,
            child: Text(
              'Preview',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Platform Tabs
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _platforms
                    .map((p) => _buildPlatformTab(p, isDark))
                    .toList(),
              ),
            ),
          ),

          // Main Editor Area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Input
                  Container(
                    margin: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(minHeight: 200),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 8,
                      // expands: true, // Cannot use expands with SingleChildScrollView
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            "What's on your mind? Start writing and use AI to enhance your content...",
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  // Character count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${_textController.text.length} characters',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Manual Hashtags Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, 'Hashtags', isDark),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tag,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Add hashtags...',
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(color: textColor),
                                  onSubmitted: (value) {
                                    if (value.isNotEmpty) {
                                      _textController.text =
                                          "${_textController.text} #$value";
                                      setState(() {}); // refresh
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Attached Media Section
                  if (provider.selectedMedia.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            context,
                            'Attached Media',
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: provider.selectedMedia.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildMediaImage(
                                          provider.selectedMedia[index],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () {
                                          provider.toggleMediaSelection(
                                            provider.selectedMedia[index],
                                          );
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),

          // AI Toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI Enhance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _aiActions.map((action) {
                    final isActive = _processingAction == action['id'];
                    return _buildAiActionButton(
                      action['icon'],
                      action['label'],
                      () => _handleAiAction(action['id']),
                      isDark,
                      isProcessing: isActive,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                // Attach media
                InkWell(
                  onTap: _showMediaSourceSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add Media',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Continue button
                ElevatedButton(
                  onPressed: _textController.text.isEmpty
                      ? null
                      : _continueToPreview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 18),
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

  Widget _buildPlatformTab(String platform, bool isDark) {
    // Basic mapping for icons
    IconData icon;
    if (platform == 'Inspire') {
      icon = Icons.auto_awesome;
    } else if (platform == 'Instagram') {
      icon = Icons.camera_alt;
    } else if (platform == 'Facebook') {
      icon = Icons.public;
    } else if (platform == 'Twitter') {
      icon = Icons.flutter_dash;
    } else if (platform == 'LinkedIn') {
      icon = Icons.business_center;
    } else {
      icon = Icons.public;
    }

    final isActive = _activePlatform == platform;
    final isAvailable = _isPlatformAvailable(platform);

    // Colors based on availability
    final Color iconColor;
    final Color textColor;

    if (!isAvailable) {
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
      onTap: () => _switchPlatform(platform),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              platform,
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

  Widget _buildAiActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isDark, {
    bool isProcessing = false,
  }) {
    return InkWell(
      onTap: isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
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
      ],
    );
  }

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
