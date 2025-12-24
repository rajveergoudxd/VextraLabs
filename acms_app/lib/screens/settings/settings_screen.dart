import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/theme/theme_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/auth_provider.dart';
import 'package:acms_app/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to theme changes to rebuild UI
    themeManager.addListener(_onThemeChanged);
    // Load settings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).loadSettings();
    });
  }

  @override
  void dispose() {
    themeManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsProvider.isLoading && settingsProvider.settings.id == 0
          ? const Center(child: CircularProgressIndicator())
          : settingsProvider.error != null && settingsProvider.settings.id == 0
          ? _buildErrorState(isDark, settingsProvider)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Section - Real user data
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.transparent : Colors.grey[100]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            image: user?.profilePicture != null
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      user!.profilePicture!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: user?.profilePicture == null
                              ? Icon(
                                  Icons.person,
                                  size: 30,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'User',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textMain,
                                ),
                              ),
                              if (user?.email != null)
                                Text(
                                  user!.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_square,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                          onPressed: () => context.push('/edit-profile'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Account
                  _buildSectionHeader('ACCOUNT'),
                  _buildSettingsContainer(isDark, [
                    _buildSettingsItem(
                      context,
                      icon: Icons.person,
                      title: 'Personal Info',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      isDark: isDark,
                      onTap: () => context.push('/edit-profile'),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsItem(
                      context,
                      icon: Icons.lock,
                      title: 'Change Password',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      isDark: isDark,
                      onTap: () => context.push('/settings/change-password'),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Preferences
                  _buildSectionHeader('PREFERENCES'),
                  _buildSettingsContainer(isDark, [
                    _buildSettingsItem(
                      context,
                      icon: Icons.notifications,
                      title: 'Push Notifications',
                      trailing: Switch(
                        value: settingsProvider.pushNotificationsEnabled,
                        onChanged: settingsProvider.isLoading
                            ? null
                            : (value) async {
                                await settingsProvider.updatePushNotifications(
                                  value,
                                );
                              },
                        // ignore: deprecated_member_use
                        activeColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                      ),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSettingsItem(
                      context,
                      icon: Icons.palette,
                      title: 'Theme',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            themeManager.themeMode == ThemeMode.system
                                ? 'System'
                                : (themeManager.themeMode == ThemeMode.dark
                                      ? 'Dark'
                                      : 'Light'),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      isDark: isDark,
                      onTap: () => _showThemePicker(context, settingsProvider),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsItem(
                      context,
                      icon: Icons.shield,
                      title: 'Privacy & Data',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      isDark: isDark,
                      onTap: () => context.push('/settings/privacy'),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Logout
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Reset settings
                      settingsProvider.reset();
                      // Logout user
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                      backgroundColor: isDark
                          ? AppColors.surfaceDark
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey[100]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required bool isDark,
    Color? iconColor,
    Color? iconBgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(
                  iconBgColor != null ? 8 : 0,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color:
                    iconColor ?? (isDark ? Colors.grey[300] : Colors.grey[600]),
              ),
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
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textMain,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, SettingsProvider settingsProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              settingsProvider.clearError();
              settingsProvider.loadSettings();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(
        height: 1,
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
      ),
    );
  }

  void _showThemePicker(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Select Theme',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                context,
                settingsProvider,
                'System Default',
                ThemeMode.system,
                'system',
              ),
              _buildThemeOption(
                context,
                settingsProvider,
                'Light Mode',
                ThemeMode.light,
                'light',
              ),
              _buildThemeOption(
                context,
                settingsProvider,
                'Dark Mode',
                ThemeMode.dark,
                'dark',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    SettingsProvider settingsProvider,
    String title,
    ThemeMode mode,
    String preference,
  ) {
    final isSelected = themeManager.themeMode == mode;
    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        // Update locally immediately
        themeManager.setThemeMode(mode);
        Navigator.pop(context);
        // Sync to backend
        settingsProvider.updateThemePreference(preference);
      },
    );
  }
}
