import 'package:acms_app/services/api_client.dart';

/// Service for handling notification related API calls
class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// Get paginated list of notifications
  Future<Map<String, dynamic>> getNotifications({
    int skip = 0,
    int limit = 20,
    String? type,
  }) async {
    final Map<String, dynamic> queryParams = {'skip': skip, 'limit': limit};

    if (type != null) {
      queryParams['type'] = type;
    }

    final response = await _apiClient.dio.get(
      '/notifications',
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get unread notification count
  Future<Map<String, dynamic>> getUnreadCount() async {
    final response = await _apiClient.dio.get('/notifications/unread-count');
    return response.data;
  }

  /// Mark a single notification as read
  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    final response = await _apiClient.dio.put(
      '/notifications/$notificationId/read',
    );
    return response.data;
  }

  /// Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    final response = await _apiClient.dio.put('/notifications/mark-all-read');
    return response.data;
  }

  /// Delete a notification
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    final response = await _apiClient.dio.delete(
      '/notifications/$notificationId',
    );
    return response.data;
  }

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String token) async {
    await _apiClient.dio.put(
      '/users/fcm-token',
      queryParameters: {'token': token},
    );
  }
}
