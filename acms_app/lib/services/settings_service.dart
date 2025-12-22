import 'package:dio/dio.dart';
import 'package:acms_app/services/api_client.dart';

class SettingsService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get('/settings/me');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateSettings({
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    String? themePreference,
  }) async {
    try {
      final response = await _dio.put(
        '/settings/me',
        data: {
          if (pushNotificationsEnabled != null)
            'push_notifications_enabled': pushNotificationsEnabled,
          if (emailNotificationsEnabled != null)
            'email_notifications_enabled': emailNotificationsEnabled,
          if (themePreference != null) 'theme_preference': themePreference,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _dio.put(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/settings/me');
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('detail')) {
          return data['detail'];
        }
      }
      return 'Network error occurred: ${error.message}';
    }
    return 'An unexpected error occurred';
  }
}
