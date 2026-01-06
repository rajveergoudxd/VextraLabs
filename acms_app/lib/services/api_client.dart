import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:acms_app/core/config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  // Token refresh state management
  bool _isRefreshing = false;
  final List<Function(String)> _pendingRequests = [];

  factory ApiClient() {
    return _instance;
  }

  final _logoutController = StreamController<void>.broadcast();
  Stream<void> get onLogout => _logoutController.stream;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Config.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Handle 401/403 by attempting token refresh
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            // Don't try to refresh for the refresh endpoint itself
            if (e.requestOptions.path.contains('/auth/refresh')) {
              _logoutController.add(null);
              return handler.next(e);
            }

            // Try to refresh the token
            final retried = await _handleTokenRefresh(e.requestOptions);
            if (retried != null) {
              return handler.resolve(retried);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Handle token refresh and retry the original request
  Future<Response?> _handleTokenRefresh(RequestOptions requestOptions) async {
    // If already refreshing, queue this request
    if (_isRefreshing) {
      final completer = Completer<Response?>();
      _pendingRequests.add((String newToken) async {
        try {
          final response = await _retryRequest(requestOptions, newToken);
          completer.complete(response);
        } catch (e) {
          completer.complete(null);
        }
      });
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        debugPrint('No refresh token available, logging out');
        _logoutController.add(null);
        return null;
      }

      // Create a new Dio instance for refresh to avoid interceptor loop
      final refreshDio = Dio(BaseOptions(baseUrl: Config.baseUrl));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'];
        await _storage.write(key: 'access_token', value: newAccessToken);
        debugPrint('Token refreshed successfully');

        // Retry all pending requests with new token
        for (final callback in _pendingRequests) {
          callback(newAccessToken);
        }
        _pendingRequests.clear();

        // Retry the original request
        return await _retryRequest(requestOptions, newAccessToken);
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      // Clear pending requests on failure
      _pendingRequests.clear();
      _logoutController.add(null);
    } finally {
      _isRefreshing = false;
    }

    return null;
  }

  /// Retry a failed request with a new token
  Future<Response> _retryRequest(
    RequestOptions requestOptions,
    String newToken,
  ) async {
    final options = Options(
      method: requestOptions.method,
      headers: {...requestOptions.headers, 'Authorization': 'Bearer $newToken'},
    );

    return await dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
