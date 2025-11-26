import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Firebase Cloud Messaging Service
/// Handles push notifications for route assignments and shift updates
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Get the current FCM token
  static String? get token => _fcmToken;

  /// Initialize FCM and request permissions
  static Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.general('FCM: User granted permission');
      } else {
        AppLogger.general(
          'FCM: User declined permission',
          level: AppLogger.warning,
        );
        return;
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      AppLogger.general('FCM Token: $_fcmToken');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        AppLogger.general('FCM Token refreshed: $newToken');
        // TODO: Send new token to backend
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.general(
          'Received foreground message: ${message.notification?.title}',
        );
        _handleMessage(message);
      });

      // Handle background messages (when app is opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.general(
          'Notification opened app: ${message.notification?.title}',
        );
        _handleMessage(message);
      });

      // Check if app was opened from a notification while terminated
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.general(
          'App opened from terminated state: ${initialMessage.notification?.title}',
        );
        _handleMessage(initialMessage);
      }

      AppLogger.general('FCM initialized successfully');
    } catch (e) {
      AppLogger.general('FCM initialization error: $e', level: AppLogger.error);
    }
  }

  /// Handle incoming push notification
  static void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    AppLogger.general('FCM Message Type: $type');
    AppLogger.general('FCM Message Data: $data');

    switch (type) {
      case 'route_assigned':
        _handleRouteAssigned(data);
        break;
      case 'shift_update':
        _handleShiftUpdate(data);
        break;
      default:
        AppLogger.general(
          'Unknown FCM message type: $type',
          level: AppLogger.warning,
        );
    }
  }

  /// Handle route assignment notification
  static void _handleRouteAssigned(Map<String, dynamic> data) {
    AppLogger.general(
      'Route assigned: ${data['route_id']} with ${data['total_bins']} bins',
    );
    // TODO: Refresh shift state from backend
    // TODO: Show in-app notification
  }

  /// Handle shift update notification
  static void _handleShiftUpdate(Map<String, dynamic> data) {
    AppLogger.general('Shift update: ${data['shift_id']}');
    // TODO: Refresh shift state from backend
  }

  /// Register FCM token with backend
  static Future<void> registerToken() async {
    if (_fcmToken == null) {
      AppLogger.general('No FCM token available', level: AppLogger.warning);
      return;
    }

    try {
      final deviceType = Platform.isIOS ? 'ios' : 'android';

      AppLogger.general('Registering FCM token with backend...');

      // Import will be added at top of file when we use this
      // For now, we'll import it dynamically
      // This will be called from main.dart where we have access to providers

      AppLogger.general('FCM token ready: $_fcmToken');
      AppLogger.general('Device type: $deviceType');
    } catch (e) {
      AppLogger.general(
        'Failed to register FCM token: $e',
        level: AppLogger.error,
      );
    }
  }
}
