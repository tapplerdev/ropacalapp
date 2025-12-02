import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// DoorDash-style notifications page
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          // Today section
          _buildSectionHeader('Today'),
          _buildNotificationCard(
            icon: Icons.route,
            iconColor: AppColors.primaryBlue,
            iconBgColor: AppColors.primaryBlue.withOpacity(0.1),
            title: 'New route assigned',
            description: 'You have 3 bins to collect on Main Street route',
            time: '10 min ago',
            isUnread: true,
          ),
          _buildNotificationCard(
            icon: Icons.delete_outline,
            iconColor: Colors.orange.shade700,
            iconBgColor: Colors.orange.shade50,
            title: 'Bin #2847 is 95% full',
            description: 'High priority pickup needed at 123 Oak Avenue',
            time: '1 hour ago',
            isUnread: true,
          ),
          _buildNotificationCard(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green.shade600,
            iconBgColor: Colors.green.shade50,
            title: 'Shift completed',
            description: 'Great job! You completed 12 bins today',
            time: '3 hours ago',
            isUnread: false,
          ),

          // Yesterday section
          _buildSectionHeader('Yesterday'),
          _buildNotificationCard(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.red.shade600,
            iconBgColor: Colors.red.shade50,
            title: 'Route delayed',
            description: 'Traffic detected on Highway 101. Adjust your route',
            time: 'Yesterday, 2:30 PM',
            isUnread: false,
          ),
          _buildNotificationCard(
            icon: Icons.schedule,
            iconColor: AppColors.primaryBlue,
            iconBgColor: AppColors.primaryBlue.withOpacity(0.1),
            title: 'Shift starting soon',
            description: 'Your shift starts in 30 minutes',
            time: 'Yesterday, 8:30 AM',
            isUnread: false,
          ),

          // This week section
          _buildSectionHeader('This Week'),
          _buildNotificationCard(
            icon: Icons.celebration_outlined,
            iconColor: Colors.purple.shade600,
            iconBgColor: Colors.purple.shade50,
            title: 'Weekly goal achieved!',
            description: 'You collected 45 bins this week. Keep it up!',
            time: 'Monday, 6:00 PM',
            isUnread: false,
          ),
          _buildNotificationCard(
            icon: Icons.update,
            iconColor: Colors.teal.shade600,
            iconBgColor: Colors.teal.shade50,
            title: 'App updated',
            description: 'New features available. Check them out!',
            time: 'Sunday, 10:00 AM',
            isUnread: false,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle notification tap
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
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
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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
