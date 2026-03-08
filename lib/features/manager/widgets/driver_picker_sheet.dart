import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/shift_state.dart';

/// Bottom sheet for selecting a driver to assign a shift to.
/// Drivers with active shifts are shown but greyed out with "On Shift" badge.
class DriverPickerSheet extends HookConsumerWidget {
  const DriverPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final driversAsync = ref.watch(driversNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Driver',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => searchQuery.value = v,
                  decoration: InputDecoration(
                    hintText: 'Search drivers...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Driver list
              Expanded(
                child: driversAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error loading drivers: $e'),
                  ),
                  data: (drivers) {
                    final query = searchQuery.value.toLowerCase();
                    final filtered = drivers.where((d) {
                      if (query.isEmpty) return true;
                      return d.driverName.toLowerCase().contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No drivers found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final driver = filtered[index];
                        final isOnShift = driver.status == ShiftStatus.active ||
                            driver.status == ShiftStatus.paused;

                        return _DriverCard(
                          driver: driver,
                          isOnShift: isOnShift,
                          onTap: isOnShift
                              ? null
                              : () => Navigator.of(context).pop({
                                    'id': driver.driverId,
                                    'name': driver.driverName,
                                  }),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DriverCard extends StatelessWidget {
  final ActiveDriver driver;
  final bool isOnShift;
  final VoidCallback? onTap;

  const _DriverCard({
    required this.driver,
    required this.isOnShift,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOnShift ? Colors.grey.shade50 : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOnShift ? Colors.grey.shade200 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: isOnShift
                    ? Colors.grey.shade300
                    : AppColors.primaryGreen.withValues(alpha: 0.15),
                child: Text(
                  driver.driverName.isNotEmpty
                      ? driver.driverName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOnShift
                        ? Colors.grey.shade500
                        : AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Text(
                  driver.driverName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isOnShift ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
              ),
              // Status badge
              if (isOnShift)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'On Shift',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
