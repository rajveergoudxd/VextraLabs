import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/theme/theme_manager.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/providers/auth_provider.dart';

// Screens
import 'package:acms_app/screens/welcome_screen.dart';
import 'package:acms_app/screens/auth/create_account_screen.dart';
import 'package:acms_app/screens/auth/login_screen.dart';
import 'package:acms_app/screens/onboarding/gallery_permission_screen.dart';
import 'package:acms_app/screens/onboarding/mic_permission_screen.dart';
import 'package:acms_app/screens/onboarding/connect_social_screen.dart';
import 'package:acms_app/screens/onboarding/setup_complete_screen.dart';
import 'package:acms_app/screens/auth/forgot_password_screen.dart';
import 'package:acms_app/screens/auth/verify_otp_screen.dart';
import 'package:acms_app/screens/auth/set_new_password_screen.dart';
import 'package:acms_app/screens/onboarding/complete_profile_screen.dart';
import 'package:acms_app/screens/onboarding/onboarding_success_screen.dart';
import 'package:acms_app/screens/home/home_screen.dart';
import 'package:acms_app/screens/notifications/notifications_screen.dart';
import 'package:acms_app/screens/create/select_mode_screen.dart';

import 'package:acms_app/screens/create/select_media_screen.dart';
import 'package:acms_app/screens/create/edit_media_screen.dart';
import 'package:acms_app/screens/create/craft_post_screen.dart';
import 'package:acms_app/screens/create/ai_generation_screen.dart';
import 'package:acms_app/screens/create/review_publish_screen.dart';
import 'package:acms_app/screens/create/published_success_screen.dart';
import 'package:acms_app/screens/profile/profile_screen.dart';
import 'package:acms_app/screens/settings/settings_screen.dart';
import 'package:acms_app/screens/voice_chat/voice_chat_screen.dart';
import 'package:acms_app/screens/splash_screen.dart';

// Placeholder for tabs that don't exist yet
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text(title)),
  );
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => CreationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const AcmsApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AcmsApp extends StatelessWidget {
  const AcmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    final router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),

        // Shell Route for Bottom Navigation Tabs
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScaffold(navigationShell: navigationShell);
          },
          branches: [
            // Tab 0: Home
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeView(),
                ),
              ],
            ),

            // Tab 1: Calendar
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/calendar',
                  builder: (context, state) =>
                      const PlaceholderScreen('Calendar'),
                ),
              ],
            ),

            // Tab 2: AI Tools
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/tools',
                  builder: (context, state) =>
                      const PlaceholderScreen('AI Tools'),
                ),
              ],
            ),

            // Tab 3: Profile
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) =>
                      const ProfileScreen(isEmbedded: true),
                ),
              ],
            ),
          ],
        ),

        // ---- Auth / Onboarding ----
        GoRoute(
          path: '/create-account',
          builder: (context, state) => const CreateAccountScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/verify-otp',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            return VerifyOtpScreen(
              email: args['email'] as String,
              purpose: args['purpose'] as String,
            );
          },
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            return SetNewPasswordScreen(
              email: args['email'] as String,
              code: args['code'] as String,
            );
          },
        ),
        GoRoute(
          path: '/complete-profile',
          builder: (context, state) => const CompleteProfileScreen(),
        ),
        GoRoute(
          path: '/onboarding-success',
          builder: (context, state) => const OnboardingSuccessScreen(),
        ),
        GoRoute(
          path: '/onboarding/gallery',
          builder: (context, state) => const GalleryPermissionScreen(),
        ),
        GoRoute(
          path: '/onboarding/mic',
          builder: (context, state) => const MicPermissionScreen(),
        ),
        GoRoute(
          path: '/onboarding/social',
          builder: (context, state) => const ConnectSocialScreen(),
        ),
        GoRoute(
          path: '/onboarding/complete',
          builder: (context, state) => const SetupCompleteScreen(),
        ),

        // ---- Creation Flow (Full Screen, Hide Bottom Bar) ----
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/create/select-mode',
          builder: (context, state) => const SelectModeScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/create/select-media',
          builder: (context, state) => const SelectMediaScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/create/edit-media',
          builder: (context, state) => const EditMediaScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/create/craft-post',
          builder: (context, state) => const CraftPostScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/create/ai-generation',
          builder: (context, state) => const AiGenerationScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/create/review',
          builder: (context, state) => const ReviewPublishScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/create/success',
          builder: (context, state) => const PublishedSuccessScreen(),
        ),

        // ---- Settings (Full Screen) ----
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        // ---- Notifications (Full Screen) ----
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),

        // ---- Voice Chat (Full Screen) ----
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/voice-chat',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const VoiceChatScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Vextra',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeManager.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
