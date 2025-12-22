import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'dart:async';
import 'dart:math' as math;

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  bool _isListening = true;
  String _transcript = "";
  final String _fullText =
      "I can help you create a new blog post about 'The Future of AI in Design'. Would you like to start with an outline or generate a draft?";

  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Simulate live transcription after a delay
    Future.delayed(const Duration(seconds: 1), () {
      _startTyping();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _startTyping() {
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index < _fullText.length) {
        setState(() {
          _transcript += _fullText[index];
          index++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isListening = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textMain;
    final subtextColor = isDark ? Colors.grey[400] : AppColors.textSub;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 1.2,
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                      backgroundColor,
                    ],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[200]!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: textColor,
                            size: 18,
                          ),
                        ),
                      ),
                      // Title
                      Column(
                        children: [
                          Text(
                            'Voice Assistant',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _isListening
                                      ? AppColors.success
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isListening ? 'Listening' : 'Ready',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Settings placeholder
                      IconButton(
                        onPressed: () {},
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[200]!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: textColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Voice Orb
                Center(child: _buildVoiceOrb(isDark)),

                const Spacer(flex: 1),

                // Live Transcript Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(minHeight: 120),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isListening && _transcript.isNotEmpty
                      ? Text(
                          _transcript,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        )
                      : _isListening
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildListeningWave(isDark),
                            const SizedBox(height: 12),
                            Text(
                              "Listening...",
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              color: subtextColor,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap the mic to speak",
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 300.ms),
                ),

                const Spacer(flex: 2),

                // Controls - seamless edge-to-edge
                _buildControls(isDark, surfaceColor, textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningWave(bool isDark) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final offset = index * 0.15;
            final value = math.sin(
              (_waveController.value + offset) * math.pi * 2,
            );
            final height = 8 + (value * 12).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.6 + value * 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildVoiceOrb(bool isDark) {
    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = _pulseController.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring pulse (only when listening)
              if (_isListening)
                Container(
                  width: 200 + (pulseValue * 20),
                  height: 200 + (pulseValue * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: 0.2 * (1 - pulseValue),
                      ),
                      width: 2,
                    ),
                  ),
                ),

              // Second ring
              if (_isListening)
                Container(
                  width: 170 + (pulseValue * 15),
                  height: 170 + (pulseValue * 15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: 0.3 * (1 - pulseValue * 0.5),
                      ),
                      width: 1.5,
                    ),
                  ),
                ),

              // Outer glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: _isListening ? 0.25 + (pulseValue * 0.15) : 0.15,
                      ),
                      blurRadius: _isListening ? 40 + (pulseValue * 20) : 30,
                      spreadRadius: _isListening ? 10 + (pulseValue * 10) : 5,
                    ),
                  ],
                ),
              ),

              // Main orb
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    colors: [
                      AppColors.primary.withValues(alpha: 0.9),
                      AppColors.primaryDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),

              // Inner highlight
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    radius: 0.8,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Center icon
              Icon(
                _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 40,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls(bool isDark, Color surfaceColor, Color textColor) {
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gradient fade from transparent to background
        Container(
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundColor.withValues(alpha: 0), backgroundColor],
            ),
          ),
        ),
        // Main controls area - flush with edges
        Container(
          width: double.infinity,
          color: backgroundColor,
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Keyboard Input
              _buildControlButton(
                icon: Icons.keyboard_rounded,
                label: 'Type',
                onTap: () {},
                isDark: isDark,
              ),

              // Main Mic Toggle - Centered and elevated
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isListening = !_isListening;
                        if (_isListening) {
                          _transcript = "";
                          _startTyping();
                        }
                      });
                    },
                    child:
                        Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.surfaceDark
                                          : Colors.white),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _isListening
                                        ? AppColors.primary.withValues(
                                            alpha: 0.4,
                                          )
                                        : Colors.black.withValues(alpha: 0.1),
                                    blurRadius: _isListening ? 24 : 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: _isListening ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: _isListening
                                    ? Colors.white
                                    : AppColors.primary,
                                size: 32,
                              ),
                            )
                            .animate(target: _isListening ? 1 : 0)
                            .scale(
                              end: const Offset(0.95, 0.95),
                              duration: 100.ms,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isListening ? 'Tap to stop' : 'Tap to speak',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Gallery/Media
              _buildControlButton(
                icon: Icons.image_rounded,
                label: 'Media',
                onTap: () {},
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
