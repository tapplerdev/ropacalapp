import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

/// Defines all notification channels.
/// Android: These become actual system notification channels.
/// iOS: These map to notification categories.
class NotificationChannels {
  NotificationChannels._();

  // Channel key constants
  static const String shiftUpdates = 'shift_updates';
  static const String routeUpdates = 'route_updates';
  static const String moveRequests = 'move_requests';
  static const String binAlerts = 'bin_alerts';
  static const String driverAlerts = 'driver_alerts';
  static const String systemUpdates = 'system_updates';

  /// All channel definitions for awesome_notifications initialization.
  static List<NotificationChannel> get allChannels => [
        NotificationChannel(
          channelKey: shiftUpdates,
          channelName: 'Shift Updates',
          channelDescription:
              'Shift assignments, cancellations, and edits',
          channelGroupKey: 'operations',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF5E9646),
          ledColor: const Color(0xFF5E9646),
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: routeUpdates,
          channelName: 'Route Updates',
          channelDescription:
              'Route assignments, modifications, and re-routing',
          channelGroupKey: 'operations',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF2196F3),
          ledColor: const Color(0xFF2196F3),
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: moveRequests,
          channelName: 'Move Requests',
          channelDescription: 'Bin move requests and status updates',
          channelGroupKey: 'operations',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFFF6AB2F),
          ledColor: const Color(0xFFF6AB2F),
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: binAlerts,
          channelName: 'Bin Alerts',
          channelDescription: 'High fill levels, bin status changes',
          channelGroupKey: 'alerts',
          importance: NotificationImportance.Default,
          defaultColor: const Color(0xFFE6492D),
          ledColor: const Color(0xFFE6492D),
          playSound: true,
        ),
        NotificationChannel(
          channelKey: driverAlerts,
          channelName: 'Driver Alerts',
          channelDescription:
              'Driver went offline, shift late, location issues',
          channelGroupKey: 'alerts',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFFE6492D),
          ledColor: const Color(0xFFE6492D),
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: systemUpdates,
          channelName: 'System Updates',
          channelDescription: 'App updates and general information',
          channelGroupKey: 'general',
          importance: NotificationImportance.Low,
          defaultColor: const Color(0xFF5E9646),
        ),
      ];

  /// Channel groups for organizing channels in Android settings.
  static List<NotificationChannelGroup> get channelGroups => [
        NotificationChannelGroup(
          channelGroupKey: 'operations',
          channelGroupName: 'Operations',
        ),
        NotificationChannelGroup(
          channelGroupKey: 'alerts',
          channelGroupName: 'Alerts',
        ),
        NotificationChannelGroup(
          channelGroupKey: 'general',
          channelGroupName: 'General',
        ),
      ];

  /// Human-readable channel names for settings UI.
  static const Map<String, String> channelDisplayNames = {
    shiftUpdates: 'Shift Updates',
    routeUpdates: 'Route Updates',
    moveRequests: 'Move Requests',
    binAlerts: 'Bin Alerts',
    driverAlerts: 'Driver Alerts',
    systemUpdates: 'System Updates',
  };
}
