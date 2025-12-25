import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:acms_app/services/agent_service.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/providers/social_provider.dart';
import 'package:acms_app/providers/inspire_provider.dart';
import 'package:acms_app/providers/settings_provider.dart';
import 'package:acms_app/providers/notification_provider.dart';
import 'package:acms_app/providers/auth_provider.dart';
import 'package:acms_app/theme/theme_manager.dart';
import 'package:provider/provider.dart';

/// States for the voice agent
enum AgentState {
  idle, // Ready to start
  listening, // STT is active
  processing, // Sending to backend
  speaking, // TTS is playing
  error, // An error occurred
}

/// Provider for the AI voice agent
class AgentProvider extends ChangeNotifier {
  final AgentService _agentService = AgentService();
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  // State
  AgentState _state = AgentState.idle;
  String _transcript = '';
  String _lastResponse = '';
  String? _error;
  bool _sttInitialized = false;
  bool _ttsInitialized = false;

  // Conversation history for context
  final List<AgentMessage> _history = [];

  // Getters
  AgentState get state => _state;
  String get transcript => _transcript;
  String get lastResponse => _lastResponse;
  String? get error => _error;
  bool get isListening => _state == AgentState.listening;
  bool get isProcessing => _state == AgentState.processing;
  bool get isSpeaking => _state == AgentState.speaking;
  bool get isIdle => _state == AgentState.idle;
  List<AgentMessage> get history => List.unmodifiable(_history);

  /// Initialize the agent (call once on screen mount)
  Future<void> initialize() async {
    // Initialize Speech-to-Text
    try {
      _sttInitialized = await _stt.initialize(
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg}');
          _setError('Speech recognition error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'done' && _state == AgentState.listening) {
            // STT finished, process the transcript
            _processTranscript();
          }
        },
      );
    } catch (e) {
      debugPrint('STT init error: $e');
      _sttInitialized = false;
    }

    // Initialize Text-to-Speech
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // Slightly slower for clarity
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        if (_state == AgentState.speaking) {
          _setState(AgentState.idle);
        }
      });

      _ttsInitialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
      _ttsInitialized = false;
    }

    notifyListeners();
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (!_sttInitialized) {
      _setError('Speech recognition not available');
      return;
    }

    if (_state == AgentState.speaking) {
      await _tts.stop();
    }

    _transcript = '';
    _error = null;
    _setState(AgentState.listening);

    await _stt.listen(
      onResult: (result) {
        _transcript = result.recognizedWords;
        notifyListeners();

        // If final result, process it
        if (result.finalResult) {
          _processTranscript();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      listenMode: ListenMode.dictation,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_state == AgentState.listening) {
      await _stt.stop();
      if (_transcript.isNotEmpty) {
        _processTranscript();
      } else {
        _setState(AgentState.idle);
      }
    }
  }

  /// Cancel listening without processing
  Future<void> cancelListening() async {
    await _stt.stop();
    _transcript = '';
    _setState(AgentState.idle);
  }

  /// Process text input (for keyboard fallback)
  Future<void> processTextInput(String text) async {
    if (text.trim().isEmpty) return;
    _transcript = text;
    await _processTranscript();
  }

  /// Process the transcript through the agent
  Future<void> _processTranscript() async {
    if (_transcript.isEmpty) {
      _setState(AgentState.idle);
      return;
    }

    _setState(AgentState.processing);

    try {
      // Add user message to history
      _history.add(AgentMessage(role: 'user', content: _transcript));

      // Send to agent
      final response = await _agentService.chat(
        _transcript,
        history: _history.length > 10
            ? _history.sublist(_history.length - 10) // Keep last 10 messages
            : _history,
      );

      _lastResponse = response.message;

      // Add assistant response to history
      _history.add(AgentMessage(role: 'assistant', content: response.message));

      // Speak the response
      if (_ttsInitialized && response.message.isNotEmpty) {
        _setState(AgentState.speaking);
        await _tts.speak(response.message);
      } else {
        _setState(AgentState.idle);
      }

      // Return actions for the UI to execute
      notifyListeners();

      // Note: Actions should be executed by the calling code
      // This allows the UI to handle navigation context properly
    } catch (e) {
      _setError('Failed to process: $e');
    }
  }

  /// Execute an action returned by the agent
  /// Call this from the UI with proper context
  Future<void> executeAction(BuildContext context, AgentAction action) async {
    final router = GoRouter.of(context);

    switch (action.name) {
      // ===== NAVIGATION =====
      case 'navigate_to':
        final screen = action.parameters['screen'] as String?;
        if (screen != null) {
          _navigateTo(router, screen);
        }
        break;

      // ===== POST CREATION =====
      case 'create_post':
        final content = action.parameters['content'] as String?;
        final platforms = action.parameters['platforms'] as List<dynamic>?;
        if (content != null) {
          final creation = context.read<CreationProvider>();
          creation.setCaption('inspire', content);
          if (platforms != null) {
            for (final p in platforms) {
              creation.togglePlatform(p.toString());
            }
          }
          router.go('/create/review');
        }
        break;

      case 'save_draft':
        final content = action.parameters['content'] as String?;
        final title = action.parameters['title'] as String?;
        if (content != null) {
          final creation = context.read<CreationProvider>();
          creation.setCaption('inspire', content);
          await creation.saveDraft(title: title);
        }
        break;

      case 'get_drafts':
        router.go(
          '/home',
        ); // Navigate to home where recent activity shows drafts
        break;

      case 'publish_draft':
        final draftId = action.parameters['draft_id'] as int?;
        if (draftId != null) {
          final creation = context.read<CreationProvider>();
          await creation.publishDraft(draftId);
        }
        break;

      case 'delete_draft':
        final draftId = action.parameters['draft_id'] as int?;
        if (draftId != null) {
          final creation = context.read<CreationProvider>();
          await creation.deleteDraft(draftId);
        }
        break;

      // ===== POST INTERACTIONS =====
      case 'like_post':
        final postId = action.parameters['post_id'] as int?;
        if (postId != null) {
          final inspire = context.read<InspireProvider>();
          await inspire.likePost(postId);
        }
        break;

      case 'save_post':
        final postId = action.parameters['post_id'] as int?;
        if (postId != null) {
          final inspire = context.read<InspireProvider>();
          await inspire.savePost(postId);
        }
        break;

      case 'unsave_post':
        final postId = action.parameters['post_id'] as int?;
        if (postId != null) {
          final inspire = context.read<InspireProvider>();
          await inspire.unsavePost(postId);
        }
        break;

      case 'delete_post':
        final postId = action.parameters['post_id'] as int?;
        if (postId != null) {
          final inspire = context.read<InspireProvider>();
          await inspire.deletePost(postId);
        }
        break;

      case 'add_comment':
        // Navigate to post detail - actual comment would be added there
        final postId = action.parameters['post_id'] as int?;
        if (postId != null) {
          // Would need to fetch post first or pass minimal info
          debugPrint('Add comment to post $postId');
        }
        break;

      case 'share_post':
        final postId = action.parameters['post_id'] as int?;
        if (postId != null) {
          router.push('/chats/share', extra: {'postId': postId});
        }
        break;

      // ===== SOCIAL =====
      case 'search_users':
        // Navigate to search screen
        router.push('/search');
        break;

      case 'view_profile':
        final username = action.parameters['username'] as String?;
        if (username != null) {
          router.push('/user/$username');
        }
        break;

      case 'follow_user':
        final userId = action.parameters['user_id'] as int?;
        if (userId != null) {
          final social = context.read<SocialProvider>();
          await social.followUser(userId);
        }
        break;

      case 'unfollow_user':
        final userId = action.parameters['user_id'] as int?;
        if (userId != null) {
          final social = context.read<SocialProvider>();
          await social.unfollowUser(userId);
        }
        break;

      // ===== FEED =====
      case 'refresh_feed':
        final inspire = context.read<InspireProvider>();
        await inspire.loadFeed(refresh: true);
        router.go('/inspire');
        break;

      case 'get_my_posts':
        router.go('/profile');
        break;

      case 'get_saved_posts':
        router.push('/saved-posts');
        break;

      // ===== SETTINGS =====
      case 'change_theme':
        final mode = action.parameters['mode'] as String?;
        if (mode != null) {
          final theme = themeManager;
          switch (mode) {
            case 'light':
              theme.setThemeMode(ThemeMode.light);
              break;
            case 'dark':
              theme.setThemeMode(ThemeMode.dark);
              break;
            case 'system':
              theme.setThemeMode(ThemeMode.system);
              break;
          }
        }
        break;

      case 'toggle_notifications':
        final enabled = action.parameters['enabled'] as bool?;
        if (enabled != null) {
          final settings = context.read<SettingsProvider>();
          await settings.updatePushNotifications(enabled);
        }
        break;

      case 'update_profile':
        router.push('/edit-profile');
        break;

      case 'logout':
        final auth = context.read<AuthProvider>();
        await auth.logout();
        router.go('/');
        break;

      // ===== NOTIFICATIONS =====
      case 'get_notifications':
        router.push('/notifications');
        break;

      case 'mark_notifications_read':
        final notifications = context.read<NotificationProvider>();
        await notifications.markAllAsRead();
        break;

      // ===== CONTENT GENERATION =====
      case 'generate_caption':
        // Navigate to create flow - AI will assist there
        router.go('/create/write-text');
        break;

      case 'suggest_hashtags':
        // This would be handled inline in the create flow
        break;

      default:
        debugPrint('Unknown action: ${action.name}');
    }
  }

  void _navigateTo(GoRouter router, String screen) {
    switch (screen) {
      case 'home':
        router.go('/home');
        break;
      case 'profile':
        router.go('/profile');
        break;
      case 'settings':
        router.push('/settings');
        break;
      case 'inspire':
        router.go('/inspire');
        break;
      case 'create':
        router.push('/create/select-mode');
        break;
      case 'notifications':
        router.push('/notifications');
        break;
      case 'saved_posts':
        router.push('/saved-posts');
        break;
      case 'drafts':
        router.go('/home'); // Drafts shown in recent activity
        break;
      case 'chat':
      case 'chats':
        router.go('/chats');
        break;
      case 'followers':
      case 'following':
        // Would need user ID - navigate to profile first
        router.go('/profile');
        break;
      case 'search':
        router.push('/search');
        break;
      default:
        debugPrint('Unknown screen: $screen');
    }
  }

  void _setState(AgentState state) {
    _state = state;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _state = AgentState.error;
    notifyListeners();

    // Auto-recover after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (_state == AgentState.error) {
        _error = null;
        _state = AgentState.idle;
        notifyListeners();
      }
    });
  }

  /// Clear conversation history
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// Stop TTS if speaking
  Future<void> stopSpeaking() async {
    if (_state == AgentState.speaking) {
      await _tts.stop();
      _setState(AgentState.idle);
    }
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}
