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
      duration: const Duration(seconds: 2),
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

    // Check auth state when initialized
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    void checkAuth() {
      if (authProvider.isInitialized) {
        if (authProvider.isAuthenticated) {
          context.go('/home');
        } else {
          context.go('/');
        }
      }
    }

    if (authProvider.isInitialized) {
      // Small delay for animation smoothnes
      Future.delayed(const Duration(seconds: 2), checkAuth);
    } else {
      // Wait for initialization
      authProvider.addListener(() {
        if (authProvider.isInitialized && mounted) {
          Future.delayed(const Duration(seconds: 2), checkAuth);
        }
      });
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
