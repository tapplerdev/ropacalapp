import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';

/// Filter options for drivers list
enum DriverFilter {
  all,
  active,
  idle,
}

/// Drivers Page - Shows all drivers with filtering
class DriversPage extends HookConsumerWidget {
  const DriversPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = useState(DriverFilter.all);
    final searchInput = useState(''); // User's raw input
    final debouncedSearchQuery = useState(''); // Debounced value used for filtering
    final allDriversAsync = ref.watch(driversNotifierProvider);

    // Create TextEditingController for search field
    final searchController = useTextEditingController(text: searchInput.value);

    // Debounce search input
    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 300), () {
        debouncedSearchQuery.value = searchInput.value;
      });
      return timer.cancel;
    }, [searchInput.value]);

    // Filter drivers based on selected filter and search
    List<ActiveDriver> filterDrivers(List<ActiveDriver> drivers) {
      var filtered = drivers;

      // Apply search filter (using debounced value)
      if (debouncedSearchQuery.value.isNotEmpty) {
        filtered = filtered.where((driver) {
          final query = debouncedSearchQuery.value.toLowerCase();
          return driver.driverName.toLowerCase().contains(query) ||
              (driver.routeId?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Apply status filter
      switch (selectedFilter.value) {
        case DriverFilter.active:
          filtered = filtered
              .where((d) => d.status == ShiftStatus.active ||
                  d.status == ShiftStatus.paused ||
                  d.status == ShiftStatus.ready)
              .toList();
          break;
        case DriverFilter.idle:
          // Drivers with status 'inactive' (no active shift)
          filtered = filtered
              .where((d) => d.status == ShiftStatus.inactive ||
                  d.shiftId.isEmpty)
              .toList();
          break;
        case DriverFilter.all:
          break;
      }

      return filtered;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Drivers'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(driversNotifierProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (value) => searchInput.value = value,
                decoration: InputDecoration(
                  hintText: 'Search for a driver...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF8E8E93),
                  ),
                  suffixIcon: searchInput.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            searchInput.value = '';
                            debouncedSearchQuery.value = '';
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: selectedFilter.value == DriverFilter.all,
                    onSelected: () => selectedFilter.value = DriverFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active',
                    isSelected: selectedFilter.value == DriverFilter.active,
                    onSelected: () => selectedFilter.value = DriverFilter.active,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Idle',
                    isSelected: selectedFilter.value == DriverFilter.idle,
                    onSelected: () => selectedFilter.value = DriverFilter.idle,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Drivers list
          Expanded(
            child: allDriversAsync.when(
        data: (drivers) {
          final filteredDrivers = filterDrivers(drivers);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<String>(
                '${selectedFilter.value.name}',
              ),
              child: filteredDrivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No drivers found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedFilter.value == DriverFilter.all
                                ? 'No drivers in the system'
                                : selectedFilter.value == DriverFilter.active
                                    ? 'No active drivers at the moment'
                                    : 'All drivers are currently on shifts',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(driversNotifierProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = filteredDrivers[index];
                          return _DriverCard(driver: driver);
                        },
                      ),
                    ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load drivers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(driversNotifierProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
          ),
        ],
      ),
    );
  }
}

/// Filter chip widget - minimalist design matching bins page
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

/// Individual driver card in the list
class _DriverCard extends StatelessWidget {
  final ActiveDriver driver;

  const _DriverCard({required this.driver});

  bool get isIdle => driver.shiftId.isEmpty;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.push('/manager/drivers/${driver.driverId}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Driver name + Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/male-avatar.svg',
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            driver.driverName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isIdle
                                  ? Colors.grey.shade600
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(driver: driver, isIdle: isIdle),
                ],
              ),

              const SizedBox(height: 12),

              if (!isIdle) ...[
                // Route name with efficiency indicator
                Row(
                  children: [
                    // Efficiency dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getEfficiencyColor(driver),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        driver.routeDisplayName,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress and time elapsed
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${driver.completedBins}/${driver.totalBins} bins',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(driver.activeDuration),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                // Progress bar
                if (driver.totalBins > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: driver.completionPercentage,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getEfficiencyColor(driver),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // Last activity for idle drivers
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getLastActivityText(driver),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (driver.totalBins > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last shift: ${driver.completedBins}/${driver.totalBins} bins',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Color _getEfficiencyColor(ActiveDriver driver) {
    // Calculate efficiency based on completion percentage and time
    // Green: on track or ahead, Yellow: slightly behind, Red: significantly behind

    if (driver.totalBins == 0) return Colors.grey;

    final completionRate = driver.completionPercentage;

    if (completionRate >= 0.8) {
      return AppColors.successGreen; // On track or ahead
    } else if (completionRate >= 0.5) {
      return Colors.orange; // Slightly behind
    } else {
      return Colors.red; // Behind schedule
    }
  }

  String _getLastActivityText(ActiveDriver driver) {
    if (driver.updatedAt == null) {
      return 'No recent activity';
    }

    final lastActivity = DateTime.fromMillisecondsSinceEpoch(driver.updatedAt! * 1000);
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 1) {
      return 'Active now';
    } else if (difference.inMinutes < 60) {
      return 'Last active ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last active ${difference.inHours}h ago';
    } else {
      return 'Last active ${difference.inDays}d ago';
    }
  }
}

/// Status badge showing driver shift status
class _StatusBadge extends StatelessWidget {
  final ActiveDriver driver;
  final bool isIdle;

  const _StatusBadge({required this.driver, required this.isIdle});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo.color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            size: 14,
            color: statusInfo.color,
          ),
          const SizedBox(width: 6),
          Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo() {
    if (isIdle) {
      return _StatusInfo(
        label: 'Idle',
        color: Colors.grey.shade600,
        icon: Icons.event_available,
      );
    }

    switch (driver.status) {
      case ShiftStatus.active:
        return _StatusInfo(
          label: 'Active',
          color: AppColors.primaryGreen,
          icon: Icons.play_circle_filled,
        );
      case ShiftStatus.paused:
        return _StatusInfo(
          label: 'Paused',
          color: Colors.amber.shade700,
          icon: Icons.pause_circle_filled,
        );
      case ShiftStatus.ready:
        return _StatusInfo(
          label: 'Ready',
          color: Colors.blue.shade700,
          icon: Icons.schedule,
        );
      case ShiftStatus.inactive:
        return _StatusInfo(
          label: 'Idle',
          color: Colors.grey.shade600,
          icon: Icons.event_available,
        );
      default:
        return _StatusInfo(
          label: driver.status.toString().split('.').last,
          color: Colors.grey.shade600,
          icon: Icons.info,
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  _StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Small stat chip with icon + label
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
