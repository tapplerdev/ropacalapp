import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/bin_helpers.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/potential_locations_list_provider.dart';
import 'package:ropacalapp/providers/converted_locations_list_provider.dart';
import 'package:ropacalapp/providers/focused_potential_location_provider.dart';
import 'package:ropacalapp/providers/move_requests_list_provider.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/models/potential_location.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/features/manager/widgets/convert_location_dialog.dart';
import 'package:ropacalapp/features/manager/widgets/move_request_bottom_sheet.dart';
import 'package:ropacalapp/features/manager/widgets/create_move_request_page.dart';

/// Manager Operations Tab - Central hub for operational data
/// Contains: Drivers, Bins, Potential Locations, Move Requests
class ManagerOperationsTab extends HookConsumerWidget {
  const ManagerOperationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 4);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Operations',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: tabController,
          indicatorColor: AppColors.primaryGreen,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Drivers'),
            Tab(text: 'Bins'),
            Tab(text: 'Locations'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          _DriversTab(),
          _BinsTab(),
          _LocationsTab(),
          _RequestsTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// DRIVERS TAB
// =============================================================================

enum _DriverFilter { all, active, ready, inactive }

class _DriversTab extends HookConsumerWidget {
  const _DriversTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversNotifierProvider);
    final selectedFilter = useState(_DriverFilter.all);

    bool _matchesFilter(ActiveDriver driver, _DriverFilter filter) {
      switch (filter) {
        case _DriverFilter.all:
          return true;
        case _DriverFilter.active:
          return driver.status == ShiftStatus.active ||
              driver.status == ShiftStatus.paused;
        case _DriverFilter.ready:
          return driver.status == ShiftStatus.ready;
        case _DriverFilter.inactive:
          return driver.status == ShiftStatus.inactive ||
              driver.status == ShiftStatus.ended ||
              driver.status == ShiftStatus.cancelled;
      }
    }

    return driversAsync.when(
      data: (drivers) {
        if (drivers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: 'No Drivers',
            subtitle: 'Driver list will appear here',
          );
        }

        final filtered = drivers
            .where((d) => _matchesFilter(d, selectedFilter.value))
            .toList();

        // Counts for filter badges
        final activeCount = drivers
            .where((d) =>
                d.status == ShiftStatus.active ||
                d.status == ShiftStatus.paused)
            .length;
        final readyCount =
            drivers.where((d) => d.status == ShiftStatus.ready).length;
        final inactiveCount = drivers
            .where((d) =>
                d.status == ShiftStatus.inactive ||
                d.status == ShiftStatus.ended ||
                d.status == ShiftStatus.cancelled)
            .length;

        return Column(
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (${drivers.length})',
                    isSelected: selectedFilter.value == _DriverFilter.all,
                    onTap: () => selectedFilter.value = _DriverFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active ($activeCount)',
                    isSelected: selectedFilter.value == _DriverFilter.active,
                    onTap: () => selectedFilter.value = _DriverFilter.active,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Ready ($readyCount)',
                    isSelected: selectedFilter.value == _DriverFilter.ready,
                    onTap: () => selectedFilter.value = _DriverFilter.ready,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Inactive ($inactiveCount)',
                    isSelected: selectedFilter.value == _DriverFilter.inactive,
                    onTap: () => selectedFilter.value = _DriverFilter.inactive,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Driver list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No drivers match this filter',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryGreen,
                      onRefresh: () async {
                        await ref
                            .read(driversNotifierProvider.notifier)
                            .refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final driver = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DriverCard(driver: driver),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(driversNotifierProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final ActiveDriver driver;

  const _DriverCard({required this.driver});

  Color _statusColor(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.active:
        return AppColors.primaryGreen;
      case ShiftStatus.paused:
        return AppColors.warningOrange;
      case ShiftStatus.ready:
        return AppColors.brandBlueAccent;
      case ShiftStatus.ended:
      case ShiftStatus.cancelled:
      case ShiftStatus.inactive:
        return Colors.grey;
    }
  }

  String _statusLabel(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.active:
        return 'Active';
      case ShiftStatus.paused:
        return 'Paused';
      case ShiftStatus.ready:
        return 'Ready';
      case ShiftStatus.ended:
        return 'Ended';
      case ShiftStatus.cancelled:
        return 'Cancelled';
      case ShiftStatus.inactive:
        return 'Inactive';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(driver.status);
    final statusLabel = _statusLabel(driver.status);
    final progress = driver.totalBins > 0
        ? driver.completedBins / driver.totalBins
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/manager/drivers/${driver.driverId}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.driverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (driver.shiftId.isNotEmpty)
                          Text(
                            'Shift: ${driver.shiftId.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              // Progress bar for active drivers
              if (driver.status == ShiftStatus.active &&
                  driver.totalBins > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      '${driver.completedBins}/${driver.totalBins} bins',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
              // Chevron hint for tappability
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// BINS TAB
// =============================================================================

enum _BinStatusFilter2 { all, active, inStorage, missing, pendingMove }

enum _BinSortOption {
  defaultSort,
  fillHighToLow,
  fillLowToHigh,
  lastCheckedOldest,
  binNumber,
}

const _sortLabels = {
  _BinSortOption.defaultSort: 'Default',
  _BinSortOption.fillHighToLow: 'Fill Level (High → Low)',
  _BinSortOption.fillLowToHigh: 'Fill Level (Low → High)',
  _BinSortOption.lastCheckedOldest: 'Last Checked (Oldest)',
  _BinSortOption.binNumber: 'Bin Number',
};

const _sortIcons = {
  _BinSortOption.defaultSort: Icons.sort,
  _BinSortOption.fillHighToLow: Icons.arrow_downward,
  _BinSortOption.fillLowToHigh: Icons.arrow_upward,
  _BinSortOption.lastCheckedOldest: Icons.schedule,
  _BinSortOption.binNumber: Icons.tag,
};

class _BinsTab extends HookConsumerWidget {
  const _BinsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binsState = ref.watch(binsListProvider);
    final searchInput = useState('');
    final debouncedSearch = useState('');
    final selectedStatus = useState(_BinStatusFilter2.all);
    final selectedSort = useState(_BinSortOption.defaultSort);

    // Debounce search input
    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 300), () {
        debouncedSearch.value = searchInput.value;
      });
      return timer.cancel;
    }, [searchInput.value]);

    List<Bin> filterAndSortBins(List<Bin> bins) {
      var filtered = bins.toList();

      // Search filter
      if (debouncedSearch.value.isNotEmpty) {
        final q = debouncedSearch.value.toLowerCase();
        filtered = filtered
            .where((bin) =>
                bin.binNumber.toString().contains(q) ||
                bin.address.toLowerCase().contains(q) ||
                bin.city.toLowerCase().contains(q))
            .toList();
      }

      // Status filter
      switch (selectedStatus.value) {
        case _BinStatusFilter2.active:
          filtered = filtered
              .where((bin) => bin.status == BinStatus.active)
              .toList();
        case _BinStatusFilter2.inStorage:
          filtered = filtered
              .where((bin) => bin.status == BinStatus.inStorage)
              .toList();
        case _BinStatusFilter2.missing:
          filtered = filtered
              .where((bin) => bin.status == BinStatus.missing)
              .toList();
        case _BinStatusFilter2.pendingMove:
          filtered = filtered
              .where((bin) => bin.status == BinStatus.pendingMove)
              .toList();
        case _BinStatusFilter2.all:
          break;
      }

      // Sort
      switch (selectedSort.value) {
        case _BinSortOption.fillHighToLow:
          filtered.sort((a, b) =>
              (b.fillPercentage ?? 0).compareTo(a.fillPercentage ?? 0));
        case _BinSortOption.fillLowToHigh:
          filtered.sort((a, b) =>
              (a.fillPercentage ?? 0).compareTo(b.fillPercentage ?? 0));
        case _BinSortOption.lastCheckedOldest:
          filtered.sort((a, b) {
            if (a.lastChecked == null && b.lastChecked == null) return 0;
            if (a.lastChecked == null) return -1; // null = never checked = oldest
            if (b.lastChecked == null) return 1;
            return a.lastChecked!.compareTo(b.lastChecked!);
          });
        case _BinSortOption.binNumber:
          filtered.sort((a, b) => a.binNumber.compareTo(b.binNumber));
        case _BinSortOption.defaultSort:
          break;
      }

      return filtered;
    }

    // Count bins per status for badges
    Map<_BinStatusFilter2, int> getStatusCounts(List<Bin> bins) {
      final counts = <_BinStatusFilter2, int>{};
      counts[_BinStatusFilter2.all] = bins.length;
      counts[_BinStatusFilter2.active] =
          bins.where((b) => b.status == BinStatus.active).length;
      counts[_BinStatusFilter2.inStorage] =
          bins.where((b) => b.status == BinStatus.inStorage).length;
      counts[_BinStatusFilter2.missing] =
          bins.where((b) => b.status == BinStatus.missing).length;
      counts[_BinStatusFilter2.pendingMove] =
          bins.where((b) => b.status == BinStatus.pendingMove).length;
      return counts;
    }

    void showSortPicker() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.sort, color: AppColors.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _BinSortOption.values.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final option = _BinSortOption.values[index];
                  final isSelected = selectedSort.value == option;
                  return Material(
                    color: isSelected
                        ? AppColors.primaryGreen.withValues(alpha: 0.06)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        selectedSort.value = option;
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryGreen
                                        .withValues(alpha: 0.12)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _sortIcons[option]!,
                                size: 18,
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _sortLabels[option]!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle,
                                  color: AppColors.primaryGreen, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => searchInput.value = value,
              decoration: InputDecoration(
                hintText: 'Search by bin #, street, or city',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                suffixIcon: searchInput.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchInput.value = '';
                          debouncedSearch.value = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),

        // Status filter chips
        binsState.whenOrNull(
              data: (bins) {
                final counts = getStatusCounts(bins);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatusChip(
                        label: 'All',
                        count: counts[_BinStatusFilter2.all] ?? 0,
                        isSelected:
                            selectedStatus.value == _BinStatusFilter2.all,
                        onTap: () =>
                            selectedStatus.value = _BinStatusFilter2.all,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Active',
                        count: counts[_BinStatusFilter2.active] ?? 0,
                        isSelected:
                            selectedStatus.value == _BinStatusFilter2.active,
                        onTap: () =>
                            selectedStatus.value = _BinStatusFilter2.active,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'In Storage',
                        count: counts[_BinStatusFilter2.inStorage] ?? 0,
                        isSelected:
                            selectedStatus.value == _BinStatusFilter2.inStorage,
                        onTap: () =>
                            selectedStatus.value = _BinStatusFilter2.inStorage,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Missing',
                        count: counts[_BinStatusFilter2.missing] ?? 0,
                        isSelected:
                            selectedStatus.value == _BinStatusFilter2.missing,
                        onTap: () =>
                            selectedStatus.value = _BinStatusFilter2.missing,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Pending Move',
                        count: counts[_BinStatusFilter2.pendingMove] ?? 0,
                        isSelected: selectedStatus.value ==
                            _BinStatusFilter2.pendingMove,
                        onTap: () => selectedStatus.value =
                            _BinStatusFilter2.pendingMove,
                      ),
                    ],
                  ),
                );
              },
            ) ??
            const SizedBox.shrink(),

        // Sort row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: InkWell(
            onTap: showSortPicker,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.sort, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'Sort: ${_sortLabels[selectedSort.value]}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selectedSort.value == _BinSortOption.defaultSort
                          ? Colors.grey[500]
                          : AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: selectedSort.value == _BinSortOption.defaultSort
                        ? Colors.grey[500]
                        : AppColors.primaryGreen,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bins list
        Expanded(
          child: binsState.when(
            data: (bins) {
              final filtered = filterAndSortBins(bins);

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No bins found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try adjusting your filters or search',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primaryGreen,
                onRefresh: () async {
                  ref.invalidate(binsListProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _BinListItem(bin: filtered[index]);
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading bins: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(binsListProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BinListItem extends StatelessWidget {
  final Bin bin;

  const _BinListItem({required this.bin});

  @override
  Widget build(BuildContext context) {
    final fillPercentage = bin.fillPercentage ?? 0;
    final fillColor = BinHelpers.getFillColor(fillPercentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/bin/${bin.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Bin number circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: fillColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    bin.binNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bin details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bin.address,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bin.city}, ${bin.zip}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Fill percentage badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: fillColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.water_drop,
                                  size: 14, color: fillColor),
                              const SizedBox(width: 4),
                              Text(
                                '$fillPercentage%',
                                style: TextStyle(
                                  color: fillColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        if (bin.status != BinStatus.active) ...[
                          const SizedBox(width: 8),
                          _buildStatusBadge(bin.status),
                        ],
                      ],
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

  Widget _buildStatusBadge(BinStatus status) {
    final (String label, Color color) = switch (status) {
      BinStatus.inStorage => ('In Storage', Colors.blue),
      BinStatus.missing => ('Missing', Colors.red),
      BinStatus.pendingMove => ('Pending Move', Colors.orange),
      BinStatus.retired => ('Retired', Colors.grey),
      _ => ('Active', AppColors.successGreen),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.shade200),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// LOCATIONS TAB (Potential Locations with Pending / History sub-tabs)
// =============================================================================

enum _PendingLocationFilter { all, today, thisWeek, thisMonth, custom }

enum _HistoryLocationFilter { all, viaShift, manual, thisWeek, thisMonth, custom }

class _LocationsTab extends ConsumerStatefulWidget {
  const _LocationsTab();

  @override
  ConsumerState<_LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends ConsumerState<_LocationsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _PendingLocationFilter _pendingFilter = _PendingLocationFilter.all;
  _HistoryLocationFilter _historyFilter = _HistoryLocationFilter.all;
  DateTimeRange? _pendingCustomRange;
  DateTimeRange? _historyCustomRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(potentialLocationsListNotifierProvider);
    final convertedAsync = ref.watch(convertedLocationsListNotifierProvider);

    return Stack(
      children: [
        Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search address, city, or ZIP...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey.shade500, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: Colors.grey.shade600, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
          ),
        ),

        // Pending / History sub-tabs
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: AppColors.primaryGreen,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pending'),
                    const SizedBox(width: 6),
                    locationsAsync.whenOrNull(
                          data: (locs) {
                            final count = locs.length;
                            if (count == 0) return null;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count.toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ) ??
                        const SizedBox.shrink(),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('History'),
                    const SizedBox(width: 6),
                    convertedAsync.whenOrNull(
                          data: (locs) {
                            final count = locs.length;
                            if (count == 0) return null;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count.toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ) ??
                        const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Pending tab
              locationsAsync.when(
                data: (locations) {
                  // Apply search
                  final searched = _searchQuery.isEmpty
                      ? locations
                      : locations.where((loc) {
                          return loc.street
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              loc.city
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              loc.zip.toLowerCase().contains(_searchQuery);
                        }).toList();

                  // Counts for filter chips
                  final now = DateTime.now();
                  final todayStart = DateTime(now.year, now.month, now.day);
                  final weekAgo = now.subtract(const Duration(days: 7));
                  final monthAgo = now.subtract(const Duration(days: 30));
                  final todayCount = searched.where((l) {
                    final d = DateTime.tryParse(l.createdAtIso);
                    return d != null && d.isAfter(todayStart);
                  }).length;
                  final weekCount = searched.where((l) {
                    final d = DateTime.tryParse(l.createdAtIso);
                    return d != null && d.isAfter(weekAgo);
                  }).length;
                  final monthCount = searched.where((l) {
                    final d = DateTime.tryParse(l.createdAtIso);
                    return d != null && d.isAfter(monthAgo);
                  }).length;

                  // Apply filter
                  final filtered = searched.where((l) {
                    switch (_pendingFilter) {
                      case _PendingLocationFilter.all:
                        return true;
                      case _PendingLocationFilter.today:
                        final d = DateTime.tryParse(l.createdAtIso);
                        return d != null && d.isAfter(todayStart);
                      case _PendingLocationFilter.thisWeek:
                        final d = DateTime.tryParse(l.createdAtIso);
                        return d != null && d.isAfter(weekAgo);
                      case _PendingLocationFilter.thisMonth:
                        final d = DateTime.tryParse(l.createdAtIso);
                        return d != null && d.isAfter(monthAgo);
                      case _PendingLocationFilter.custom:
                        if (_pendingCustomRange == null) return true;
                        return _isInDateRange(
                            l.createdAtIso, _pendingCustomRange!);
                    }
                  }).toList();

                  return Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All (${searched.length})',
                              isSelected: _pendingFilter ==
                                  _PendingLocationFilter.all,
                              onTap: () => setState(() =>
                                  _pendingFilter =
                                      _PendingLocationFilter.all),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Today ($todayCount)',
                              isSelected: _pendingFilter ==
                                  _PendingLocationFilter.today,
                              onTap: () => setState(() =>
                                  _pendingFilter =
                                      _PendingLocationFilter.today),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'This Week ($weekCount)',
                              isSelected: _pendingFilter ==
                                  _PendingLocationFilter.thisWeek,
                              onTap: () => setState(() =>
                                  _pendingFilter =
                                      _PendingLocationFilter.thisWeek),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'This Month ($monthCount)',
                              isSelected: _pendingFilter ==
                                  _PendingLocationFilter.thisMonth,
                              onTap: () => setState(() =>
                                  _pendingFilter =
                                      _PendingLocationFilter.thisMonth),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: _pendingFilter ==
                                          _PendingLocationFilter.custom &&
                                      _pendingCustomRange != null
                                  ? _formatDateRange(_pendingCustomRange!)
                                  : 'Custom...',
                              isSelected: _pendingFilter ==
                                  _PendingLocationFilter.custom,
                              onTap: () => _showCustomDateRangePicker(
                                  isPending: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _buildLocationsList(filtered,
                            isPending: true),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGreen),
                ),
                error: (error, stack) => _buildLocationsError(
                  onRetry: () => ref
                      .read(potentialLocationsListNotifierProvider.notifier)
                      .refresh(),
                ),
              ),
              // History tab
              convertedAsync.when(
                data: (locations) {
                  // Apply search
                  final searched = _searchQuery.isEmpty
                      ? locations
                      : locations.where((loc) {
                          return loc.street
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              loc.city
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              loc.zip.toLowerCase().contains(_searchQuery);
                        }).toList();

                  // Counts for filter chips
                  final now = DateTime.now();
                  final weekAgo = now.subtract(const Duration(days: 7));
                  final monthAgo = now.subtract(const Duration(days: 30));
                  final viaShiftCount = searched
                      .where((l) => l.convertedViaShiftId != null)
                      .length;
                  final manualConvCount = searched
                      .where((l) => l.convertedViaShiftId == null)
                      .length;
                  final weekCount = searched.where((l) {
                    final d = DateTime.tryParse(l.convertedAtIso ?? '');
                    return d != null && d.isAfter(weekAgo);
                  }).length;
                  final monthCount = searched.where((l) {
                    final d = DateTime.tryParse(l.convertedAtIso ?? '');
                    return d != null && d.isAfter(monthAgo);
                  }).length;

                  // Apply filter
                  final filtered = searched.where((l) {
                    switch (_historyFilter) {
                      case _HistoryLocationFilter.all:
                        return true;
                      case _HistoryLocationFilter.viaShift:
                        return l.convertedViaShiftId != null;
                      case _HistoryLocationFilter.manual:
                        return l.convertedViaShiftId == null;
                      case _HistoryLocationFilter.thisWeek:
                        final d =
                            DateTime.tryParse(l.convertedAtIso ?? '');
                        return d != null && d.isAfter(weekAgo);
                      case _HistoryLocationFilter.thisMonth:
                        final d =
                            DateTime.tryParse(l.convertedAtIso ?? '');
                        return d != null && d.isAfter(monthAgo);
                      case _HistoryLocationFilter.custom:
                        if (_historyCustomRange == null) return true;
                        return _isInDateRange(
                            l.convertedAtIso, _historyCustomRange!);
                    }
                  }).toList();

                  return Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All (${searched.length})',
                              isSelected: _historyFilter ==
                                  _HistoryLocationFilter.all,
                              onTap: () => setState(() =>
                                  _historyFilter =
                                      _HistoryLocationFilter.all),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Via Shift ($viaShiftCount)',
                              isSelected: _historyFilter ==
                                  _HistoryLocationFilter.viaShift,
                              onTap: () => setState(() =>
                                  _historyFilter =
                                      _HistoryLocationFilter.viaShift),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Manual ($manualConvCount)',
                              isSelected: _historyFilter ==
                                  _HistoryLocationFilter.manual,
                              onTap: () => setState(() =>
                                  _historyFilter =
                                      _HistoryLocationFilter.manual),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'This Week ($weekCount)',
                              isSelected: _historyFilter ==
                                  _HistoryLocationFilter.thisWeek,
                              onTap: () => setState(() =>
                                  _historyFilter =
                                      _HistoryLocationFilter.thisWeek),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'This Month ($monthCount)',
                              isSelected: _historyFilter ==
                                  _HistoryLocationFilter.thisMonth,
                              onTap: () => setState(() =>
                                  _historyFilter =
                                      _HistoryLocationFilter.thisMonth),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: _historyFilter ==
                                          _HistoryLocationFilter.custom &&
                                      _historyCustomRange != null
                                  ? _formatDateRange(_historyCustomRange!)
                                  : 'Custom...',
                              isSelected: _historyFilter ==
                                  _HistoryLocationFilter.custom,
                              onTap: () => _showCustomDateRangePicker(
                                  isPending: false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _buildLocationsList(filtered,
                            isPending: false),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGreen),
                ),
                error: (error, stack) => _buildLocationsError(
                  onRetry: () => ref
                      .read(convertedLocationsListNotifierProvider.notifier)
                      .refresh(),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'add_location',
            backgroundColor: AppColors.primaryGreen,
            onPressed: () async {
              await context.push('/location-picker');
              ref
                  .read(potentialLocationsListNotifierProvider.notifier)
                  .refresh();
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationsError({required VoidCallback onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error loading locations'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsList(List<PotentialLocation> locations,
      {required bool isPending}) {
    if (locations.isEmpty) {
      final hasActiveFilter = isPending
          ? _pendingFilter != _PendingLocationFilter.all
          : _historyFilter != _HistoryLocationFilter.all;
      return _buildEmptyState(
        icon: hasActiveFilter
            ? Icons.filter_list_off
            : (isPending ? Icons.location_on_outlined : Icons.history),
        title: hasActiveFilter
            ? 'No matches'
            : (isPending ? 'No Pending Locations' : 'No History Yet'),
        subtitle: hasActiveFilter
            ? 'Try a different filter'
            : (isPending
                ? 'New location suggestions from\ndrivers will appear here'
                : 'Approved locations will\nappear here'),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () async {
        if (isPending) {
          ref
              .read(potentialLocationsListNotifierProvider.notifier)
              .refresh();
        } else {
          ref
              .read(convertedLocationsListNotifierProvider.notifier)
              .refresh();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          return _LocationCard(
            location: locations[index],
            isPending: isPending,
            onTap: () => _showLocationDetail(locations[index], isPending),
            onLocateOnMap: () => _locateOnMap(locations[index]),
          );
        },
      ),
    );
  }

  Future<void> _showCustomDateRangePicker({
    required bool isPending,
  }) async {
    final now = DateTime.now();
    final initial = isPending ? _pendingCustomRange : _historyCustomRange;

    final picked = await Navigator.of(context).push<DateTimeRange>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                    surfaceContainerHighest: Colors.grey.shade50,
                  ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              scaffoldBackgroundColor: Colors.white,
              datePickerTheme: DatePickerThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                headerBackgroundColor: Colors.white,
                headerForegroundColor: Colors.black87,
                rangePickerBackgroundColor: Colors.white,
                rangePickerSurfaceTintColor: Colors.transparent,
                rangeSelectionBackgroundColor:
                    AppColors.primaryGreen.withValues(alpha: 0.15),
                dayOverlayColor: WidgetStatePropertyAll(
                  AppColors.primaryGreen.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: DateRangePickerDialog(
              firstDate: DateTime(2024),
              lastDate: now,
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              initialDateRange: initial ??
                  DateTimeRange(
                    start: now.subtract(const Duration(days: 30)),
                    end: now,
                  ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        fullscreenDialog: true,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isPending) {
          _pendingCustomRange = picked;
          _pendingFilter = _PendingLocationFilter.custom;
        } else {
          _historyCustomRange = picked;
          _historyFilter = _HistoryLocationFilter.custom;
        }
      });
    }
  }

  String _formatDateRange(DateTimeRange range) {
    final f = DateFormat('MMM d');
    if (range.start.year != range.end.year) {
      final fFull = DateFormat('MMM d, yy');
      return '${fFull.format(range.start)} - ${fFull.format(range.end)}';
    }
    return '${f.format(range.start)} - ${f.format(range.end)}';
  }

  bool _isInDateRange(String? isoDate, DateTimeRange range) {
    if (isoDate == null) return false;
    final d = DateTime.tryParse(isoDate);
    if (d == null) return false;
    final endOfDay = DateTime(
        range.end.year, range.end.month, range.end.day, 23, 59, 59);
    return !d.isBefore(range.start) && !d.isAfter(endOfDay);
  }

  void _showLocationDetail(PotentialLocation location, bool isPending) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConvertLocationDialog(
        location: location,
        isPending: isPending,
      ),
    );
    // Only refresh if a conversion actually happened
    if (result == true) {
      ref.read(convertedLocationsListNotifierProvider.notifier).refresh();
    }
  }

  void _locateOnMap(PotentialLocation location) {
    ref
        .read(focusedPotentialLocationProvider.notifier)
        .focusLocation(location.id);
    // The map page watches this provider and will auto-focus.
    // The scaffold will auto-switch to map tab via the provider effect.
  }
}

class _LocationCard extends StatelessWidget {
  final PotentialLocation location;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onLocateOnMap;

  const _LocationCard({
    required this.location,
    required this.isPending,
    required this.onTap,
    required this.onLocateOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppColors.primaryGreen.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppColors.primaryGreen.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: isPending
                            ? AppColors.primaryGreen
                            : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.street,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${location.city}, ${location.zip}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else ...[
                      if (location.convertedViaShiftId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'Via Shift',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purple.shade200,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'Manual',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      if (location.binNumber != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 12, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Bin ${location.binNumber}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Requester and date
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      location.requestedByName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(location.createdAtIso),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                // Notes
                if (location.notes != null &&
                    location.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note_alt_outlined,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location.notes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Conversion details for history items
                if (!isPending && location.binNumber != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade100.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check_circle,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Converted to Bin #${location.binNumber}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade900,
                                ),
                              ),
                              if (location.convertedByDriverName != null &&
                                  location.convertedViaShiftId != null)
                                Text(
                                  'By ${location.convertedByDriverName} (via shift)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                  ),
                                )
                              else if (location.convertedByManagerName != null)
                                Text(
                                  'By ${location.convertedByManagerName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              if (location.convertedAtIso != null)
                                Text(
                                  'Approved ${_formatDate(location.convertedAtIso!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Locate on Map button
                if (location.latitude != null &&
                    location.longitude != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onLocateOnMap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text(
                        'Locate on Map',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  static String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

// =============================================================================
// REQUESTS TAB (Move Requests)
// =============================================================================

enum _MoveRequestFilter { all, pending, assigned, inProgress, completed, cancelled }
enum _MoveTypeFilter { all, store, relocation, redeployment }

enum _RequestSortOption {
  newestFirst,
  oldestFirst,
  scheduledSoonest,
  scheduledLatest,
  mostOverdue,
}

const _requestSortLabels = {
  _RequestSortOption.newestFirst: 'Newest First',
  _RequestSortOption.oldestFirst: 'Oldest First',
  _RequestSortOption.scheduledSoonest: 'Scheduled (Soonest)',
  _RequestSortOption.scheduledLatest: 'Scheduled (Latest)',
  _RequestSortOption.mostOverdue: 'Most Overdue',
};

const _requestSortIcons = {
  _RequestSortOption.newestFirst: Icons.arrow_downward,
  _RequestSortOption.oldestFirst: Icons.arrow_upward,
  _RequestSortOption.scheduledSoonest: Icons.event_available,
  _RequestSortOption.scheduledLatest: Icons.event,
  _RequestSortOption.mostOverdue: Icons.warning_amber,
};

class _RequestsTab extends ConsumerStatefulWidget {
  const _RequestsTab();

  @override
  ConsumerState<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<_RequestsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _MoveRequestFilter _statusFilter = _MoveRequestFilter.all;
  _MoveTypeFilter _typeFilter = _MoveTypeFilter.all;
  _RequestSortOption _sortOption = _RequestSortOption.newestFirst;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Compute urgency from scheduled_date unix timestamp (matches dashboard logic)
  static String _computeUrgency(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'pending';
    if (status == 'completed' || status == 'cancelled') return 'resolved';

    final scheduledDate = data['scheduled_date'] as int?;
    if (scheduledDate == null) return 'scheduled';

    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    final daysUntil = (scheduledDate - now) / 86400;

    if (scheduledDate < now) return 'overdue';
    if (daysUntil < 1) return 'urgent';
    if (daysUntil < 3) return 'soon';
    return 'scheduled';
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> requests) {
    var filtered = requests;

    // Status filter
    if (_statusFilter != _MoveRequestFilter.all) {
      final statusStr = switch (_statusFilter) {
        _MoveRequestFilter.pending => 'pending',
        _MoveRequestFilter.assigned => 'assigned',
        _MoveRequestFilter.inProgress => 'in_progress',
        _MoveRequestFilter.completed => 'completed',
        _MoveRequestFilter.cancelled => 'cancelled',
        _MoveRequestFilter.all => '',
      };
      filtered = filtered.where((r) => r['status'] == statusStr).toList();
    }

    // Move type filter
    if (_typeFilter != _MoveTypeFilter.all) {
      final typeStr = switch (_typeFilter) {
        _MoveTypeFilter.store => 'store',
        _MoveTypeFilter.relocation => 'relocation',
        _MoveTypeFilter.redeployment => 'redeployment',
        _MoveTypeFilter.all => '',
      };
      filtered = filtered.where((r) => r['move_type'] == typeStr).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final binNumber = (r['bin_number'] as int?)?.toString() ?? '';
        final street = (r['current_street'] as String? ?? '').toLowerCase();
        final city = (r['city'] as String? ?? '').toLowerCase();
        final zip = (r['zip'] as String? ?? '').toLowerCase();
        final driverName = (r['driver_name'] as String? ?? '').toLowerCase();
        final assignedDriverName = (r['assigned_driver_name'] as String? ?? '').toLowerCase();
        return binNumber.contains(_searchQuery) ||
            street.contains(_searchQuery) ||
            city.contains(_searchQuery) ||
            zip.contains(_searchQuery) ||
            driverName.contains(_searchQuery) ||
            assignedDriverName.contains(_searchQuery);
      }).toList();
    }

    // Sort
    switch (_sortOption) {
      case _RequestSortOption.newestFirst:
        filtered.sort((a, b) {
          final aDate = a['created_at_iso'] as String? ?? '';
          final bDate = b['created_at_iso'] as String? ?? '';
          return bDate.compareTo(aDate);
        });
      case _RequestSortOption.oldestFirst:
        filtered.sort((a, b) {
          final aDate = a['created_at_iso'] as String? ?? '';
          final bDate = b['created_at_iso'] as String? ?? '';
          return aDate.compareTo(bDate);
        });
      case _RequestSortOption.scheduledSoonest:
        filtered.sort((a, b) {
          final aDate = a['scheduled_date'] as int? ?? 0;
          final bDate = b['scheduled_date'] as int? ?? 0;
          return aDate.compareTo(bDate);
        });
      case _RequestSortOption.scheduledLatest:
        filtered.sort((a, b) {
          final aDate = a['scheduled_date'] as int? ?? 0;
          final bDate = b['scheduled_date'] as int? ?? 0;
          return bDate.compareTo(aDate);
        });
      case _RequestSortOption.mostOverdue:
        filtered.sort((a, b) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final aScheduled = a['scheduled_date'] as int? ?? now;
          final bScheduled = b['scheduled_date'] as int? ?? now;
          // More overdue (lower scheduled_date) comes first
          return aScheduled.compareTo(bScheduled);
        });
    }

    return filtered;
  }

  int _countForStatus(List<Map<String, dynamic>> all, _MoveRequestFilter filter) {
    if (filter == _MoveRequestFilter.all) return all.length;
    final statusStr = switch (filter) {
      _MoveRequestFilter.pending => 'pending',
      _MoveRequestFilter.assigned => 'assigned',
      _MoveRequestFilter.inProgress => 'in_progress',
      _MoveRequestFilter.completed => 'completed',
      _MoveRequestFilter.cancelled => 'cancelled',
      _MoveRequestFilter.all => '',
    };
    return all.where((r) => r['status'] == statusStr).length;
  }

  int _countForType(List<Map<String, dynamic>> all, _MoveTypeFilter filter) {
    if (filter == _MoveTypeFilter.all) return all.length;
    final typeStr = switch (filter) {
      _MoveTypeFilter.store => 'store',
      _MoveTypeFilter.relocation => 'relocation',
      _MoveTypeFilter.redeployment => 'redeployment',
      _MoveTypeFilter.all => '',
    };
    return all.where((r) => r['move_type'] == typeStr).length;
  }

  void _showMoveRequestDetail(
    Map<String, dynamic> data,
    String computedUrgency,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoveRequestBottomSheet(
        data: data,
        computedUrgency: computedUrgency,
      ),
    );

    if (result == true) {
      ref.read(moveRequestsListNotifierProvider.notifier).refresh();
    }
  }

  void _openCreateMoveRequest() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CreateMoveRequestPage(),
      ),
    );
    if (result == true) {
      ref.read(moveRequestsListNotifierProvider.notifier).refresh();
    }
  }

  void _showRequestSortPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.sort, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _RequestSortOption.values.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, indent: 56, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final option = _RequestSortOption.values[index];
                final isSelected = _sortOption == option;
                return Material(
                  color: isSelected
                      ? AppColors.primaryGreen.withValues(alpha: 0.06)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _sortOption = option);
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                      .withValues(alpha: 0.12)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _requestSortIcons[option]!,
                              size: 18,
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _requestSortLabels[option]!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: AppColors.primaryGreen, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateFab() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton(
        heroTag: 'create_move_request',
        backgroundColor: AppColors.primaryGreen,
        onPressed: _openCreateMoveRequest,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moveRequestsAsync = ref.watch(moveRequestsListNotifierProvider);

    return moveRequestsAsync.when(
      data: (moveRequests) {
        if (moveRequests.isEmpty) {
          return Stack(
            children: [
              _buildEmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'No Move Requests',
                subtitle: 'Move requests will appear here',
              ),
              _buildCreateFab(),
            ],
          );
        }

        final filtered = _applyFilters(moveRequests);

        return Stack(
          children: [
            Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search bin #, address, or driver...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.grey.shade500, size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: Colors.grey.shade600, size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                // Status filter chips
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in _MoveRequestFilter.values) ...[
                          if (filter != _MoveRequestFilter.values.first)
                            const SizedBox(width: 8),
                          _FilterChip(
                            label: '${switch (filter) {
                              _MoveRequestFilter.all => 'All',
                              _MoveRequestFilter.pending => 'Pending',
                              _MoveRequestFilter.assigned => 'Assigned',
                              _MoveRequestFilter.inProgress => 'In Progress',
                              _MoveRequestFilter.completed => 'Completed',
                              _MoveRequestFilter.cancelled => 'Cancelled',
                            }} (${_countForStatus(moveRequests, filter)})',
                            isSelected: _statusFilter == filter,
                            onTap: () => setState(() => _statusFilter = filter),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Move type filter chips
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in _MoveTypeFilter.values) ...[
                          if (filter != _MoveTypeFilter.values.first)
                            const SizedBox(width: 8),
                          _FilterChip(
                            label: '${switch (filter) {
                              _MoveTypeFilter.all => 'All Types',
                              _MoveTypeFilter.store => 'Store',
                              _MoveTypeFilter.relocation => 'Relocation',
                              _MoveTypeFilter.redeployment => 'Redeployment',
                            }} (${_countForType(moveRequests, filter)})',
                            isSelected: _typeFilter == filter,
                            onTap: () => setState(() => _typeFilter = filter),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Sort row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: InkWell(
                    onTap: _showRequestSortPicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.sort, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            'Sort: ${_requestSortLabels[_sortOption]}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _sortOption == _RequestSortOption.newestFirst
                                  ? Colors.grey[500]
                                  : AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: _sortOption == _RequestSortOption.newestFirst
                                ? Colors.grey[500]
                                : AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // List
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.filter_list_off,
                          title: 'No matches',
                          subtitle: 'Try a different filter or search term',
                        )
                      : RefreshIndicator(
                          color: AppColors.primaryGreen,
                          onRefresh: () async {
                            ref.read(moveRequestsListNotifierProvider.notifier).refresh();
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final urgency = _computeUrgency(item);
                              return GestureDetector(
                                onTap: () => _showMoveRequestDetail(item, urgency),
                                child: _MoveRequestCard(
                                  data: item,
                                  computedUrgency: urgency,
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
            _buildCreateFab(),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 16),
            Text(
              'Failed to load move requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.red.shade600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(moveRequestsListNotifierProvider.notifier)
                  .refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String computedUrgency;

  const _MoveRequestCard({required this.data, required this.computedUrgency});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final moveType = data['move_type'] as String? ?? 'relocation';
    final binNumber = data['bin_number'] as int? ?? 0;
    final currentStreet = data['current_street'] as String? ?? '';
    final city = data['city'] as String? ?? '';
    final requestedByName = data['requested_by_name'] as String?;
    final scheduledDateIso = data['scheduled_date_iso'] as String?;
    final createdAtIso = data['created_at_iso'] as String?;
    final assignmentType = data['assignment_type'] as String? ?? '';
    final reason = data['reason'] as String?;
    final notes = data['notes'] as String?;
    // Assigned driver/user name — unified "driver_name" field, or fall back to specific ones
    final driverName = data['driver_name'] as String?
        ?? data['assigned_driver_name'] as String?
        ?? data['assigned_user_name'] as String?;

    final statusColor = _statusColor(status);
    final urgencyInfo = _urgencyInfo(computedUrgency);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: bin number + urgency + status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Bin #$binNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Urgency badge — show all levels
              if (computedUrgency != 'resolved' && computedUrgency != 'scheduled')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyInfo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: urgencyInfo.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(urgencyInfo.icon,
                          size: 14, color: urgencyInfo.color),
                      const SizedBox(width: 4),
                      Text(
                        urgencyInfo.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: urgencyInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStreet,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (city.isNotEmpty)
                      Text(
                        city,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Info rows: requester, assigned to, scheduled date, created date
          _buildInfoRows(
            requestedByName: requestedByName,
            driverName: driverName,
            scheduledDateIso: scheduledDateIso,
            createdAtIso: createdAtIso,
          ),
          // Move type + assignment badges
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMoveTypeBadge(moveType),
              if (assignmentType.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: assignmentType == 'manual'
                        ? Colors.amber.shade50
                        : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: assignmentType == 'manual'
                          ? Colors.amber.shade300
                          : Colors.teal.shade300,
                    ),
                  ),
                  child: Text(
                    assignmentType == 'manual' ? 'MANUAL' : 'SHIFT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: assignmentType == 'manual'
                          ? Colors.amber.shade900
                          : Colors.teal.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Reason
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Notes
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRows({
    String? requestedByName,
    String? driverName,
    String? scheduledDateIso,
    String? createdAtIso,
  }) {
    return Column(
      children: [
        if (requestedByName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.person_outline,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Requested by $requestedByName',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Assigned to
        if (driverName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.assignment_ind_outlined,
                    size: 16, color: Colors.blue.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Assigned to $driverName',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Scheduled date
        if (scheduledDateIso != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  _formatScheduledDate(scheduledDateIso),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        // Created date
        if (createdAtIso != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(Icons.access_time,
                    size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  'Created ${_formatCreatedDate(createdAtIso)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMoveTypeBadge(String moveType) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final String label;
    final IconData icon;

    switch (moveType) {
      case 'store':
        bgColor = Colors.purple.shade50;
        borderColor = Colors.purple.shade300;
        textColor = Colors.purple.shade700;
        label = 'STORE';
        icon = Icons.warehouse_outlined;
      case 'relocation':
        bgColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade300;
        textColor = Colors.blue.shade700;
        label = 'RELOCATION';
        icon = Icons.swap_horiz_rounded;
      case 'redeployment':
        bgColor = Colors.teal.shade50;
        borderColor = Colors.teal.shade300;
        textColor = Colors.teal.shade700;
        label = 'REDEPLOYMENT';
        icon = Icons.outbox_outlined;
      default:
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
        label = moveType.toUpperCase();
        icon = Icons.local_shipping_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'assigned':
        return Colors.blue.shade700;
      case 'in_progress':
        return Colors.purple.shade700;
      case 'completed':
        return AppColors.successGreen;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'IN PROGRESS';
      default:
        return status.toUpperCase();
    }
  }

  ({Color color, String label, IconData icon}) _urgencyInfo(String urgency) {
    return switch (urgency) {
      'overdue' => (
        color: Colors.red.shade700,
        label: 'OVERDUE',
        icon: Icons.error_outline,
      ),
      'urgent' => (
        color: Colors.red.shade600,
        label: 'URGENT',
        icon: Icons.warning_amber_rounded,
      ),
      'soon' => (
        color: Colors.orange.shade700,
        label: 'SOON',
        icon: Icons.schedule,
      ),
      _ => (
        color: Colors.blue.shade600,
        label: 'SCHEDULED',
        icon: Icons.event_outlined,
      ),
    };
  }

  static String _formatScheduledDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.inDays == 0 && difference.inHours >= 0) {
        return 'Scheduled: Today at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Scheduled: Tomorrow at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays > 1 && difference.inDays < 7) {
        return 'Scheduled: In ${difference.inDays} days';
      } else if (difference.inDays < 0) {
        final daysPast = difference.inDays.abs();
        if (daysPast == 1) {
          return 'Scheduled: Yesterday';
        } else {
          return 'Scheduled: $daysPast days overdue';
        }
      } else {
        return 'Scheduled: ${DateFormat('MMM d, yyyy').format(date)}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  static String _formatCreatedDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return 'yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return '';
    }
  }
}

// =============================================================================
// SHARED HELPERS
// =============================================================================

Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 48, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ),
  );
}
