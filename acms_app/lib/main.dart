import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/theme/theme_manager.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/providers/auth_provider.dart';
import 'package:acms_app/providers/settings_provider.dart';
import 'package:acms_app/providers/social_connections_provider.dart';
import 'package:acms_app/providers/social_provider.dart';
import 'package:acms_app/providers/chat_provider.dart';

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
import 'package:acms_app/screens/create/upload_media_screen.dart';
import 'package:acms_app/screens/create/write_text_screen.dart';
import 'package:acms_app/screens/profile/profile_screen.dart';
import 'package:acms_app/screens/profile/edit_profile_screen.dart';
import 'package:acms_app/screens/profile/user_profile_screen.dart';
import 'package:acms_app/screens/settings/settings_screen.dart';
import 'package:acms_app/screens/settings/change_password_screen.dart';
import 'package:acms_app/screens/settings/privacy_data_screen.dart';
import 'package:acms_app/screens/voice_chat/voice_chat_screen.dart';
import 'package:acms_app/screens/splash_screen.dart';
import 'package:acms_app/screens/inspire/inspire_screen.dart';
import 'package:acms_app/screens/inspire/user_search_screen.dart';
import 'package:acms_app/screens/chats/chats_screen.dart';
import 'package:acms_app/screens/chats/chat_detail_screen.dart';

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
        // Use the global themeManager singleton instead of creating a new instance
        ChangeNotifierProvider<ThemeManager>.value(value: themeManager),
        ChangeNotifierProvider(create: (_) => CreationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SocialConnectionsProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const AcmsApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AcmsApp extends StatelessWidget {
  const AcmsApp({super.key});

  // Create router once, not on every rebuild
  static final GoRouter _router = GoRouter(
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

          // Tab 1: Inspire
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inspire',
                builder: (context, state) => const InspireScreen(),
              ),
            ],
          ),

          // Tab 2: Chats (replaced AI Tools)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatsScreen(),
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/create/upload-media',
        builder: (context, state) => const UploadMediaScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/create/write-text',
        builder: (context, state) => const WriteTextScreen(),
      ),

      // ---- Settings (Full Screen) ----
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/privacy',
        builder: (context, state) => const PrivacyDataScreen(),
      ),

      // ---- Edit Profile (Full Screen) ----
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
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
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // ---- Chat Routes (Full Screen) ----
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/chats/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ChatDetailScreen(conversationId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/chats/new',
        builder: (context, state) => const UserSearchScreen(),
      ),

      // ---- Social Routes (Full Screen) ----
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/search',
        builder: (context, state) => const UserSearchScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/user/:username',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return UserProfileScreen(username: username);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp.router(
      title: 'Vextra',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeManager.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
