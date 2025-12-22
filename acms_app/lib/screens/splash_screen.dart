import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  late AnimationController _pulseController;

  // Main reveal animations
  late Animation<double> _strokeAnimation;
  late Animation<double> _fillAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateXAnimation;
  late Animation<double> _rotateYAnimation;
  late Animation<double> _opacityAnimation;

  // Glow/pulse animations
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller (2.5 seconds for full reveal)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Continuous glow effect
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Subtle pulse effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Stroke drawing animation (0-40% of timeline)
    _strokeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    // Fill animation (30-70% of timeline)
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    // 3D rotation X (subtle tilt forward then back)
    _rotateXAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: -0.1,
              end: 0.05,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.05,
              end: 0.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.0, 0.8),
          ),
        );

    // 3D rotation Y (subtle spin)
    _rotateYAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: -0.15,
              end: 0.08,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.08,
              end: 0.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.0, 0.9),
          ),
        );

    // Scale animation (zoom in from small)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.7,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_mainController);

    // Overall opacity
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Glow breathing effect
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Subtle pulse
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _mainController.forward();
    _glowController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);

    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for animation (2.5s) AND auth initialization
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2800)),
      _waitForAuth(authProvider),
    ]);

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/');
    }
  }

  Future<void> _waitForAuth(AuthProvider authProvider) async {
    while (!authProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Animated background particles
          _buildBackgroundParticles(isDark),

          // Main logo with animations
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _mainController,
                _glowController,
                _pulseController,
              ]),
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateX(_rotateXAnimation.value)
                      ..rotateY(_rotateYAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value * _pulseAnimation.value,
                      child: _buildAnimatedLogo(isDark),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect behind logo
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              width: 280,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.3 * _glowAnimation.value,
                    ),
                    blurRadius: 60 * _glowAnimation.value,
                    spreadRadius: 10 * _glowAnimation.value,
                  ),
                  BoxShadow(
                    color: const Color(
                      0xFFEC4899,
                    ).withValues(alpha: 0.2 * _glowAnimation.value),
                    blurRadius: 40 * _glowAnimation.value,
                    spreadRadius: 5 * _glowAnimation.value,
                  ),
                ],
              ),
            );
          },
        ),

        // Logo with stroke drawing and fill effect
        AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                // Animated gradient fill that sweeps across
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    isDark ? Colors.white : AppColors.textMain,
                    isDark ? Colors.white : AppColors.textMain,
                    Colors.transparent,
                  ],
                  stops: [
                    0.0,
                    _fillAnimation.value,
                    _fillAnimation.value + 0.01,
                  ],
                ).createShader(bounds);
              },
              child: Image.asset(
                isDark
                    ? 'assets/images/vextra_logo_dark.png'
                    : 'assets/images/vextra_logo_light.png',
                width: 250,
              ),
            );
          },
        ),

        // Red accent line animation (simulating the V accent being drawn)
        AnimatedBuilder(
          animation: _strokeAnimation,
          builder: (context, child) {
            return Positioned(
              left: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(250, 80),
                painter: _AccentLinePainter(
                  progress: _strokeAnimation.value,
                  color: AppColors.primary,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackgroundParticles(bool isDark) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlesPainter(
            progress: _mainController.value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

/// Custom painter for the accent line drawing animation
class _AccentLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _AccentLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: progress)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw a subtle accent line that builds up
    // This simulates the signature red element in the Vextra logo
    final path = Path();

    // Start from bottom-left, sweep up and to the right
    final startX = size.width * 0.35;
    final startY = size.height * 0.7;
    final endX = size.width * 0.65;
    final endY = size.height * 0.3;

    path.moveTo(startX, startY);

    // Animate how much of the line is drawn
    final currentX = startX + (endX - startX) * progress;
    final currentY = startY + (endY - startY) * progress;

    path.lineTo(currentX, currentY);

    canvas.drawPath(path, paint);

    // Add glowing dot at the end of the line
    if (progress > 0.1) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(currentX, currentY), 4 * progress, dotPaint);

      // Glow around the dot
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3 * progress)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(currentX, currentY), 10 * progress, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_AccentLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Custom painter for floating particles in background
class _ParticlesPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _ParticlesPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.2) return; // Start particles after logo begins appearing

    final adjustedProgress = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
    final random = math.Random(42); // Fixed seed for consistent particles

    for (int i = 0; i < 20; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final particleProgress = ((adjustedProgress - i * 0.03)).clamp(0.0, 1.0);

      if (particleProgress <= 0) continue;

      final opacity = (particleProgress * (1 - particleProgress) * 4).clamp(
        0.0,
        1.0,
      );
      final particleSize = 2 + random.nextDouble() * 4;

      // Particles float upward
      final yOffset = -50 * particleProgress;

      final paint = Paint()
        ..color = (i % 2 == 0 ? AppColors.primary : const Color(0xFFEC4899))
            .withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(startX, startY + yOffset),
        particleSize * opacity,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
