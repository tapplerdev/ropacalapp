import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/bin.dart';

class AlertsBottomSheet extends StatelessWidget {
  final List<Bin> bins;

  const AlertsBottomSheet({super.key, required this.bins});

  @override
  Widget build(BuildContext context) {
    final highFillBins = bins
        .where(
          (b) => (b.fillPercentage ?? 0) > BinConstants.criticalFillThreshold,
        )
        .toList();
    final urgentBins = bins
        .where(
          (b) => (b.fillPercentage ?? 0) > BinConstants.urgentFillThreshold,
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: AppColors.alertRed,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Alerts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (urgentBins.isNotEmpty) ...[
            AlertCard(
              icon: Icons.warning,
              iconColor: AppColors.alertRed,
              title:
                  'Urgent: ${urgentBins.length} bin${urgentBins.length > 1 ? 's' : ''} over 90% full',
              subtitle: 'Immediate attention required',
              bins: urgentBins,
            ),
            const SizedBox(height: 12),
          ],

          if (highFillBins.isNotEmpty) ...[
            AlertCard(
              icon: Icons.info,
              iconColor: AppColors.warningOrange,
              title:
                  '${highFillBins.length} bin${highFillBins.length > 1 ? 's' : ''} over 80% full',
              subtitle: 'Should be checked soon',
              bins: highFillBins,
            ),
            const SizedBox(height: 12),
          ],

          if (highFillBins.isEmpty && urgentBins.isEmpty)
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 64,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All clear!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.successGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No urgent bins at the moment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Bin> bins;

  const AlertCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.bins,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: iconColor.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          // Show list of affected bins
          showModalBottomSheet(
            context: context,
            builder: (context) => BinListBottomSheet(bins: bins, title: title),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class BinListBottomSheet extends StatelessWidget {
  final List<Bin> bins;
  final String title;

  const BinListBottomSheet({
    super.key,
    required this.bins,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: bins.length,
              itemBuilder: (context, index) {
                final bin = bins[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.alertRed.withOpacity(0.1),
                    child: Text(
                      bin.binNumber.toString(),
                      style: const TextStyle(
                        color: AppColors.alertRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(bin.currentStreet),
                  subtitle: Text('${bin.city} • ${bin.fillPercentage}% full'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    context.push('/bin/${bin.id}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
