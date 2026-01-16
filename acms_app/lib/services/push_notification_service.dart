import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:acms_app/services/notification_service.dart';

/// Service for handling push notifications
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  FirebaseMessaging? _fcm;
  final NotificationService _notificationService = NotificationService();

  String? _token;

  /// Initialize Push Notifications (without requesting permission)
  Future<void> initialize() async {
    debugPrint('[PushService] initialize() called');
    try {
      _fcm = FirebaseMessaging.instance;
      debugPrint('[PushService] FirebaseMessaging instance obtained');

      // Check current permission status without prompting
      NotificationSettings settings = await _fcm!.getNotificationSettings();
      debugPrint(
        '[PushService] Current permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint(
          '[PushService] Notification permission not granted. Skipping init.',
        );
        return;
      }

      // Get the token
      debugPrint('[PushService] Getting FCM token...');
      _token = await _fcm!.getToken();
      debugPrint(
        '[PushService] FCM Token: ${_token != null ? "${_token!.substring(0, 20)}..." : "NULL"}',
      );

      if (_token != null) {
        // Send token to backend
        debugPrint('[PushService] Sending token to backend...');
        await _notificationService.updateFcmToken(_token!);
        debugPrint('[PushService] Token sent to backend successfully');
      } else {
        debugPrint('[PushService] ERROR: FCM token is null!');
      }

      // Listen to token refresh
      _fcm!.onTokenRefresh.listen((newToken) async {
        debugPrint(
          '[PushService] Token refreshed: ${newToken.substring(0, 20)}...',
        );
        _token = newToken;
        await _notificationService.updateFcmToken(newToken);
      });

      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[PushService] Got a message whilst in the foreground!');
        debugPrint('[PushService] Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
            '[PushService] Message also contained a notification: ${message.notification}',
          );
        }
      });
    } catch (e, stackTrace) {
      debugPrint('[PushService] ERROR in initialize(): $e');
      debugPrint('[PushService] Stack trace: $stackTrace');
    }
  }

  /// Explicitly request permission (e.g. from Settings toggle)
  Future<bool> requestPermission() async {
    debugPrint('[PushService] requestPermission() called');
    try {
      // Use permission_handler for robust request behavior (especially Android 13+)
      final status = await Permission.notification.request();
      debugPrint('[PushService] Permission request result: $status');

      if (status.isGranted) {
        debugPrint(
          '[PushService] User granted permission via permission_handler',
        );
        await initialize(); // Setup listeners now that we have permission
        return true;
      } else if (status.isProvisional) {
        debugPrint('[PushService] User granted provisional permission');
        await initialize();
        return true;
      } else {
        debugPrint(
          '[PushService] User declined or has not accepted permission: $status',
        );
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[PushService] Error requesting permission: $e');
      debugPrint('[PushService] Stack trace: $stackTrace');
      return false;
    }
  }
}
