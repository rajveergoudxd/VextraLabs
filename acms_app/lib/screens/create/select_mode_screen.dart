import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';

class SelectModeScreen extends StatefulWidget {
  const SelectModeScreen({super.key});

  @override
  State<SelectModeScreen> createState() => _SelectModeScreenState();
}

class _SelectModeScreenState extends State<SelectModeScreen> {
  final _options = [
    {
      'id': 'manual',
      'title': 'Completely Manual',
      'desc': 'Full control. Create content from scratch manually.',
      'icon': Icons.edit_document,
      'bg':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDM8G3eU4oVj-f9hkkBPf681RryzFci75IFV0zqSXbdUBjQ3BNeNw7giHm3Wv5A-AflZfnRGJVkwBdTDHYEaYGqTIpQiMxCrXZDHyQJL4vdq-gnF6PB5j-Bu7mTpfbQXDlt8QyvPz_DgMEjDadOyclFQ1kIghNKSfOqgzDNk63Bm1vSyA8IKE-ZDmKIQoaftcbCp4FveuS0ZuB4fnOK6DAfQuqQAxXdHUj2JmUU8rtk7wR48NSMcdJVrQ07mgQ-1VVTQBUd5k0J1rk',
    },
    {
      'id': 'auto',
      'title': 'Completely Automatic',
      'desc': 'Hands-free. AI handles creation & publishing.',
      'icon': Icons.smart_toy,
      'bg':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCNMaqYoRJ9KyycTlyzur1QQZ5ZbkhWh4vbPkS3hpwf3Fi8p0dwT5HL6g_ruqCTYO7jiVcHBx2BdlaJ7pVS0YDPDfcRS6tD_L65i1DQoAv98D9iqwAnROFN4qU4lp5HpsPdI_RVIqjCS-ZxGPjYpk77cB0ovfyvEWwRpznWeZe1i2_7wYs2tGBt7DUJTfVvgGCyCk-IVz1rrxbGEHmL8bubYWdDgRacEFHWoUths9575rnYpofgGBhJRA8sEA4InJxUe8OVoJCTfcc',
    },
    {
      'id': 'review',
      'title': 'Automated with Review',
      'desc': 'AI drafts, you refine. The best of both worlds.',
      'icon': Icons.fact_check,
      'bg':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA-rqku9JDtqVicZcbrqao2ZHc3Me8jCrClp11UUaej2HQLfZFu0v5bYZeKBipe_h_Dx40BeXi7WhkROVmAF7_9pEc1Q5Tsb3M_uMAfdvCfqOlSjIA9MfSC1M3TpsI73aEmE1PEPGpyOTjL57kmEl9T-PeRujc2OemaGYkbhxZnPjkUov9gdQgJHi08BmVrRBTDHb0axXNJxGpz0fyGYbuFbUgsMEpMrFgaaMbU-HEDHkyJKBooFoyu_wnovzDh9hsm-RNGSR_6-qc',
      'recommended': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final creationProvider = Provider.of<CreationProvider>(context);
    final selectedId = creationProvider.mode;

    return Scaffold(
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
                          'Create New Post',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // Balance
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Select Creation Mode',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose the level of AI automation for your workflow.',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        ..._options.map(
                          (opt) => _buildOptionCard(
                            context,
                            id: opt['id'] as String,
                            title: opt['title'] as String,
                            desc: opt['desc'] as String,
                            icon: opt['icon'] as IconData,
                            bg: opt['bg'] as String,
                            recommended: (opt['recommended'] as bool?) ?? false,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Voice Control Hint
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'VOICE CONTROL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[200]!,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        creationProvider.setMode('auto');
                                        Future.delayed(500.ms, () {
                                          if (context.mounted) {
                                            context.push(
                                              '/create/select-media',
                                            );
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.mic,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text.rich(
                                      TextSpan(
                                        text: 'Try saying ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: '"Start auto mode"',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                16,
                16,
                16,
                24,
              ), // Added bottom margin
              color:
                  (isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight)
                      .withValues(alpha: 0.9),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  disabledForegroundColor: isDark
                      ? Colors.grey[600]
                      : Colors.grey[400],
                  minimumSize: const Size(
                    double.infinity,
                    52,
                  ), // Concise height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: selectedId != null ? 8 : 0,
                  shadowColor: selectedId != null
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : null,
                ),
                onPressed: selectedId != null
                    ? () {
                        if (selectedId == 'manual') {
                          context.push('/create/select-media');
                        } else {
                          // Auto or Review modes -> Show Bottom Sheet
                          _showMediaSourceSheet(context);
                        }
                      }
                    : null,
                child: Text(
                  selectedId != null ? 'Continue' : 'Select a mode to continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaSourceSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final creationProvider = Provider.of<CreationProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Media Source',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textMain,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSheetOption(
              context,
              title: 'Pick from Gallery',
              icon: Icons.photo_library,
              isDark: isDark,
              onTap: () {
                creationProvider.setMediaType('gallery');
                context.pop(); // Close sheet
                context.push('/create/select-media');
              },
            ),
            const SizedBox(height: 12),
            _buildSheetOption(
              context,
              title: 'Auto-Select Recent',
              icon: Icons.auto_awesome_motion,
              isDark: isDark,
              isAuto: true,
              onTap: () {
                creationProvider.setMediaType('auto');
                context.pop(); // Close sheet
                context.push('/create/ai-generation');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    bool isAuto = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isAuto
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: isAuto
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isAuto
                  ? AppColors.primary
                  : (isDark ? Colors.white : Colors.grey[700]),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isAuto
                    ? AppColors.primary
                    : (isDark ? Colors.white : AppColors.textMain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String id,
    required String title,
    required String desc,
    required IconData icon,
    required String bg,
    required bool isDark,
    bool recommended = false,
  }) {
    final selectedId = Provider.of<CreationProvider>(context).mode;
    final isSelected = selectedId == id;

    return GestureDetector(
      onTap: () =>
          Provider.of<CreationProvider>(context, listen: false).setMode(id),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            icon,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[500],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(bg),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (recommended)
            Positioned(
              top: -12,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Text(
                  'Recommended',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
