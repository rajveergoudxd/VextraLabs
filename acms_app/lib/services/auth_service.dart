import 'package:dio/dio.dart';
import 'package:acms_app/services/api_client.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login/access-token',
        data: {
          'username': email, // OAuth2 standard uses 'username'
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> signup(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'is_active': true,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> forgotPassword(
    String email, {
    String purpose = 'reset_password',
  }) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email, 'purpose': purpose},
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String email,
    String code, {
    String purpose = 'signup',
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'code': code, 'purpose': purpose},
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'new_password': newPassword},
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? profilePicture,
  }) async {
    try {
      final response = await _dio.put(
        '/users/me',
        data: {
          if (fullName != null) 'full_name': fullName,
          if (profilePicture != null) 'profile_picture': profilePicture,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> uploadProfilePicture(dynamic file) async {
    try {
      // file can be File (mobile) or XFile (web/mobile)
      // handling FormData manually
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post('/upload/', data: formData);
      return response.data['url'];
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
