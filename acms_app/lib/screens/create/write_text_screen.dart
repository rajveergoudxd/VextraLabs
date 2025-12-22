import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';

class WriteTextScreen extends StatefulWidget {
  const WriteTextScreen({super.key});

  @override
  State<WriteTextScreen> createState() => _WriteTextScreenState();
}

class _WriteTextScreenState extends State<WriteTextScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Set<String> _selectedPlatforms = {'instagram'};
  String? _processingAction;

  final List<Map<String, dynamic>> _platforms = [
    {'id': 'instagram', 'name': 'Instagram', 'icon': Icons.camera_alt},
    {'id': 'linkedin', 'name': 'LinkedIn', 'icon': Icons.work},
    {'id': 'twitter', 'name': 'Twitter', 'icon': Icons.flutter_dash},
    {'id': 'facebook', 'name': 'Facebook', 'icon': Icons.facebook},
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
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CreationProvider>();
      provider.reset();
      provider.setMode('manual');
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
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

    // Simulate AI processing (replace with actual API call)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    String currentText = _textController.text;

    switch (actionId) {
      case 'expand':
        // Simulate AI expansion
        _textController.text =
            '$currentText\n\nThis is a fascinating topic that continues to shape our digital landscape. The implications are far-reaching and worth exploring further.';
        break;
      case 'shorten':
        // Simulate AI shortening
        final words = currentText.split(' ');
        if (words.length > 10) {
          _textController.text = '${words.take(10).join(' ')}...';
        }
        break;
      case 'hashtags':
        // Simulate hashtag generation
        _textController.text =
            '$currentText\n\n#ContentCreation #AI #SocialMedia #Trending #Digital';
        break;
      case 'emoji':
        // Simulate emoji addition
        _textController.text = '✨ $currentText 🚀';
        break;
    }

    setState(() {
      _processingAction = null;
    });
  }

  void _togglePlatform(String platformId) {
    setState(() {
      if (_selectedPlatforms.contains(platformId)) {
        if (_selectedPlatforms.length > 1) {
          _selectedPlatforms.remove(platformId);
        }
      } else {
        _selectedPlatforms.add(platformId);
      }
    });
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

    // Save caption for selected platforms
    final provider = context.read<CreationProvider>();
    for (final platformId in _selectedPlatforms) {
      provider.setCaption(platformId, _textController.text);
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => context.pop(),
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
          // Platform selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posting to',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _platforms.map((platform) {
                      final isSelected = _selectedPlatforms.contains(
                        platform['id'],
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _buildPlatformChip(
                          platform['name'],
                          platform['icon'],
                          isSelected,
                          () => _togglePlatform(platform['id']),
                          isDark,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Text input area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
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
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // Character count
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
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
                  onTap: () => context.push('/create/upload-media'),
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
                        'Preview & Continue',
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

  Widget _buildPlatformChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
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
}
