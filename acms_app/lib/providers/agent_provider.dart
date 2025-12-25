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
          // Auto-listen after agent finishes speaking to create conversational flow
          startListening();
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
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
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

        final creation = context.read<CreationProvider>();

        if (content != null && content.isNotEmpty) {
          // We have specific content, set it and go to review
          creation.setCaption('inspire', content);
          if (platforms != null) {
            for (final p in platforms) {
              creation.togglePlatform(p.toString());
            }
          }
          router.go('/create/review');
        } else {
          // No content specified, just open the creation flow
          router.go('/create/write-text');
        }
        break;

      case 'manage_draft':
        final actionType = action.parameters['action'] as String?;
        final content = action.parameters['content'] as String?;
        final title = action.parameters['title'] as String?;
        final draftId = action.parameters['draft_id'] as int?;

        final creation = context.read<CreationProvider>();

        if (actionType == 'save' && content != null) {
          creation.setCaption('inspire', content);
          await creation.saveDraft(title: title);
        } else if (actionType == 'publish' && draftId != null) {
          await creation.publishDraft(draftId);
        } else if (actionType == 'delete' && draftId != null) {
          await creation.deleteDraft(draftId);
        }
        break;

      // ===== INTERACTIONS =====
      case 'interact_with_post':
        final actionType = action.parameters['action'] as String?;
        final postId = action.parameters['post_id'] as int?;
        final content = action.parameters['content'] as String?;

        if (postId == null) break;

        final inspire = context.read<InspireProvider>();

        if (actionType == 'like') {
          await inspire.likePost(postId);
        } else if (actionType == 'save') {
          await inspire.savePost(postId);
        } else if (actionType == 'unsave') {
          await inspire.unsavePost(postId);
        } else if (actionType == 'delete') {
          await inspire.deletePost(postId);
        } else if (actionType == 'share') {
          router.push('/chats/share', extra: {'postId': postId});
        } else if (actionType == 'comment') {
          // Navigate to post detail for commenting
          // In a real implementation we might auto-fill the comment box
          debugPrint('Add comment to post $postId: $content');
        }
        break;

      // ===== SOCIAL =====
      case 'manage_relationship':
        final actionType = action.parameters['action'] as String?;
        final userId = action.parameters['user_id'] as int?;

        if (userId != null) {
          final social = context.read<SocialProvider>();
          if (actionType == 'follow') {
            await social.followUser(userId);
          } else if (actionType == 'unfollow') {
            await social.unfollowUser(userId);
          }
        }
        break;

      case 'search_users':
        router.push('/search');
        break;

      case 'view_profile':
        final username = action.parameters['username'] as String?;
        if (username != null) {
          router.push('/user/$username');
        }
        break;

      // ===== SETTINGS & EXTRAS =====
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

      case 'mark_notifications_read':
        final notifications = context.read<NotificationProvider>();
        await notifications.markAllAsRead();
        break;

      case 'generate_caption':
        router.go('/create/write-text');
        break;

      case 'suggest_hashtags':
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
      // Set to idle FIRST to prevent completion handler from restarting listening
      _state = AgentState.idle;
      notifyListeners();
      await _tts.stop();
    }
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}
