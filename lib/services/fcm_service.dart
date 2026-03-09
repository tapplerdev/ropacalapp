import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/notifications/notification_service.dart';
import 'package:ropacalapp/core/notifications/notification_router.dart';
import 'package:ropacalapp/core/notifications/notification_adapters.dart';

/// Firebase Cloud Messaging Service
/// Handles push notification permissions, token management, and message routing.
/// Token registration with the backend is handled by auth_provider on login.
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Set by notification_provider when router is created, so FCM messages
  /// flow through the full pipeline (dedup, role check, prefs, side effects).
  static NotificationRouter? router;

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
        AppLogger.general('FCM Token refreshed');
        // Note: re-registration with backend happens on next login
        // or could be triggered via a provider if needed
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
          'App opened from terminated state: '
          '${initialMessage.notification?.title}',
        );
        _handleMessage(initialMessage);
      }

      AppLogger.general('FCM initialized successfully');
    } catch (e) {
      AppLogger.general(
        'FCM initialization error: $e',
        level: AppLogger.error,
      );
    }
  }

  /// Handle incoming push notification.
  /// Routes through NotificationRouter for dedup, role/pref checks,
  /// and side effects. Falls back to direct display on cold start.
  static void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    AppLogger.general('FCM Message Type: $type, Data: $data');

    final event = NotificationAdapters.fromFCM(data);

    if (router != null) {
      router!.receive(event);
    } else {
      NotificationService().showNotification(event);
    }
  }
}
