import 'package:flutter/material.dart';
import 'package:ropacalapp/models/move_request.dart';

class MoveRequestNotificationDialog extends StatelessWidget {
  final MoveRequest moveRequest;
  final VoidCallback onClose;

  const MoveRequestNotificationDialog({
    super.key,
    required this.moveRequest,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: Colors.orange.shade700,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'New Move Request Assigned',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Bin number
            if (moveRequest.binNumber != null)
              Text(
                'Bin #${moveRequest.binNumber}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
              ),

            const SizedBox(height: 24),

            // Pickup location
            _LocationInfo(
              icon: Icons.location_on_outlined,
              iconColor: Colors.blue,
              label: 'Pickup Location',
              address: moveRequest.pickupAddress,
            ),

            const SizedBox(height: 16),

            // Dropoff location
            _LocationInfo(
              icon: Icons.place_outlined,
              iconColor: Colors.green,
              label: 'Drop-off Location',
              address: moveRequest.dropoffAddress,
            ),

            const SizedBox(height: 24),

            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This stop has been added to your route. Navigate to pickup location to begin.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
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
                  backgroundColor: Colors.orange.shade600,
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

class _LocationInfo extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  const _LocationInfo({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
