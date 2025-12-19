import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';

class AiGenerationScreen extends StatefulWidget {
  const AiGenerationScreen({super.key});

  @override
  State<AiGenerationScreen> createState() => _AiGenerationScreenState();
}

class _AiGenerationScreenState extends State<AiGenerationScreen> {
  double _progress = 0.0;
  int _currentStep = 0;
  Timer? _timer;

  final List<String> _steps = [
    'Analyzing media for key moments',
    'Generating platform captions',
    'Integrating trending audio',
    'Optimizing hashtags',
  ];

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  void _startGeneration() {
    // Simulate progress
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.005;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          // Navigate to success/review after a brief pause
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              final creationProvider = Provider.of<CreationProvider>(
                context,
                listen: false,
              );
              if (creationProvider.mode == 'auto') {
                context.pushReplacement('/create/success');
              } else {
                context.pushReplacement('/create/review');
              }
            }
          });
        }

        // Update steps based on progress
        if (_progress > 0.75) {
          _currentStep = 3;
        } else if (_progress > 0.5) {
          _currentStep = 2;
        } else if (_progress > 0.25) {
          _currentStep = 1;
        } else {
          _currentStep = 0;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                  const Text(
                    'AI Magic in Progress',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Central AI Orb Visualization
                    SizedBox(
                      height: 260, // Reduced height to prevent overflow
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Ring
                          Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    width: 1,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                duration: 2.seconds,
                              ),

                          // Pulsing Glow
                          Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.05,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1.1, 1.1),
                                duration: 1500.ms,
                              ),

                          // Inner Dashed Ring simulation
                          Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    style: BorderStyle
                                        .solid, // Flutter doesn't support easy dashed circle borders natively without custom painter, using solid for now or thin
                                    width: 1,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .rotate(duration: 10.seconds),

                          // Core Orb
                          Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      Color(0xFFff4d4d),
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                duration: 1.seconds,
                              ),

                          // Floating Icons
                          Positioned(
                                top: 40,
                                right: 40,
                                child: _buildFloatingIcon(Icons.mic, isDark),
                              )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .moveY(begin: 10, end: 0),

                          Positioned(
                                bottom: 60,
                                left: 30,
                                child: _buildFloatingIcon(
                                  Icons.perm_media,
                                  isDark,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .moveY(begin: 10, end: 0),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Progress Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Crafting engaging collages and reels...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: isDark ? Colors.white : AppColors.textMain,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Estimated time remaining: 12s',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Progress Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL PROGRESS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                '${(_progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                              minHeight: 10,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Steps
                          ...List.generate(_steps.length, (index) {
                            return _buildStepItem(
                              context,
                              _steps[index],
                              index,
                              isDark,
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), // Extra padding for scroll
                  ],
                ),
              ),
            ),

            // Cancel Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('CANCEL GENERATION'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF331a1a) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Icon(icon, color: AppColors.primary, size: 16),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    String text,
    int index,
    bool isDark,
  ) {
    bool isCompleted = index < _currentStep;
    bool isActive = index == _currentStep;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          else if (isActive)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            )
          else
            Icon(
              Icons.radio_button_unchecked,
              color: Colors.grey[600],
              size: 20,
            ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCompleted || isActive
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isActive
                        ? (isDark ? Colors.white : AppColors.textMain)
                        : (isCompleted ? Colors.grey[500] : Colors.grey[600]),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Processing...',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
