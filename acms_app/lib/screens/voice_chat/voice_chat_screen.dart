import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'dart:async';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = true;
  String _transcript = "";
  final String _fullText =
      "I can help you create a new blog post about 'The Future of AI in Design'. Would you like to start with an outline or generate a draft?";

  @override
  void initState() {
    super.initState();
    // Simulate live transcription after a delay
    Future.delayed(const Duration(seconds: 1), () {
      _startTyping();
    });
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Close Button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),

            Column(
              children: [
                const Spacer(flex: 2),

                // Neural Orb
                Center(child: _buildNeuralOrb()),

                const Spacer(flex: 1),

                // Live Transcript / Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  height: 120, // Fixed height to prevent jumps
                  alignment: Alignment.center,
                  child: _isListening
                      ? Text(
                          _transcript.isEmpty ? "Listening..." : _transcript,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        )
                      : Text(
                          "Tap to speak",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 18,
                          ),
                        ).animate().fadeIn(),
                ),

                const Spacer(flex: 2),

                // Controls
                _buildControls(),

                const SizedBox(height: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeuralOrb() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow (Purple)
          Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.3),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              )
              .fade(begin: 0.5, end: 0.8),

          // Middle Core (Primary Red)
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.primary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),

          // Inner Sparks (Blue/White)
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 300.ms, // jittery for active state
              )
              .blur(begin: const Offset(0, 0), end: const Offset(2, 2)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Keyboard Input (Secondary)
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.keyboard, color: Colors.white, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(width: 32),

        // Main Mic Toggle
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.white : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!_isListening)
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isListening ? Colors.black : Colors.white,
                      size: 36,
                    ),
                  )
                  .animate(target: _isListening ? 1 : 0)
                  .scale(end: const Offset(0.9, 0.9), duration: 100.ms),
        ),

        const SizedBox(width: 32),

        // Gallery/Input (Secondary)
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
