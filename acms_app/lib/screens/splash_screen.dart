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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for minimum 1 second animation AND auth initialization
    await Future.wait([
      Future.delayed(const Duration(seconds: 1)),
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
    if (authProvider.isInitialized) return;

    // We can rely on the fact that AuthProvider notifies listeners when initialized
    // But since we are in a async method, we can poll or use a completer mechanism attached to listener.
    // Simplifying: Just poll until initialized since it should be very fast usually.
    // Or better: Use a stream or just check periodically.

    while (!authProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              isDark
                  ? 'assets/images/vextra_logo_dark.png'
                  : 'assets/images/vextra_logo_light.png',
              width: 250, // Adjust size as needed
            ),
          ),
        ),
      ),
    );
  }
}
