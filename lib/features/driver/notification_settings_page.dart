import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// Notification Settings Page - Manage notification preferences
class NotificationSettingsPage extends HookConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Connect to actual notification preferences provider
    // For now, using local state
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              'Manage your notification preferences',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Route Notifications Section
            _buildSectionHeader('ROUTE UPDATES'),
            const SizedBox(height: 8),
            Container(
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
                children: [
                  _NotificationToggle(
                    icon: Icons.route,
                    iconColor: Colors.blue.shade600,
                    title: 'Route Assignments',
                    subtitle: 'New route assignments & updates',
                    initialValue: true,
                    onChanged: (value) {
                      // TODO: Update preference
                    },
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.backgroundLight,
                    indent: 60,
                  ),
                  _NotificationToggle(
                    icon: Icons.update,
                    iconColor: Colors.green.shade600,
                    title: 'Route Changes',
                    subtitle: 'Route modifications & re-routing',
                    initialValue: true,
                    onChanged: (value) {
                      // TODO: Update preference
                    },
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.backgroundLight,
                    indent: 60,
                  ),
                  _NotificationToggle(
                    icon: Icons.move_down,
                    iconColor: Colors.orange.shade600,
                    title: 'Move Requests',
                    subtitle: 'Manager requests to move bins',
                    initialValue: true,
                    onChanged: (value) {
                      // TODO: Update preference
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bin Alerts Section
            _buildSectionHeader('BIN ALERTS'),
            const SizedBox(height: 8),
            Container(
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
                children: [
                  _NotificationToggle(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.red.shade600,
                    title: 'High Fill Alerts',
                    subtitle: 'Bins exceeding 80% capacity',
                    initialValue: true,
                    onChanged: (value) {
                      // TODO: Update preference
                    },
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.backgroundLight,
                    indent: 60,
                  ),
                  _NotificationToggle(
                    icon: Icons.priority_high,
                    iconColor: Colors.purple.shade600,
                    title: 'Priority Bins',
                    subtitle: 'Urgent collection requests',
                    initialValue: true,
                    onChanged: (value) {
                      // TODO: Update preference
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // General Notifications Section
            _buildSectionHeader('GENERAL'),
            const SizedBox(height: 8),
            Container(
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
                children: [
                  _NotificationToggle(
                    icon: Icons.message_outlined,
                    iconColor: Colors.teal.shade600,
                    title: 'Manager Messages',
                    subtitle: 'Messages from management',
                    initialValue: true,
                    onChanged: (value) {
                      // TODO: Update preference
                    },
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.backgroundLight,
                    indent: 60,
                  ),
                  _NotificationToggle(
                    icon: Icons.notifications_active,
                    iconColor: Colors.indigo.shade600,
                    title: 'Sound',
                    subtitle: 'Play sound for notifications',
                    initialValue: true,
                    onChanged: (value) {
                      // TODO: Update preference
                    },
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.backgroundLight,
                    indent: 60,
                  ),
                  _NotificationToggle(
                    icon: Icons.vibration,
                    iconColor: Colors.pink.shade600,
                    title: 'Vibration',
                    subtitle: 'Vibrate for notifications',
                    initialValue: true,
                    onChanged: (value) {
                      // TODO: Update preference
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Notification toggle widget
class _NotificationToggle extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon,
              color: widget.iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _value,
            onChanged: (value) {
              setState(() {
                _value = value;
              });
              widget.onChanged(value);
            },
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}
