import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// Notification severity levels matching the API contract
enum NotificationSeverity { critical, warning, info }

/// Notification type — defines what happened
enum NotificationType {
  binFull,
  driverOffline,
  shiftLate,
  routeDelayed,
  routeAssigned,
  shiftCompleted,
  moveRequest,
  binCollected,
  appUpdate,
}

/// Unified notification model — single shape for the future API
class AppNotification {
  final String id;
  final NotificationSeverity severity;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  // Metadata for deep-linking
  final String? binId;
  final String? driverId;
  final String? shiftId;

  const AppNotification({
    required this.id,
    required this.severity,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.binId,
    this.driverId,
    this.shiftId,
  });
}

/// Unified notifications page — replaces both NotificationsPage and ManagerAlertsTab
/// Bell icon navigates here. Filter tabs: All | Critical | Warnings | Updates
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TODO: Replace with real provider/API call
  final List<AppNotification> _notifications = _getMockNotifications();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AppNotification> _filtered(NotificationSeverity? severity) {
    if (severity == null) return _notifications;
    return _notifications.where((n) => n.severity == severity).toList();
  }

  int _unreadCount(NotificationSeverity? severity) {
    return _filtered(severity).where((n) => !n.isRead).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
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
              controller: _tabController,
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
                _buildTab('All', null),
                _buildTab('Critical', NotificationSeverity.critical),
                _buildTab('Warn', NotificationSeverity.warning),
                _buildTab('Updates', NotificationSeverity.info),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NotificationList(notifications: _filtered(null)),
          _NotificationList(notifications: _filtered(NotificationSeverity.critical)),
          _NotificationList(notifications: _filtered(NotificationSeverity.warning)),
          _NotificationList(notifications: _filtered(NotificationSeverity.info)),
        ],
      ),
    );
  }

  Tab _buildTab(String label, NotificationSeverity? severity) {
    final count = _unreadCount(severity);
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: severity == NotificationSeverity.critical
                    ? AppColors.alertRed
                    : severity == NotificationSeverity.warning
                        ? AppColors.warningOrange
                        : AppColors.primaryGreen,
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

/// Scrollable list of notification cards
class _NotificationList extends StatelessWidget {
  final List<AppNotification> notifications;

  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
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

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () async {
        // TODO: Refetch from API
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _NotificationCard(notification: notifications[index]);
        },
      ),
    );
  }
}

/// Individual notification card
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor();
    final severityIcon = _getSeverityIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead
            ? null
            : Border.all(color: severityColor.withValues(alpha: 0.2), width: 1),
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
            // TODO: Deep-link based on notification.type and metadata
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Severity icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    severityIcon,
                    color: severityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: severityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimeAgo(notification.createdAt),
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

  Color _getSeverityColor() {
    switch (notification.severity) {
      case NotificationSeverity.critical:
        return AppColors.alertRed;
      case NotificationSeverity.warning:
        return AppColors.warningOrange;
      case NotificationSeverity.info:
        return AppColors.primaryGreen;
    }
  }

  IconData _getSeverityIcon() {
    switch (notification.type) {
      case NotificationType.binFull:
        return Icons.delete_outline;
      case NotificationType.driverOffline:
        return Icons.signal_wifi_off;
      case NotificationType.shiftLate:
        return Icons.schedule;
      case NotificationType.routeDelayed:
        return Icons.warning_amber_rounded;
      case NotificationType.routeAssigned:
        return Icons.route;
      case NotificationType.shiftCompleted:
        return Icons.check_circle_outline;
      case NotificationType.moveRequest:
        return Icons.swap_horiz;
      case NotificationType.binCollected:
        return Icons.check;
      case NotificationType.appUpdate:
        return Icons.update;
    }
  }
}

/// Format time ago
String _formatTimeAgo(DateTime dateTime) {
  final duration = DateTime.now().difference(dateTime);

  if (duration.inDays > 0) {
    return '${duration.inDays}d ago';
  } else if (duration.inHours > 0) {
    return '${duration.inHours}h ago';
  } else if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m ago';
  } else {
    return 'Just now';
  }
}

// =============================================================================
// Mock Data (TODO: Replace with real API call)
// GET /manager/notifications?severity=critical&is_read=false&limit=50
// Response: { notifications: [...], unread_count: 5, critical_count: 2 }
// =============================================================================

List<AppNotification> _getMockNotifications() {
  return [
    // Critical
    AppNotification(
      id: '1',
      severity: NotificationSeverity.critical,
      type: NotificationType.binFull,
      title: 'Bin #876 is 95% full',
      message: '123 Oak St — needs immediate pickup',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      binId: 'bin-876',
    ),
    AppNotification(
      id: '2',
      severity: NotificationSeverity.critical,
      type: NotificationType.driverOffline,
      title: 'Driver Ali went offline',
      message: 'No signal for 15 minutes during active shift',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      driverId: 'driver-ali',
    ),
    // Warnings
    AppNotification(
      id: '3',
      severity: NotificationSeverity.warning,
      type: NotificationType.shiftLate,
      title: 'Shift started 22 mins late',
      message: 'Omar Gabr — Morning Route A',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      driverId: 'driver-omar',
      shiftId: 'shift-123',
    ),
    AppNotification(
      id: '4',
      severity: NotificationSeverity.warning,
      type: NotificationType.binFull,
      title: 'Bin #451 at 82% capacity',
      message: '456 Main St — schedule collection soon',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      binId: 'bin-451',
    ),
    AppNotification(
      id: '5',
      severity: NotificationSeverity.warning,
      type: NotificationType.routeDelayed,
      title: 'Route delayed',
      message: 'Traffic on Highway 101 — Route B affected',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    // Info / Updates
    AppNotification(
      id: '6',
      severity: NotificationSeverity.info,
      type: NotificationType.routeAssigned,
      title: 'New route assigned',
      message: '3 bins on Main Street route — assigned to Mary',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      driverId: 'driver-mary',
    ),
    AppNotification(
      id: '7',
      severity: NotificationSeverity.info,
      type: NotificationType.shiftCompleted,
      title: 'Shift completed',
      message: 'Mary Johnson finished Route C — 12 bins collected',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      driverId: 'driver-mary',
      shiftId: 'shift-456',
    ),
    AppNotification(
      id: '8',
      severity: NotificationSeverity.info,
      type: NotificationType.moveRequest,
      title: 'Move request completed',
      message: 'Bin #332 moved from 789 Elm St to 101 Pine Ave',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      binId: 'bin-332',
    ),
    AppNotification(
      id: '9',
      severity: NotificationSeverity.info,
      type: NotificationType.binCollected,
      title: 'Bin #120 collected',
      message: 'Picked up by John Smith at 2:15 PM',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      binId: 'bin-120',
      driverId: 'driver-john',
    ),
  ];
}
