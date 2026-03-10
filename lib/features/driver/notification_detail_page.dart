import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/notifications/notification_event.dart';
import 'package:ropacalapp/core/notifications/notification_registry.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationEvent? event;

  const NotificationDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Notification not found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final e = event!;
    final config = NotificationRegistry.getConfig(e.eventType);
    final title = config?.titleBuilder(e.payload) ?? e.eventType;
    final body = config?.bodyBuilder(e.payload) ?? '';
    final priority = config?.priority ?? NotificationPriority.normal;
    final color = _priorityColor(priority);
    final icon = _eventIcon(e.eventType);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero header
              _buildHeader(title, icon, color, priority),
              const SizedBox(height: 20),

              // Timestamp
              _buildTimestamp(e.receivedAt),
              const SizedBox(height: 20),

              // Body
              if (body.isNotEmpty) ...[
                _buildBodyCard(body),
                const SizedBox(height: 16),
              ],

              // Payload details
              _buildDetailsCard(e.payload),
              const SizedBox(height: 16),

              // Source
              _buildSourceChip(e.source),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      String title, IconData icon, Color color, NotificationPriority priority) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _priorityLabel(priority),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp(DateTime receivedAt) {
    final timeAgo = _formatTimeAgo(receivedAt);
    final exact = DateFormat('MMM d, yyyy  h:mm a').format(receivedAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded,
              size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeAgo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                exact,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCard(String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Map<String, dynamic> payload) {
    final entries = _extractDisplayEntries(payload);
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSourceChip(NotificationSource source) {
    final label = switch (source) {
      NotificationSource.centrifugo => 'via Live Stream',
      NotificationSource.fcm => 'via Push Notification',
      NotificationSource.local => 'via Local',
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Extract human-readable key-value pairs from the payload.
  /// Skips internal/duplicate fields, formats timestamps, flattens nested maps.
  List<MapEntry<String, String>> _extractDisplayEntries(
      Map<String, dynamic> payload) {
    // Keys that are internal, already shown elsewhere, or raw UUIDs
    const skipKeys = {
      'type',
      'event_type',
      'id',
      'deep_link',
      'timestamp',
      'message', // already shown in body card
      'shift_id',
      'driver_id',
      'bin_id',
      'move_request_id',
      'location_id',
      'zone_id',
    };

    // Keys whose values are Unix timestamps (seconds or milliseconds)
    const timestampKeys = {
      'cancelled_at',
      'created_at',
      'updated_at',
      'scheduled_date',
      'start_time',
      'end_time',
      'ended_at',
    };

    final entries = <MapEntry<String, String>>[];

    void addEntry(String key, dynamic rawValue) {
      if (skipKeys.contains(key)) return;
      if (rawValue == null) return;

      final label = _formatKey(key);
      String value;

      if (timestampKeys.contains(key) && rawValue is num) {
        value = _formatUnixTimestamp(rawValue);
      } else {
        value = rawValue.toString();
      }

      if (value.isNotEmpty) {
        entries.add(MapEntry(label, value));
      }
    }

    for (final entry in payload.entries) {
      if (entry.value is Map) {
        // Flatten nested maps (e.g. move_request: {bin_number: 123, ...})
        final nested = entry.value as Map;
        for (final nestedEntry in nested.entries) {
          addEntry(nestedEntry.key.toString(), nestedEntry.value);
        }
      } else {
        addEntry(entry.key, entry.value);
      }
    }

    return entries;
  }

  /// Format a Unix timestamp (seconds or milliseconds) to a readable date.
  static String _formatUnixTimestamp(num value) {
    final int ms;
    if (value > 9999999999) {
      // Already milliseconds
      ms = value.toInt();
    } else {
      // Seconds — convert to milliseconds
      ms = (value * 1000).toInt();
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('MMM d, yyyy  h:mm a').format(dt);
  }

  /// Convert snake_case key to Title Case label.
  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
    return 'Just now';
  }

  static String _priorityLabel(NotificationPriority priority) {
    return switch (priority) {
      NotificationPriority.critical => 'Critical',
      NotificationPriority.high => 'Warning',
      NotificationPriority.normal => 'Info',
      NotificationPriority.low => 'Low',
    };
  }

  static Color _priorityColor(NotificationPriority priority) {
    return switch (priority) {
      NotificationPriority.critical => AppColors.alertRed,
      NotificationPriority.high => AppColors.warningOrange,
      NotificationPriority.normal => AppColors.primaryGreen,
      NotificationPriority.low => Colors.grey,
    };
  }

  static IconData _eventIcon(String eventType) {
    const map = {
      'shift_created': Icons.work_history,
      'shift_edited': Icons.edit_note,
      'shift_reassigned': Icons.swap_horiz,
      'shift_cancelled': Icons.cancel_outlined,
      'shift_deleted': Icons.delete_outline,
      'task_removed': Icons.remove_circle_outline,
      'route_assigned': Icons.route,
      'route_updated': Icons.alt_route,
      'move_request_assigned': Icons.move_down,
      'move_request_created': Icons.add_location_alt,
      'move_request_updated': Icons.edit_location_alt,
      'move_request_cancelled': Icons.location_off,
      'bin_updated': Icons.delete_outline,
      'bin_fill_high': Icons.warning_amber_rounded,
      'shift_progress': Icons.trending_up,
      'driver_checkin_complete': Icons.camera_alt,
      'driver_shift_change': Icons.person_pin,
      'potential_location_created': Icons.place,
      'potential_location_converted': Icons.check_circle_outline,
      'potential_location_deleted': Icons.location_off,
      'zone_created': Icons.shield,
      'zone_updated': Icons.shield,
      'zone_merged': Icons.merge,
      'warehouse_location_updated': Icons.warehouse,
      'digest_overdue_moves': Icons.schedule_rounded,
      'digest_upcoming_moves': Icons.upcoming_rounded,
      'digest_warehouse_bins': Icons.warehouse_rounded,
    };
    return map[eventType] ?? Icons.notifications_outlined;
  }
}
