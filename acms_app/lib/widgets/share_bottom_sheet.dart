import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:acms_app/providers/inspire_provider.dart';
import 'package:acms_app/theme/app_theme.dart';

/// Bottom sheet for sharing a post via chat, link, or other apps
class ShareBottomSheet extends StatefulWidget {
  final int postId;
  final String? postContent;
  final String? postImageUrl;

  const ShareBottomSheet({
    super.key,
    required this.postId,
    this.postContent,
    this.postImageUrl,
  });

  /// Show the share bottom sheet
  static Future<void> show(
    BuildContext context, {
    required int postId,
    String? postContent,
    String? postImageUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        postId: postId,
        postContent: postContent,
        postImageUrl: postImageUrl,
      ),
    );
  }

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  bool _isLoading = false;
  String? _shareUrl;

  Future<void> _getShareLink() async {
    if (_shareUrl != null) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<InspireProvider>(context, listen: false);
      final data = await provider.getShareLink(widget.postId);
      setState(() {
        _shareUrl = data['web_url'] ?? data['share_url'];
      });
    } catch (e) {
      debugPrint('Failed to get share link: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _getShareLink();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Share Post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),

            const Divider(height: 1),

            // Share options
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Share to Chat
                  _buildShareOption(
                    icon: Icons.chat_bubble_outline,
                    title: 'Share to Chat',
                    subtitle: 'Send to a conversation',
                    onTap: () => _shareToChat(context),
                    isDark: isDark,
                  ),

                  // Copy Link
                  _buildShareOption(
                    icon: Icons.link,
                    title: 'Copy Link',
                    subtitle: _isLoading
                        ? 'Getting link...'
                        : 'Copy shareable link',
                    onTap: _isLoading ? null : () => _copyLink(context),
                    isDark: isDark,
                  ),

                  // Share to Other Apps
                  _buildShareOption(
                    icon: Icons.share_outlined,
                    title: 'Share to Other Apps',
                    subtitle: 'Open system share sheet',
                    onTap: _isLoading ? null : () => _shareToOtherApps(context),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      onTap: onTap,
    );
  }

  void _shareToChat(BuildContext context) {
    Navigator.pop(context);
    // Navigate to chat share screen with post info
    context.push(
      '/chats/share',
      extra: {
        'postId': widget.postId,
        'postContent': widget.postContent,
        'postImageUrl': widget.postImageUrl,
      },
    );
  }

  void _copyLink(BuildContext context) {
    if (_shareUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to get share link')));
      return;
    }

    Clipboard.setData(ClipboardData(text: _shareUrl!));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Link copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareToOtherApps(BuildContext context) {
    if (_shareUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to get share link')));
      return;
    }

    Navigator.pop(context);

    final shareText = widget.postContent != null
        ? '${widget.postContent}\n\n$_shareUrl'
        : 'Check out this post on Vextra!\n$_shareUrl';

    SharePlus.instance.share(
      ShareParams(text: shareText, subject: 'Check out this post on Vextra!'),
    );
  }
}
