import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:acms_app/services/notification_service.dart';

/// Service for handling push notifications
class PushNotificationService {
  FirebaseMessaging? _fcm;
  final NotificationService _notificationService = NotificationService();

  String? _token;

  /// Initialize Push Notifications (without requesting permission)
  Future<void> initialize() async {
    try {
      _fcm = FirebaseMessaging.instance;

      // Check current permission status without prompting
      NotificationSettings settings = await _fcm!.getNotificationSettings();

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('Notification permission not granted. Skipping init.');
        return;
      }

      // Get the token
      _token = await _fcm!.getToken();
      debugPrint('FCM Token: $_token');

      if (_token != null) {
        // Send token to backend
        await _notificationService.updateFcmToken(_token!);
      }

      // Listen to token refresh
      _fcm!.onTokenRefresh.listen((newToken) async {
        _token = newToken;
        await _notificationService.updateFcmToken(newToken);
      });

      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
            'Message also contained a notification: ${message.notification}',
          );
        }
      });
    } catch (e) {
      debugPrint(
        'FirebaseMessaging not initialized (likely missing config): $e',
      );
    }
  }

  /// Explicitly request permission (e.g. from Settings toggle)
  Future<bool> requestPermission() async {
    try {
      // Use permission_handler for robust request behavior (especially Android 13+)
      final status = await Permission.notification.request();

      if (status.isGranted) {
        debugPrint('User granted permission via permission_handler');
        await initialize(); // Setup listeners now that we have permission
        return true;
      } else if (status.isProvisional) {
        debugPrint('User granted provisional permission');
        await initialize();
        return true;
      } else {
        debugPrint('User declined or has not accepted permission: $status');
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }
}
