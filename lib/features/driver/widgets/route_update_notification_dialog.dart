import 'package:flutter/material.dart';
import 'package:ropacalapp/providers/route_update_notification_provider.dart';

class RouteUpdateNotificationDialog extends StatelessWidget {
  final RouteUpdateNotification notification;
  final VoidCallback onClose;

  const RouteUpdateNotificationDialog({
    super.key,
    required this.notification,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Different colors/icons based on action type
    final bool isRemoved = notification.actionType == 'removed';
    final Color iconColor = isRemoved ? Colors.red : Colors.blue;
    final Color iconBgColor = isRemoved ? Colors.red.shade100 : Colors.blue.shade100;
    final IconData iconData = isRemoved
        ? Icons.remove_circle_outline
        : notification.actionType == 'added'
            ? Icons.add_circle_outline
            : Icons.edit_outlined;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 48,
                color: iconColor,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'Route Update',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Manager name
            Text(
              notification.managerName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Action description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.route_outlined,
                    color: iconColor,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.actionDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRemoved
                          ? 'This stop has been removed from your route. Continue to your next destination.'
                          : 'Your route has been updated. Please check your navigation for changes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // OK button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Got It',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
