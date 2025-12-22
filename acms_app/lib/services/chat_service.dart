import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:acms_app/services/api_client.dart';

/// Service for chat features: conversations and messages
class ChatService {
  final ApiClient _apiClient = ApiClient();

  // ============== Conversations ==============

  /// Create or get existing conversation with a user
  Future<Map<String, dynamic>> getOrCreateConversation(
    int participantId,
  ) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations',
      data: {'participant_id': participantId},
    );
    return response.data;
  }

  /// Get list of all conversations for current user
  Future<Map<String, dynamic>> getConversations({
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await _apiClient.dio.get(
      '/chat/conversations',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return response.data;
  }

  /// Get single conversation with messages
  Future<Map<String, dynamic>> getConversationDetail(int conversationId) async {
    final response = await _apiClient.dio.get(
      '/chat/conversations/$conversationId',
    );
    return response.data;
  }

  // ============== Messages ==============

  /// Send a text message
  Future<Map<String, dynamic>> sendTextMessage(
    int conversationId,
    String content,
  ) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations/$conversationId/messages',
      data: {'content': content, 'message_type': 'text'},
    );
    return response.data;
  }

  /// Send a message with media
  Future<Map<String, dynamic>> sendMediaMessage(
    int conversationId,
    String mediaUrl,
    String messageType, { // 'image' or 'video'
    String? caption,
  }) async {
    final response = await _apiClient.dio.post(
      '/chat/conversations/$conversationId/messages',
      data: {
        'content': caption,
        'message_type': messageType,
        'media_url': mediaUrl,
      },
    );
    return response.data;
  }

  /// Get messages for a conversation with pagination
  Future<List<dynamic>> getMessages(
    int conversationId, {
    int skip = 0,
    int limit = 50,
    int? beforeId,
  }) async {
    final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};
    if (beforeId != null) {
      queryParams['before_id'] = beforeId;
    }

    final response = await _apiClient.dio.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Mark conversation as read
  Future<Map<String, dynamic>> markConversationRead(int conversationId) async {
    final response = await _apiClient.dio.put(
      '/chat/conversations/$conversationId/read',
    );
    return response.data;
  }

  /// Upload media file and get URL
  Future<String?> uploadMedia(File file) async {
    final fileName = file.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();

    MediaType mediaType;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      mediaType = MediaType('image', extension == 'jpg' ? 'jpeg' : extension);
    } else if (['mp4', 'mov', 'avi', 'webm'].contains(extension)) {
      mediaType = MediaType('video', extension);
    } else {
      mediaType = MediaType('application', 'octet-stream');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: mediaType,
      ),
    });

    final response = await _apiClient.dio.post('/upload/file', data: formData);

    return response.data['url'];
  }
}
