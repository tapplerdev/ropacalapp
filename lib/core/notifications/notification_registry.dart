import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:ropacalapp/core/notifications/notification_channels.dart';
import 'package:ropacalapp/core/notifications/notification_event.dart';

/// Configuration for one notification event type.
/// This is a pure data/function record — no side effects.
class NotificationTypeConfig {
  final String eventType;
  final String channelKey;
  final NotificationLayout layout;
  final NotificationPriority priority;

  /// Which user roles should receive this notification.
  /// Empty list = all roles.
  final List<String> allowedRoles;

  /// Builds the notification title from the event payload.
  final String Function(Map<String, dynamic> payload) titleBuilder;

  /// Builds the notification body text.
  final String Function(Map<String, dynamic> payload) bodyBuilder;

  /// Builds a bigPicture URL (for BigPicture layout).
  final String Function(Map<String, dynamic> payload)? bigPictureBuilder;

  /// Builds progress value 0-100 (for ProgressBar layout).
  final int Function(Map<String, dynamic> payload)? progressBuilder;

  /// Action buttons to attach.
  final List<NotificationActionButton> Function(Map<String, dynamic> payload)?
      actionButtonsBuilder;

  /// Group key for notification grouping.
  final String? groupKey;

  /// Route path for deep-linking when notification is tapped.
  final String Function(Map<String, dynamic> payload)? deepLinkBuilder;

  /// Whether to also trigger an in-app overlay/dialog.
  final bool showInAppOverlay;

  /// Whether to add to the in-app notification feed.
  final bool addToFeed;

  /// Whether this event triggers side effects (provider invalidations).
  final bool hasSideEffects;

  const NotificationTypeConfig({
    required this.eventType,
    required this.channelKey,
    this.layout = NotificationLayout.Default,
    this.priority = NotificationPriority.normal,
    this.allowedRoles = const [],
    required this.titleBuilder,
    required this.bodyBuilder,
    this.bigPictureBuilder,
    this.progressBuilder,
    this.actionButtonsBuilder,
    this.groupKey,
    this.deepLinkBuilder,
    this.showInAppOverlay = false,
    this.addToFeed = true,
    this.hasSideEffects = false,
  });
}

/// The registry: a static map of event type → config.
/// To add a new notification type, add an entry here. That's it.
class NotificationRegistry {
  NotificationRegistry._();

  static final Map<String, NotificationTypeConfig> _configs = {
    for (final config in _allConfigs) config.eventType: config,
  };

  /// Look up config by event type. Returns null if unregistered.
  static NotificationTypeConfig? getConfig(String eventType) =>
      _configs[eventType];

  /// All registered event types.
  static List<String> get registeredTypes => _configs.keys.toList();

  /// All configs for a given channel (used by settings UI).
  static List<NotificationTypeConfig> configsForChannel(String channelKey) =>
      _allConfigs.where((c) => c.channelKey == channelKey).toList();

  // =========================================================================
  //  COMPLETE REGISTRY
  // =========================================================================

  static final List<NotificationTypeConfig> _allConfigs = [
    // -----------------------------------------------------------------------
    //  SHIFT EVENTS
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'shift_created',
      channelKey: NotificationChannels.shiftUpdates,
      priority: NotificationPriority.high,
      allowedRoles: const ['driver'],
      titleBuilder: (_) => 'New Shift Assigned',
      bodyBuilder: (p) {
        final taskCount = p['task_count'] ?? 0;
        return 'You have a new shift with $taskCount stops. Tap to view.';
      },
      deepLinkBuilder: (_) => '/home',
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'shift_edited',
      channelKey: NotificationChannels.shiftUpdates,
      layout: NotificationLayout.BigText,
      priority: NotificationPriority.high,
      allowedRoles: const ['driver'],
      titleBuilder: (p) {
        final manager = p['manager_name'] ?? 'Manager';
        return 'Shift Modified by $manager';
      },
      bodyBuilder: (p) {
        final reason = p['reason'] ?? 'No reason provided';
        return 'Your shift has been updated. Reason: $reason';
      },
      deepLinkBuilder: (_) => '/home',
      showInAppOverlay: true,
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'shift_reassigned',
      channelKey: NotificationChannels.shiftUpdates,
      priority: NotificationPriority.critical,
      allowedRoles: const ['driver'],
      titleBuilder: (_) => 'Shift Reassigned',
      bodyBuilder: (p) {
        final reason = p['reason'] ?? '';
        return reason.toString().isNotEmpty
            ? 'Your shift has been reassigned. Reason: $reason'
            : 'Your shift has been reassigned to another driver.';
      },
      deepLinkBuilder: (_) => '/home',
      showInAppOverlay: true,
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'shift_cancelled',
      channelKey: NotificationChannels.shiftUpdates,
      priority: NotificationPriority.critical,
      allowedRoles: const ['driver'],
      titleBuilder: (_) => 'Shift Cancelled',
      bodyBuilder: (p) {
        final cancelledBy = p['cancelled_by'];
        if (cancelledBy != null && cancelledBy.toString().isNotEmpty) {
          return 'Your shift has been cancelled by $cancelledBy.';
        }
        final message =
            p['message'] ?? 'Your shift has been cancelled by management.';
        return message.toString();
      },
      actionButtonsBuilder: (_) => [
        NotificationActionButton(
          key: 'ACKNOWLEDGE',
          label: 'Acknowledge',
          actionType: ActionType.Default,
        ),
      ],
      deepLinkBuilder: (_) => '/home',
      showInAppOverlay: true,
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'task_removed',
      channelKey: NotificationChannels.shiftUpdates,
      priority: NotificationPriority.high,
      allowedRoles: const ['driver'],
      titleBuilder: (p) {
        final count = p['removed_count'] ?? 1;
        return '$count Stop${(count as int) > 1 ? 's' : ''} Removed';
      },
      bodyBuilder: (p) {
        final manager = p['manager_name'] ?? 'Manager';
        final reason = p['reason'] ?? '';
        return reason.toString().isNotEmpty
            ? '$manager removed stops from your route. Reason: $reason'
            : '$manager removed stops from your route.';
      },
      deepLinkBuilder: (_) => '/home',
      showInAppOverlay: true,
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'shift_deleted',
      channelKey: NotificationChannels.shiftUpdates,
      priority: NotificationPriority.critical,
      allowedRoles: const ['driver'],
      titleBuilder: (_) => 'Shift Cleared',
      bodyBuilder: (p) {
        final message =
            p['message'] ?? 'Your shift has been cleared by management.';
        return message.toString();
      },
      actionButtonsBuilder: (_) => [
        NotificationActionButton(
          key: 'ACKNOWLEDGE',
          label: 'Acknowledge',
          actionType: ActionType.Default,
        ),
      ],
      deepLinkBuilder: (_) => '/home',
      showInAppOverlay: true,
      hasSideEffects: true,
    ),

    // -----------------------------------------------------------------------
    //  ROUTE EVENTS
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'route_assigned',
      channelKey: NotificationChannels.routeUpdates,
      priority: NotificationPriority.high,
      allowedRoles: const ['driver'],
      titleBuilder: (_) => 'New Route Assigned!',
      bodyBuilder: (p) {
        final binCount = p['total_bins'] ?? p['bin_count'] ?? 0;
        return 'You have a new route with $binCount bins. Start your shift to begin.';
      },
      deepLinkBuilder: (_) => '/home',
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'route_updated',
      channelKey: NotificationChannels.routeUpdates,
      priority: NotificationPriority.high,
      allowedRoles: const ['driver'],
      titleBuilder: (_) => 'Route Update',
      bodyBuilder: (p) {
        final action = p['action_type'] ?? 'updated';
        final binNumber = p['bin_number'];
        if (binNumber != null) {
          return 'Bin #$binNumber has been $action in your route.';
        }
        return 'Your route has been modified. Check your navigation.';
      },
      deepLinkBuilder: (_) => '/home',
      showInAppOverlay: true,
      hasSideEffects: true,
    ),

    // -----------------------------------------------------------------------
    //  MOVE REQUEST EVENTS
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'move_request_assigned',
      channelKey: NotificationChannels.moveRequests,
      priority: NotificationPriority.high,
      allowedRoles: const ['driver'],
      titleBuilder: (p) {
        final binNumber = p['move_request']?['bin_number'];
        return binNumber != null
            ? 'Move Request: Bin #$binNumber'
            : 'New Move Request Assigned';
      },
      bodyBuilder: (p) {
        final pickup =
            p['move_request']?['original_address'] ?? 'Unknown';
        final dropoff = p['move_request']?['new_address'];
        return dropoff != null
            ? 'Pickup: $pickup\nDropoff: $dropoff'
            : 'Pickup: $pickup';
      },
      actionButtonsBuilder: (_) => [
        NotificationActionButton(
          key: 'VIEW_DETAILS',
          label: 'View Details',
          actionType: ActionType.Default,
        ),
      ],
      deepLinkBuilder: (_) => '/home',
      showInAppOverlay: true,
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'move_request_created',
      channelKey: NotificationChannels.moveRequests,
      priority: NotificationPriority.normal,
      allowedRoles: const ['admin'],
      titleBuilder: (_) => 'New Move Request',
      bodyBuilder: (p) {
        final binId = p['bin_id'] ?? 'Unknown';
        return 'A new move request has been created for bin $binId.';
      },
      groupKey: 'move_requests',
      deepLinkBuilder: (_) => '/manager/move-requests',
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'move_request_updated',
      channelKey: NotificationChannels.moveRequests,
      priority: NotificationPriority.normal,
      allowedRoles: const ['admin'],
      titleBuilder: (_) => 'Move Request Updated',
      bodyBuilder: (p) {
        final status = p['status'] ?? 'updated';
        final binId = p['bin_id'] ?? '';
        return 'Move request for bin $binId status: $status.';
      },
      groupKey: 'move_requests',
      deepLinkBuilder: (_) => '/manager/move-requests',
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'move_request_cancelled',
      channelKey: NotificationChannels.moveRequests,
      priority: NotificationPriority.normal,
      titleBuilder: (_) => 'Move Request Cancelled',
      bodyBuilder: (p) {
        final binId = p['bin_id'] ?? '';
        return 'The move request for bin $binId has been cancelled.';
      },
      deepLinkBuilder: (_) => '/home',
      hasSideEffects: true,
    ),

    // -----------------------------------------------------------------------
    //  BIN EVENTS
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'bin_updated',
      channelKey: NotificationChannels.binAlerts,
      layout: NotificationLayout.ProgressBar,
      priority: NotificationPriority.normal,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final binNumber = p['bin_number'] ?? p['id'] ?? 'Unknown';
        return 'Bin #$binNumber Updated';
      },
      bodyBuilder: (p) {
        final fill = p['fill_percentage'];
        final status = p['status'] ?? 'updated';
        if (fill != null) {
          return 'Fill level: $fill% | Status: $status';
        }
        return 'Bin status changed to: $status';
      },
      progressBuilder: (p) {
        final fill = p['fill_percentage'];
        if (fill is int) return fill.clamp(0, 100);
        if (fill is double) return fill.round().clamp(0, 100);
        return 0;
      },
      groupKey: 'bin_alerts',
      deepLinkBuilder: (p) => '/bin/${p['id'] ?? ''}',
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'bin_fill_high',
      channelKey: NotificationChannels.binAlerts,
      layout: NotificationLayout.ProgressBar,
      priority: NotificationPriority.high,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final binNumber = p['bin_number'] ?? 'Unknown';
        final fill = p['fill_percentage'] ?? '??';
        return 'Bin #$binNumber at $fill% capacity';
      },
      bodyBuilder: (p) {
        final address = p['address'] ?? p['current_street'] ?? 'Unknown location';
        return '$address — needs collection soon';
      },
      progressBuilder: (p) {
        final fill = p['fill_percentage'];
        if (fill is int) return fill.clamp(0, 100);
        if (fill is double) return fill.round().clamp(0, 100);
        return 80;
      },
      groupKey: 'bin_alerts',
      deepLinkBuilder: (p) => '/bin/${p['id'] ?? ''}',
    ),

    // -----------------------------------------------------------------------
    //  SHIFT PROGRESS (LOCAL — generated client-side)
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'shift_progress',
      channelKey: NotificationChannels.shiftUpdates,
      layout: NotificationLayout.ProgressBar,
      priority: NotificationPriority.low,
      allowedRoles: const ['driver'],
      titleBuilder: (p) {
        final completed = p['completed_bins'] ?? 0;
        final total = p['total_bins'] ?? 0;
        return 'Shift Progress: $completed/$total bins';
      },
      bodyBuilder: (p) {
        final remaining =
            ((p['total_bins'] ?? 0) as int) - ((p['completed_bins'] ?? 0) as int);
        return '$remaining bins remaining';
      },
      progressBuilder: (p) {
        final completed = (p['completed_bins'] ?? 0) as int;
        final total = (p['total_bins'] ?? 1) as int;
        if (total == 0) return 0;
        return ((completed / total) * 100).round().clamp(0, 100);
      },
      addToFeed: false,
    ),

    // -----------------------------------------------------------------------
    //  DRIVER CHECK-IN (BigPicture with photo)
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'driver_checkin_complete',
      channelKey: NotificationChannels.shiftUpdates,
      layout: NotificationLayout.BigPicture,
      priority: NotificationPriority.normal,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final driverName = p['driver_name'] ?? 'Driver';
        final binNumber = p['bin_number'] ?? '';
        return '$driverName checked in at Bin #$binNumber';
      },
      bodyBuilder: (p) {
        final address = p['address'] ?? 'Unknown location';
        return 'Location: $address';
      },
      bigPictureBuilder: (p) => (p['photo_url'] ?? '') as String,
      groupKey: 'driver_checkins',
      deepLinkBuilder: (p) => '/manager/drivers/${p['driver_id'] ?? ''}',
    ),

    // -----------------------------------------------------------------------
    //  DRIVER STATUS (Manager only)
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'driver_shift_change',
      channelKey: NotificationChannels.driverAlerts,
      priority: NotificationPriority.normal,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final status = p['status'] ?? 'changed';
        return 'Driver Shift: ${_capitalize(status.toString())}';
      },
      bodyBuilder: (p) {
        final driverName = p['driver_name'] ?? p['driver_id'] ?? 'Unknown';
        final status = p['status'] ?? '';
        return '$driverName shift status: $status';
      },
      groupKey: 'driver_status',
      deepLinkBuilder: (p) => '/manager/drivers/${p['driver_id'] ?? ''}',
      hasSideEffects: true,
    ),

    // -----------------------------------------------------------------------
    //  POTENTIAL LOCATION EVENTS (Manager only)
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'potential_location_created',
      channelKey: NotificationChannels.systemUpdates,
      priority: NotificationPriority.low,
      allowedRoles: const ['admin'],
      titleBuilder: (_) => 'New Potential Location',
      bodyBuilder: (p) {
        final address = p['address'] ?? 'Unknown';
        return 'A driver reported a potential bin location: $address';
      },
      groupKey: 'potential_locations',
      deepLinkBuilder: (_) => '/manager/potential-locations',
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'potential_location_converted',
      channelKey: NotificationChannels.systemUpdates,
      priority: NotificationPriority.low,
      allowedRoles: const ['admin'],
      titleBuilder: (_) => 'Location Converted to Bin',
      bodyBuilder: (_) =>
          'A potential location has been converted to an active bin.',
      groupKey: 'potential_locations',
      deepLinkBuilder: (_) => '/manager/potential-locations',
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'potential_location_deleted',
      channelKey: NotificationChannels.systemUpdates,
      priority: NotificationPriority.low,
      allowedRoles: const ['admin'],
      titleBuilder: (_) => 'Potential Location Removed',
      bodyBuilder: (_) => 'A potential location has been deleted.',
      groupKey: 'potential_locations',
      hasSideEffects: true,
    ),

    // -----------------------------------------------------------------------
    //  ZONE EVENTS (Manager only)
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'zone_created',
      channelKey: NotificationChannels.systemUpdates,
      priority: NotificationPriority.low,
      allowedRoles: const ['admin'],
      titleBuilder: (_) => 'New Zone Created',
      bodyBuilder: (_) => 'A new collection zone has been created.',
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'zone_updated',
      channelKey: NotificationChannels.systemUpdates,
      priority: NotificationPriority.low,
      allowedRoles: const ['admin'],
      titleBuilder: (_) => 'Zone Updated',
      bodyBuilder: (_) => 'A collection zone has been modified.',
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'zone_merged',
      channelKey: NotificationChannels.systemUpdates,
      priority: NotificationPriority.low,
      allowedRoles: const ['admin'],
      titleBuilder: (_) => 'Zones Merged',
      bodyBuilder: (_) => 'Two or more zones have been merged.',
      hasSideEffects: true,
    ),
    // -----------------------------------------------------------------------
    //  WAREHOUSE / CONFIG EVENTS (Manager only)
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'warehouse_location_updated',
      channelKey: NotificationChannels.systemUpdates,
      priority: NotificationPriority.low,
      allowedRoles: const ['admin'],
      titleBuilder: (_) => 'Warehouse Location Updated',
      bodyBuilder: (p) {
        final address = p['address'] ?? '';
        return address.toString().isNotEmpty
            ? 'Warehouse moved to: $address'
            : 'Warehouse location has been updated.';
      },
    ),

    // -----------------------------------------------------------------------
    //  DAILY DIGEST EVENTS (scheduled backend push, Manager only)
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'digest_overdue_moves',
      channelKey: NotificationChannels.moveRequests,
      priority: NotificationPriority.high,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final count = p['overdue_count'] ?? '?';
        return '$count Overdue Move Request${_pluralS(count)}';
      },
      bodyBuilder: (_) => 'These moves are past their scheduled date.',
      deepLinkBuilder: (_) => '/manager/move-requests',
    ),

    NotificationTypeConfig(
      eventType: 'digest_upcoming_moves',
      channelKey: NotificationChannels.moveRequests,
      priority: NotificationPriority.normal,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final urgent = _toInt(p['urgent_count']);
        final soon = _toInt(p['soon_count']);
        final total = urgent + soon;
        return '$total Move Request${_pluralS(total)} Due Soon';
      },
      bodyBuilder: (p) {
        final urgent = _toInt(p['urgent_count']);
        final soon = _toInt(p['soon_count']);
        final parts = <String>[];
        if (urgent > 0) parts.add('$urgent urgent (< 24h)');
        if (soon > 0) parts.add('$soon due within 3 days');
        return parts.join(', ');
      },
      deepLinkBuilder: (_) => '/manager/move-requests',
    ),

    NotificationTypeConfig(
      eventType: 'digest_warehouse_bins',
      channelKey: NotificationChannels.binAlerts,
      priority: NotificationPriority.normal,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final count = p['warehouse_count'] ?? '?';
        return '$count Bin${_pluralS(count)} in Warehouse';
      },
      bodyBuilder: (_) => 'Awaiting redeployment.',
      deepLinkBuilder: (_) => '/manager/move-requests',
    ),

    // -----------------------------------------------------------------------
    //  REAL-TIME MOVE REQUEST ALERTS (Backend monitor, Manager only)
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'move_request_overdue',
      channelKey: NotificationChannels.moveRequests,
      priority: NotificationPriority.critical,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final binNumber = p['bin_number'] ?? '?';
        return 'Move Request Overdue: Bin #$binNumber';
      },
      bodyBuilder: (p) {
        final hours = p['hours_overdue'] ?? '?';
        return 'This move is $hours hours past its scheduled date.';
      },
      deepLinkBuilder: (_) => '/manager/move-requests',
      groupKey: 'move_request_alerts',
      showInAppOverlay: true,
      addToFeed: true,
      hasSideEffects: true,
    ),

    NotificationTypeConfig(
      eventType: 'move_request_due_soon',
      channelKey: NotificationChannels.moveRequests,
      priority: NotificationPriority.high,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final binNumber = p['bin_number'] ?? '?';
        return 'Move Due Soon: Bin #$binNumber';
      },
      bodyBuilder: (p) {
        final hours = p['hours_until'] ?? '?';
        return 'Due in $hours hours. Plan ahead.';
      },
      deepLinkBuilder: (_) => '/manager/move-requests',
      groupKey: 'move_request_alerts',
      showInAppOverlay: true,
      addToFeed: true,
      hasSideEffects: true,
    ),

    // -----------------------------------------------------------------------
    //  DAILY REPORT EVENTS (Scheduled backend push, Manager only)
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'daily_move_report',
      channelKey: NotificationChannels.moveRequests,
      priority: NotificationPriority.high,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final overdue = _toInt(p['overdue_count']);
        final urgent = _toInt(p['urgent_count']);
        final soon = _toInt(p['soon_count']);
        final total = overdue + urgent + soon;
        return 'Daily Move Report: $total Request${_pluralS(total)}';
      },
      bodyBuilder: (p) {
        final parts = <String>[];
        final overdue = _toInt(p['overdue_count']);
        final urgent = _toInt(p['urgent_count']);
        final soon = _toInt(p['soon_count']);
        final warehouse = _toInt(p['warehouse_count']);
        if (overdue > 0) {
          parts.add('$overdue move${overdue == 1 ? '' : 's'} overdue and need attention');
        }
        if (urgent > 0) {
          parts.add('$urgent move${urgent == 1 ? '' : 's'} due within 24 hours');
        }
        if (soon > 0) {
          parts.add('$soon move${soon == 1 ? '' : 's'} coming up in the next few days');
        }
        if (warehouse > 0) {
          parts.add('$warehouse bin${warehouse == 1 ? '' : 's'} sitting in warehouse');
        }
        return parts.isEmpty
            ? 'All clear — no pending move requests today.'
            : parts.join('. ') + '.';
      },
      deepLinkBuilder: (_) => '/manager/move-requests',
      groupKey: 'daily_reports',
    ),

    NotificationTypeConfig(
      eventType: 'daily_bin_check_report',
      channelKey: NotificationChannels.binAlerts,
      priority: NotificationPriority.high,
      allowedRoles: const ['admin'],
      titleBuilder: (p) {
        final critical = _toInt(p['critical_count']);
        final overdue = _toInt(p['overdue_count']);
        final total = critical + overdue;
        return 'Bin Check Report: $total Bin${_pluralS(total)} Need Checking';
      },
      bodyBuilder: (p) {
        final parts = <String>[];
        final critical = _toInt(p['critical_count']);
        final overdue = _toInt(p['overdue_count']);
        if (critical > 0) {
          parts.add('$critical bin${critical == 1 ? " hasn\'t" : "s haven\'t"} been checked in over 2 weeks');
        }
        if (overdue > 0) {
          parts.add('$overdue bin${overdue == 1 ? " is" : "s are"} overdue for a check (7–13 days)');
        }
        return parts.isEmpty
            ? 'All bins are up to date!'
            : parts.join('. ') + '.';
      },
      deepLinkBuilder: (_) => '/manager/bins',
      groupKey: 'daily_reports',
    ),

    // -----------------------------------------------------------------------
    //  AIRTAG DRIFT ALERTS (Backend 5-min poll, Manager only)
    // -----------------------------------------------------------------------
    NotificationTypeConfig(
      eventType: 'bin_drift_alert',
      channelKey: NotificationChannels.binAlerts,
      priority: NotificationPriority.critical,
      allowedRoles: const ['admin', 'manager'],
      titleBuilder: (p) {
        final binNumber = p['bin_number'] ?? '?';
        return 'Bin $binNumber Moved!';
      },
      bodyBuilder: (p) {
        final distance = p['distance_meters'] ?? '?';
        return 'Detected ${distance}m from assigned location';
      },
      deepLinkBuilder: (_) => '/home',
      showInAppOverlay: true,
      addToFeed: true,
    ),
  ];
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _pluralS(dynamic n) {
  final v = _toInt(n);
  return v == 1 ? '' : 's';
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
