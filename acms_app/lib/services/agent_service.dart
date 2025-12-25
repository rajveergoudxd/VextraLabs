import 'package:dio/dio.dart';
import 'package:acms_app/services/api_client.dart';

/// Model for an action returned by the agent
class AgentAction {
  final String name;
  final Map<String, dynamic> parameters;

  AgentAction({required this.name, required this.parameters});

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    return AgentAction(
      name: json['name'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }
}

/// Model for a message in the conversation history
class AgentMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  AgentMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Response from the agent chat endpoint
class AgentChatResponse {
  final String message;
  final List<AgentAction> actions;
  final bool success;
  final String? error;

  AgentChatResponse({
    required this.message,
    required this.actions,
    required this.success,
    this.error,
  });

  factory AgentChatResponse.fromJson(Map<String, dynamic> json) {
    return AgentChatResponse(
      message: json['message'] as String,
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((a) => AgentAction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      success: json['success'] as bool? ?? true,
      error: json['error'] as String?,
    );
  }
}

/// Service for communicating with the AI agent backend
class AgentService {
  final ApiClient _apiClient = ApiClient();

  /// Send a message to the AI agent and get a response with actions
  Future<AgentChatResponse> chat(
    String message, {
    List<AgentMessage>? history,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/agent/chat',
        data: {
          'message': message,
          if (history != null)
            'history': history.map((m) => m.toJson()).toList(),
        },
      );

      return AgentChatResponse.fromJson(response.data);
    } on DioException catch (e) {
      // Handle specific error cases
      if (e.response?.statusCode == 503) {
        return AgentChatResponse(
          message:
              'AI service is temporarily unavailable. Please try again later.',
          actions: [],
          success: false,
          error: 'Service unavailable',
        );
      }
      return AgentChatResponse(
        message:
            'Failed to connect to the assistant. Please check your connection.',
        actions: [],
        success: false,
        error: e.message,
      );
    } catch (e) {
      return AgentChatResponse(
        message: 'Something went wrong. Please try again.',
        actions: [],
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check if the agent service is available
  Future<bool> isAvailable() async {
    try {
      final response = await _apiClient.dio.get('/agent/health');
      return response.data['available'] == true;
    } catch (e) {
      return false;
    }
  }
}
