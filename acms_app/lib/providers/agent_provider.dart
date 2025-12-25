import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:acms_app/services/agent_service.dart';

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
  /// In Guide Mode, we do not execute actions, but we keep this method
  /// to handle any potential future navigation links if needed.
  Future<void> executeAction(BuildContext context, AgentAction action) async {
    // Guide Mode: No actions are executed automatically.
    // The agent will explain what to do instead.
    debugPrint('Action received in Guide Mode (ignored): ${action.name}');
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
