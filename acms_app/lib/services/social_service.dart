import 'package:acms_app/services/api_client.dart';

/// Service for social features: follow system, user search, public profiles
class SocialService {
  final ApiClient _apiClient = ApiClient();

  // ============== Follow System ==============

  /// Follow a user by their ID
  Future<Map<String, dynamic>> followUser(int userId) async {
    final response = await _apiClient.dio.post('/social/follow/$userId');
    return response.data;
  }

  /// Unfollow a user by their ID
  Future<Map<String, dynamic>> unfollowUser(int userId) async {
    final response = await _apiClient.dio.delete('/social/unfollow/$userId');
    return response.data;
  }

  /// Get follow status between current user and target user
  Future<Map<String, dynamic>> getFollowStatus(int userId) async {
    final response = await _apiClient.dio.get('/social/follow-status/$userId');
    return response.data;
  }

  /// Get followers list for a user
  Future<Map<String, dynamic>> getFollowers(
    int userId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await _apiClient.dio.get(
      '/social/followers/$userId',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return response.data;
  }

  /// Get following list for a user
  Future<Map<String, dynamic>> getFollowing(
    int userId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await _apiClient.dio.get(
      '/social/following/$userId',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return response.data;
  }

  // ============== User Search ==============

  /// Search users by username or full name
  Future<Map<String, dynamic>> searchUsers(
    String query, {
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await _apiClient.dio.get(
      '/social/search',
      queryParameters: {'q': query, 'skip': skip, 'limit': limit},
    );
    return response.data;
  }

  /// Get public profile by username
  Future<Map<String, dynamic>> getPublicProfile(String username) async {
    final response = await _apiClient.dio.get('/social/profile/$username');
    return response.data;
  }

  /// Get public profile by user ID
  Future<Map<String, dynamic>> getPublicProfileById(int userId) async {
    final response = await _apiClient.dio.get('/social/profile-by-id/$userId');
    return response.data;
  }
}
