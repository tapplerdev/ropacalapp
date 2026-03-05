import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// Manager Alerts Tab - Real-time notifications and priority items
/// Grouped by severity: Critical, Warnings, Updates
class ManagerAlertsTab extends HookConsumerWidget {
  const ManagerAlertsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showCritical = useState(true);
    final showWarnings = useState(true);
    final showUpdates = useState(true);

    // TODO: Replace with real alert data from provider
    final criticalAlerts = _getMockCriticalAlerts();
    final warningAlerts = _getMockWarningAlerts();
    final updateAlerts = _getMockUpdateAlerts();

    final visibleCount =
      (showCritical.value ? criticalAlerts.length : 0) +
      (showWarnings.value ? warningAlerts.length : 0) +
      (showUpdates.value ? updateAlerts.length : 0);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Alerts',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: Colors.grey.shade700),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'critical',
                checked: showCritical.value,
                child: const Text('Critical'),
              ),
              CheckedPopupMenuItem(
                value: 'warnings',
                checked: showWarnings.value,
                child: const Text('Warnings'),
              ),
              CheckedPopupMenuItem(
                value: 'updates',
                checked: showUpdates.value,
                child: const Text('Updates'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'critical':
                  showCritical.value = !showCritical.value;
                  break;
                case 'warnings':
                  showWarnings.value = !showWarnings.value;
                  break;
                case 'updates':
                  showUpdates.value = !showUpdates.value;
                  break;
              }
            },
          ),
        ],
      ),
      body: visibleCount == 0
          ? const _EmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                // TODO: Implement refresh
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Critical Alerts
                  if (showCritical.value && criticalAlerts.isNotEmpty) ...[
                    _AlertSectionHeader(
                      icon: Icons.error,
                      color: Colors.red,
                      label: 'Critical',
                      count: criticalAlerts.length,
                    ),
                    const SizedBox(height: 12),
                    ...criticalAlerts.map((alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AlertCard(alert: alert),
                    )),
                    const SizedBox(height: 24),
                  ],

                  // Warning Alerts
                  if (showWarnings.value && warningAlerts.isNotEmpty) ...[
                    _AlertSectionHeader(
                      icon: Icons.warning,
                      color: Colors.orange,
                      label: 'Warnings',
                      count: warningAlerts.length,
                    ),
                    const SizedBox(height: 12),
                    ...warningAlerts.map((alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AlertCard(alert: alert),
                    )),
                    const SizedBox(height: 24),
                  ],

                  // Update Alerts
                  if (showUpdates.value && updateAlerts.isNotEmpty) ...[
                    _AlertSectionHeader(
                      icon: Icons.check_circle,
                      color: Colors.green,
                      label: 'Updates',
                      count: updateAlerts.length,
                    ),
                    const SizedBox(height: 12),
                    ...updateAlerts.map((alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AlertCard(alert: alert),
                    )),
                  ],
                ],
              ),
            ),
    );
  }
}

/// Alert section header
class _AlertSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _AlertSectionHeader({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Alert card
class _AlertCard extends StatelessWidget {
  final AlertItem alert;

  const _AlertCard({required this.alert});

  Color _getColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.update:
        return Colors.green;
    }
  }

  IconData _getIcon() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.update:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to alert details
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getIcon(), color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTimeAgo(alert.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                // Action button
                if (alert.actionLabel != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Handle action
                    },
                    icon: Icon(
                      alert.actionIcon ?? Icons.arrow_forward,
                      size: 16,
                    ),
                    label: Text(alert.actionLabel!),
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All caught up! You\'ll see notifications here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Mock Data & Models (TODO: Replace with real providers)
// ============================================================================

enum AlertSeverity { critical, warning, update }

class AlertItem {
  final String id;
  final AlertSeverity severity;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? actionLabel;
  final IconData? actionIcon;

  AlertItem({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    required this.timestamp,
    this.actionLabel,
    this.actionIcon,
  });
}

List<AlertItem> _getMockCriticalAlerts() {
  return [
    AlertItem(
      id: '1',
      severity: AlertSeverity.critical,
      title: 'Bin #876 - 95% Full',
      description: '123 Oak St • Added to shift',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      actionLabel: 'View Bin',
      actionIcon: Icons.location_on,
    ),
    AlertItem(
      id: '2',
      severity: AlertSeverity.critical,
      title: 'Driver Offline',
      description: 'John Smith • No signal 15 mins',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      actionLabel: 'Call Driver',
      actionIcon: Icons.phone,
    ),
  ];
}

List<AlertItem> _getMockWarningAlerts() {
  return [
    AlertItem(
      id: '3',
      severity: AlertSeverity.warning,
      title: 'Shift Started Late',
      description: 'Omar Gabr • 22 mins behind',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      actionLabel: 'View Shift',
      actionIcon: Icons.event,
    ),
    AlertItem(
      id: '4',
      severity: AlertSeverity.warning,
      title: 'Bin #451 - 82% Full',
      description: '456 Main St • Needs collection',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      actionLabel: 'Add to Shift',
      actionIcon: Icons.add,
    ),
  ];
}

List<AlertItem> _getMockUpdateAlerts() {
  return [
    AlertItem(
      id: '5',
      severity: AlertSeverity.update,
      title: 'Shift Completed',
      description: 'Mary Johnson • Route C done',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      actionLabel: 'View Details',
      actionIcon: Icons.info_outline,
    ),
  ];
}

/// Format time ago (simple version without package)
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
