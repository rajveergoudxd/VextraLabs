import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for OAuth social platform authentication
class OAuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Replace with your actual backend URL
  static const String _baseUrl =
      'https://vextra-backend-842753730816.us-central1.run.app/api/v1';

  OAuthService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  /// Get authorization headers with stored token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Get list of connected social platforms
  Future<List<SocialConnection>> getConnections() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '/oauth/connections',
        options: Options(headers: headers),
      );

      final data = response.data['connections'] as List;
      return data.map((conn) => SocialConnection.fromJson(conn)).toList();
    } catch (e) {
      throw Exception('Failed to get connections: $e');
    }
  }

  /// Get OAuth authorization URL for a platform
  Future<OAuthAuthorizeResponse> getAuthorizationUrl(String platform) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '/oauth/$platform/authorize',
        options: Options(headers: headers),
      );

      return OAuthAuthorizeResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get authorization URL: $e');
    }
  }

  /// Send OAuth callback code to backend
  Future<bool> handleCallback(
    String platform,
    String code,
    String state,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '/oauth/$platform/callback',
        options: Options(headers: headers),
        data: {'code': code, 'state': state},
      );

      return response.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to connect platform: $e');
    }
  }

  /// Disconnect a platform
  Future<bool> disconnect(String platform) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.delete(
        '/oauth/$platform/disconnect',
        options: Options(headers: headers),
      );

      return response.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to disconnect: $e');
    }
  }

  /// Publish content to platforms
  Future<PublishResult> publish({
    required List<String> platforms,
    required String content,
    List<String>? mediaUrls,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '/publish/',
        options: Options(headers: headers),
        data: {
          'platforms': platforms,
          'content': content,
          if (mediaUrls != null) 'media_urls': mediaUrls,
        },
      );

      return PublishResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to publish: $e');
    }
  }
}

/// Social connection model
class SocialConnection {
  final int id;
  final String platform;
  final String platformUserId;
  final String? platformUsername;
  final String? platformDisplayName;
  final String? platformProfilePicture;
  final bool isTokenValid;
  final DateTime? tokenExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SocialConnection({
    required this.id,
    required this.platform,
    required this.platformUserId,
    this.platformUsername,
    this.platformDisplayName,
    this.platformProfilePicture,
    required this.isTokenValid,
    this.tokenExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SocialConnection.fromJson(Map<String, dynamic> json) {
    return SocialConnection(
      id: json['id'],
      platform: json['platform'],
      platformUserId: json['platform_user_id'],
      platformUsername: json['platform_username'],
      platformDisplayName: json['platform_display_name'],
      platformProfilePicture: json['platform_profile_picture'],
      isTokenValid: json['is_token_valid'] ?? true,
      tokenExpiresAt: json['token_expires_at'] != null
          ? DateTime.parse(json['token_expires_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// OAuth authorization response
class OAuthAuthorizeResponse {
  final String authorizationUrl;
  final String state;

  OAuthAuthorizeResponse({required this.authorizationUrl, required this.state});

  factory OAuthAuthorizeResponse.fromJson(Map<String, dynamic> json) {
    return OAuthAuthorizeResponse(
      authorizationUrl: json['authorization_url'],
      state: json['state'],
    );
  }
}

/// Publish result model
class PublishResult {
  final bool success;
  final Map<String, dynamic> results;

  PublishResult({required this.success, required this.results});

  factory PublishResult.fromJson(Map<String, dynamic> json) {
    return PublishResult(
      success: json['success'],
      results: Map<String, dynamic>.from(json['results']),
    );
  }
}
