import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/social_connections_provider.dart';

class ConnectSocialScreen extends StatefulWidget {
  const ConnectSocialScreen({super.key});

  @override
  State<ConnectSocialScreen> createState() => _ConnectSocialScreenState();
}

class _ConnectSocialScreenState extends State<ConnectSocialScreen> {
  bool _isConnecting = false;
  String? _connectingPlatform;

  Future<void> _connectPlatform(String platform) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _connectingPlatform = platform;
    });

    try {
      final provider = Provider.of<SocialConnectionsProvider>(
        context,
        listen: false,
      );
      final authResponse = await provider.getAuthorizationUrl(platform);

      if (authResponse == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start $platform connection')),
          );
        }
        return;
      }

      // Use flutter_web_auth_2 to handle OAuth in external browser
      final result = await FlutterWebAuth2.authenticate(
        url: authResponse.authorizationUrl,
        callbackUrlScheme: 'vextra',
      );

      // Parse the callback URL to extract code and state
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];

      if (code != null && state != null) {
        final success = await provider.handleCallback(platform, code, state);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$platform connected successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to connect $platform')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('OAuth error for $platform: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection cancelled or failed')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingPlatform = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectionsProvider = Provider.of<SocialConnectionsProvider>(context);

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
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "STEP 2 OF 3",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.red[200] : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
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
                      icon: FontAwesomeIcons.instagram,
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
                      icon: FontAwesomeIcons.facebook,
                      color: const Color(0xFF1877F2),
                      isDark: isDark,
                      comingSoon: true,
                    ),
                    const SizedBox(height: 12),
                    _buildSocialItem(
                      context,
                      name: 'X (Twitter)',
                      desc: 'Tweets & Threads',
                      icon: FontAwesomeIcons.xTwitter,
                      color: isDark ? Colors.white : Colors.black,
                      iconColor: isDark ? Colors.black : Colors.white,
                      isDark: isDark,
                      platform: 'twitter',
                      isConnected: connectionsProvider.isConnected('twitter'),
                      isConnecting:
                          _isConnecting && _connectingPlatform == 'twitter',
                      onConnect: () => _connectPlatform('twitter'),
                    ),
                    const SizedBox(height: 12),
                    _buildSocialItem(
                      context,
                      name: 'LinkedIn',
                      desc: 'Personal & Company',
                      icon: FontAwesomeIcons.linkedin,
                      color: const Color(0xFF0077b5),
                      isDark: isDark,
                      platform: 'linkedin',
                      isConnected: connectionsProvider.isConnected('linkedin'),
                      isConnecting:
                          _isConnecting && _connectingPlatform == 'linkedin',
                      onConnect: () => _connectPlatform('linkedin'),
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
                    onPressed: _isConnecting
                        ? null
                        : () => context.go('/onboarding-success'),
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
                    onPressed: _isConnecting
                        ? null
                        : () => context.go('/onboarding-success'),
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

  Widget _buildSocialItem(
    BuildContext context, {
    required String name,
    required String desc,
    required IconData icon,
    Color? color,
    LinearGradient? gradient,
    Color iconColor = Colors.white,
    required bool isDark,
    bool comingSoon = false,
    String? platform,
    bool isConnected = false,
    bool isConnecting = false,
    VoidCallback? onConnect,
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
              child: Center(
                child: icon.fontFamily?.contains('FontAwesome') == true
                    ? FaIcon(icon, color: iconColor, size: 28)
                    : Icon(icon, color: iconColor, size: 28),
              ),
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
            else if (isConnecting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isConnected)
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
                onPressed: onConnect,
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
