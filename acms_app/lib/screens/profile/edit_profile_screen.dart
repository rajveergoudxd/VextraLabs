import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/auth_provider.dart';
import 'package:acms_app/providers/social_connections_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _twitterController = TextEditingController();
  final _facebookController = TextEditingController();

  final _picker = ImagePicker();
  File? _imageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _usernameController.text = user.username ?? '';
      _bioController.text = user.bio ?? '';
      _instagramController.text = user.instagram ?? '';
      _linkedinController.text = user.linkedin ?? '';
      _twitterController.text = user.twitter ?? '';
      _facebookController.text = user.facebook ?? '';
    }
    // Load OAuth connections
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SocialConnectionsProvider>(
        context,
        listen: false,
      ).loadConnections();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleSave() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Upload image if changed
    String? profilePictureUrl;
    if (_imageFile != null) {
      setState(() => _isUploading = true);
      try {
        profilePictureUrl = await authProvider.uploadImage(_imageFile!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
        }
        setState(() => _isUploading = false);
        return;
      }
    }

    final success = await authProvider.updateProfile(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim(),
      profilePicture: profilePictureUrl,
      instagram: _instagramController.text.trim(),
      linkedin: _linkedinController.text.trim(),
      twitter: _twitterController.text.trim(),
      facebook: _facebookController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to update profile'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final connectionsProvider = Provider.of<SocialConnectionsProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.textMain,
        ),
        actions: [
          TextButton(
            onPressed: (authProvider.isLoading || _isUploading)
                ? null
                : _handleSave,
            child: authProvider.isLoading || _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Pic
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : (user?.profilePicture != null
                                ? DecorationImage(
                                    image: NetworkImage(user!.profilePicture!),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                    ),
                    child: (_imageFile == null && user?.profilePicture == null)
                        ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('Public Information', isDark),
            _buildTextField('Full Name', _fullNameController, isDark),
            _buildTextField('Username', _usernameController, isDark),
            _buildTextField('Bio', _bioController, isDark, maxLines: 3),

            const SizedBox(height: 24),

            _buildSectionHeader('Connected Platforms', isDark),
            _buildPlatformCard(
              'Instagram',
              FontAwesomeIcons.instagram,
              const Color(0xFFE1306C),
              _getConnectionUsername(connectionsProvider, 'instagram'),
              isDark,
              onConnect: () => _showConnectDialog('Instagram'),
              onDisconnect: () => _disconnectPlatform('instagram'),
              comingSoon: true,
            ),
            _buildPlatformCard(
              'LinkedIn',
              FontAwesomeIcons.linkedin,
              const Color(0xFF0077B5),
              _getConnectionUsername(connectionsProvider, 'linkedin'),
              isDark,
              onConnect: () => _showConnectDialog('LinkedIn'),
              onDisconnect: () => _disconnectPlatform('linkedin'),
            ),
            _buildPlatformCard(
              'Twitter / X',
              FontAwesomeIcons.xTwitter,
              isDark ? Colors.white : Colors.black,
              _getConnectionUsername(connectionsProvider, 'twitter'),
              isDark,
              onConnect: () => _showConnectDialog('Twitter'),
              onDisconnect: () => _disconnectPlatform('twitter'),
            ),
            _buildPlatformCard(
              'Facebook',
              FontAwesomeIcons.facebook,
              const Color(0xFF1877F2),
              _getConnectionUsername(connectionsProvider, 'facebook'),
              isDark,
              onConnect: () => _showConnectDialog('Facebook'),
              onDisconnect: () => _disconnectPlatform('facebook'),
              comingSoon: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textMain,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isDark, {
    int maxLines = 1,
    String? prefixText,
    IconData? icon,
    String? hint,
  }) {
    // Assign default icons based on label
    IconData fieldIcon = icon ?? _getIconForLabel(label);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textMain,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[600] : Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              fieldIcon,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: maxLines > 1 ? 16 : 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'full name':
        return Icons.person_outline_rounded;
      case 'username':
        return Icons.alternate_email_rounded;
      case 'bio':
        return Icons.edit_note_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }

  Widget _buildPlatformCard(
    String platformName,
    IconData icon,
    Color iconColor,
    String? connectedAccount,
    bool isDark, {
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
    bool comingSoon = false,
  }) {
    final isConnected = connectedAccount != null && connectedAccount.isNotEmpty;

    return Opacity(
      opacity: comingSoon ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConnected
                ? AppColors.primary.withValues(alpha: 0.3)
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Platform Logo
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),

            // Platform Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platformName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textMain,
                    ),
                  ),
                  if (comingSoon)
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[400],
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (isConnected)
                    Text(
                      '@$connectedAccount',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),

            // Connect/Disconnect Button or Coming Soon badge
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
            else if (isConnected)
              OutlinedButton(
                onPressed: onDisconnect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Connected',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              )
            else
              ElevatedButton(
                onPressed: onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showConnectDialog(String platform) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Connect $platform',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll be redirected to $platform to authorize Vextra to post on your behalf.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _launchOAuth(platform.toLowerCase());
                },
                icon: const Icon(Icons.open_in_browser),
                label: Text('Connect with $platform'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: OAuth setup requires backend configuration.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Get username for a connected platform
  String? _getConnectionUsername(
    SocialConnectionsProvider provider,
    String platform,
  ) {
    final connection = provider.getConnection(platform);
    if (connection != null && connection.isTokenValid) {
      return connection.platformUsername ??
          connection.platformDisplayName ??
          'Connected';
    }
    return null;
  }

  Future<void> _launchOAuth(String platform) async {
    try {
      final provider = Provider.of<SocialConnectionsProvider>(
        context,
        listen: false,
      );
      final authResponse = await provider.getAuthorizationUrl(platform);

      if (authResponse != null) {
        // The callback URL that the backend will redirect to after OAuth
        // This is a deep link that the app will catch
        final callbackUrlScheme = 'vextra';

        String? code;
        String? state;

        // Use system browser for OAuth (required for Twitter, Google sign-in on Twitter)
        // flutter_web_auth_2 uses Chrome Custom Tabs (Android) or ASWebAuthenticationSession (iOS)
        try {
          final resultUrl = await FlutterWebAuth2.authenticate(
            url: authResponse.authorizationUrl,
            callbackUrlScheme: callbackUrlScheme,
            options: const FlutterWebAuth2Options(
              preferEphemeral: true, // Don't persist cookies/session
              timeout: 120, // 2 minute timeout
            ),
          );

          // Parse the callback URL to extract code and state
          final uri = Uri.parse(resultUrl);
          code = uri.queryParameters['code'];
          state = uri.queryParameters['state'];

          // Check for errors
          final error = uri.queryParameters['error'];
          if (error != null) {
            final errorDesc = uri.queryParameters['error_description'] ?? error;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Authorization failed: $errorDesc'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } catch (e) {
          // If flutter_web_auth_2 fails (e.g., user cancelled), show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Authorization cancelled or failed: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Handle the OAuth result
        if (code != null && state != null && mounted) {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Connecting account...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );

          // Send the code to the backend
          final success = await provider.handleCallback(platform, code, state);

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${platform[0].toUpperCase()}${platform.substring(1)} connected successfully!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to connect: ${provider.error ?? "Unknown error"}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to get authorization URL: ${provider.error}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _disconnectPlatform(String platform) async {
    final provider = Provider.of<SocialConnectionsProvider>(
      context,
      listen: false,
    );

    final success = await provider.disconnect(platform);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Platform disconnected'
                : 'Failed to disconnect: ${provider.error}',
          ),
        ),
      );
    }
  }
}
