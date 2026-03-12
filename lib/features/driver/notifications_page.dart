import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/notifications/notification_event.dart';
import 'package:ropacalapp/core/notifications/notification_registry.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/notification_provider.dart';

/// Severity buckets for the filter tabs.
enum _Severity { critical, warning, info }

_Severity _eventSeverity(NotificationEvent event) {
  final config = NotificationRegistry.getConfig(event.eventType);
  if (config == null) return _Severity.info;
  switch (config.priority) {
    case NotificationPriority.critical:
      return _Severity.critical;
    case NotificationPriority.high:
      return _Severity.warning;
    case NotificationPriority.normal:
    case NotificationPriority.low:
      return _Severity.info;
  }
}

Color _severityColor(_Severity s) {
  switch (s) {
    case _Severity.critical:
      return AppColors.alertRed;
    case _Severity.warning:
      return AppColors.warningOrange;
    case _Severity.info:
      return AppColors.primaryGreen;
  }
}

IconData _eventIcon(String eventType) {
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

/// Unified notifications page. Reads from the live notification feed provider.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(notificationFeedProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          actions: [
            if (feed.isNotEmpty)
              TextButton(
                onPressed: () async {
                  // Mark all as read on the backend
                  try {
                    final apiService = ref.read(apiServiceProvider);
                    await apiService.patch('/api/notifications/read-all', {});
                  } catch (_) {}
                  ref.read(notificationFeedProvider.notifier).clearAll();
                },
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: TabBar(
                isScrollable: false,
                labelColor: AppColors.primaryGreen,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: AppColors.primaryGreen,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: [
                  _buildTab('All', feed.length),
                  _buildTab(
                    'Critical',
                    feed
                        .where((e) =>
                            _eventSeverity(e) == _Severity.critical)
                        .length,
                  ),
                  _buildTab(
                    'Warn',
                    feed
                        .where((e) =>
                            _eventSeverity(e) == _Severity.warning)
                        .length,
                  ),
                  _buildTab(
                    'Updates',
                    feed
                        .where(
                            (e) => _eventSeverity(e) == _Severity.info)
                        .length,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _NotificationList(events: feed),
            _NotificationList(
              events: feed
                  .where((e) => _eventSeverity(e) == _Severity.critical)
                  .toList(),
            ),
            _NotificationList(
              events: feed
                  .where((e) => _eventSeverity(e) == _Severity.warning)
                  .toList(),
            ),
            _NotificationList(
              events: feed
                  .where((e) => _eventSeverity(e) == _Severity.info)
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Tab _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<NotificationEvent> events;

  const _NotificationList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications',
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _NotificationCard(event: events[index]);
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEvent event;

  const _NotificationCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final severity = _eventSeverity(event);
    final color = _severityColor(severity);
    final icon = _eventIcon(event.eventType);
    final config = NotificationRegistry.getConfig(event.eventType);

    final title = config?.titleBuilder(event.payload) ?? event.eventType;
    final body = config?.bodyBuilder(event.payload) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/notification-detail', extra: event);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _formatTimeAgo(event.receivedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatTimeAgo(DateTime dateTime) {
  final duration = DateTime.now().difference(dateTime);
  if (duration.inDays > 0) return '${duration.inDays}d ago';
  if (duration.inHours > 0) return '${duration.inHours}h ago';
  if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
  return 'Just now';
}
