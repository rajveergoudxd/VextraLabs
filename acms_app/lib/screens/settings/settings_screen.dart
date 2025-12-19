import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/theme/theme_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Section
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
                      border: Border.all(color: AppColors.primary, width: 2),
                      image: const DecorationImage(
                        image: CachedNetworkImageProvider(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuBE8gEfC22IC2P_14syVYuERNKwUwvSAIyPiBvg0_Oa-eigjB1ZzpNjS1-S20iTfb7ZsB32GEO_Nn2JZ9cDhU1cRjmP43vwNw_9O5o1aG_5eEb-JRZ4Eo5MnghLPMfUKKdprq8JzSl8in70xPT6soLcuTMrJpAQFkHDjvS8afakvrhqliyMFpEQJbID7HiVEM0FoAKO6ia5WhFkkQX0ADGnOv53KsGwkskB8SiCwI8fHtQjcseuY4OAkcNSeZgmtNv6DwdlGdVgqqs",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sarah Jenkins',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textMain,
                          ),
                        ),
                        const Text(
                          'Pro Plan Member',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
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
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // AI Workflows
            _buildSectionHeader('AI WORKFLOWS'),
            _buildSettingsContainer(isDark, [
              _buildSettingsItem(
                context,
                icon: Icons.mic,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                title: 'Voice Command',
                subtitle: '"Hey AI, post to Twitter"',
                trailing: Switch(
                  value: true,
                  onChanged: (v) {},
                  activeTrackColor: AppColors.primary,
                ),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSettingsItem(
                context,
                icon: Icons.psychology,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                title: 'Content Tone Defaults',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                isDark: isDark,
              ),
            ]),

            const SizedBox(height: 16),

            // Account
            _buildSectionHeader('ACCOUNT'),
            _buildSettingsContainer(isDark, [
              _buildSettingsItem(
                context,
                icon: Icons.person,
                title: 'Personal Info',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSettingsItem(
                context,
                icon: Icons.lock,
                title: 'Security',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSettingsItem(
                context,
                icon: Icons.credit_card,
                title: 'Subscription',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                isDark: isDark,
              ),
            ]),

            const SizedBox(height: 16),

            // Preferences
            _buildSectionHeader('PREFERENCES'),
            _buildSettingsContainer(isDark, [
              _buildSettingsItem(
                context,
                icon: Icons.notifications,
                title: 'Notifications',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                isDark: isDark,
                onTap: () => _showThemePicker(context),
              ),
              _buildDivider(isDark),
              _buildSettingsItem(
                context,
                icon: Icons.shield,
                title: 'Privacy & Data',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                isDark: isDark,
              ),
            ]),

            const SizedBox(height: 24),

            // Logout
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'Version 2.4.0 (Build 302)',
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

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(
        height: 1,
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
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
              _buildThemeOption(context, 'System Default', ThemeMode.system),
              _buildThemeOption(context, 'Light Mode', ThemeMode.light),
              _buildThemeOption(context, 'Dark Mode', ThemeMode.dark),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, ThemeMode mode) {
    final isSelected = themeManager.themeMode == mode;
    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        themeManager.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }
}
