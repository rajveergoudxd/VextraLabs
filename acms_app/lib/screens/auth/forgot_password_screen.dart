import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/auth_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') setState(() => _isListening = false);
        },
        onError: (errorNotification) {
          setState(() => _isListening = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${errorNotification.errorMsg}')),
            );
          }
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _emailController.text = result.recognizedWords;
              // If final, maybe stop?
            });
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _handleSendResetLink() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final router = GoRouter.of(context);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    final success = await authProvider.forgotPassword(email);

    if (!mounted) return;

    if (success) {
      // Navigate to OTP screen with arguments
      router.push(
        '/verify-otp',
        extra: {'email': email, 'purpose': 'reset_password'},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Failed to send OTP')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new),
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Forgot Password?',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Don't worry! It happens. Please enter the email associated with your account.",
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : AppColors.textSub,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email Input
                    _buildInputField(
                      context,
                      'Email Address',
                      'you@example.com',
                      controller: _emailController,
                      icon: Icons.mail,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      suffixIcon: _isListening ? Icons.mic_off : Icons.mic,
                      onSuffixPressed: _listen,
                    ),

                    const SizedBox(height: 32),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : _handleSendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remember password? ',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : AppColors.textSub,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/'), // Go back to login
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 18,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Need help? Contact Support',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method copied from LoginScreen for consistency
  Widget _buildInputField(
    BuildContext context,
    String label,
    String placeholder, {
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixPressed,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.grey[200] : AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                contentPadding: const EdgeInsets.fromLTRB(
                  48,
                  16,
                  48, // Padding for suffix icon
                  16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                suffixIcon: suffixIcon != null
                    ? IconButton(
                        icon: Icon(
                          suffixIcon,
                          color: isDark ? Colors.grey[500] : AppColors.textSub,
                        ),
                        onPressed: onSuffixPressed,
                      )
                    : null,
              ),
            ),
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Icon(
                icon,
                color: isDark ? Colors.grey[500] : AppColors.textSub,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
