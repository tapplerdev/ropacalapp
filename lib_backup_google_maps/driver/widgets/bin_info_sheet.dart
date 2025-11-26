import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/models/bin.dart';

class BinInfoSheet extends StatelessWidget {
  final Bin bin;

  const BinInfoSheet({super.key, required this.bin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Bin #${bin.binNumber}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoRow(
            icon: Icons.location_on,
            label: 'Location',
            value: '${bin.currentStreet}\n${bin.city}, ${bin.zip}',
          ),
          const SizedBox(height: 12),
          InfoRow(
            icon: Icons.water_drop,
            label: 'Fill Level',
            value: '${bin.fillPercentage ?? 0}%',
          ),
          const SizedBox(height: 12),
          InfoRow(
            icon: Icons.info_outline,
            label: 'Status',
            value: bin.status == BinStatus.active ? 'Active' : 'Missing',
          ),
          if (bin.lastChecked != null) ...[
            const SizedBox(height: 12),
            InfoRow(
              icon: Icons.access_time,
              label: 'Last Checked',
              value: _formatDate(bin.lastChecked!),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/bin/${bin.id}');
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
