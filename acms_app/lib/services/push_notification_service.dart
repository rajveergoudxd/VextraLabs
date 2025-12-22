import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:acms_app/services/notification_service.dart';

/// Service for handling push notifications
class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  String? _token;

  /// Initialize Push Notifications
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // Get the token
    try {
      _token = await _fcm.getToken();
      debugPrint('FCM Token: $_token');

      if (_token != null) {
        // Send token to backend
        await _notificationService.updateFcmToken(_token!);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
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
        // Here we could show a local notification overlay or update the badge
      }
    });
  }
}
