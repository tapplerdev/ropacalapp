import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/utils/bin_helpers.dart';
import 'package:ropacalapp/core/utils/responsive_helper.dart';

enum BinFilter { all, highFill, checked }

class BinsListPage extends HookConsumerWidget {
  const BinsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = ResponsiveHelper(context);
    final binsState = ref.watch(binsListProvider);
    final searchInput = useState(''); // User's raw input
    final debouncedSearchQuery = useState(''); // Debounced value used for filtering
    final selectedFilter = useState(BinFilter.all);

    // Debounce search input
    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 300), () {
        debouncedSearchQuery.value = searchInput.value;
      });
      return timer.cancel;
    }, [searchInput.value]);

    List<Bin> filterBins(List<Bin> bins) {
      var filtered = bins;

      // Apply search filter (using debounced value)
      if (debouncedSearchQuery.value.isNotEmpty) {
        filtered = filtered.where((bin) {
          final query = debouncedSearchQuery.value.toLowerCase();
          return bin.binNumber.toString().contains(query) ||
              bin.currentStreet.toLowerCase().contains(query) ||
              bin.city.toLowerCase().contains(query);
        }).toList();
      }

      // Apply status filter
      switch (selectedFilter.value) {
        case BinFilter.highFill:
          filtered = filtered
              .where(
                (bin) =>
                    (bin.fillPercentage ?? 0) > BinConstants.highFillThreshold,
              )
              .toList();
          break;
        case BinFilter.checked:
          filtered = filtered.where((bin) => bin.checked).toList();
          break;
        case BinFilter.all:
          break;
      }

      return filtered;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bins'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(binsListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(responsive.gapLarge),
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
                onChanged: (value) => searchInput.value = value,
                decoration: InputDecoration(
                  hintText: 'Search by bin #, street, or city',
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: responsive.gapLarge),
            child: Row(
              children: [
                _FilterButton(
                  label: 'All',
                  isSelected: selectedFilter.value == BinFilter.all,
                  onTap: () => selectedFilter.value = BinFilter.all,
                ),
                SizedBox(width: responsive.gapMediumSmall),
                _FilterButton(
                  label: 'High Fill (>70%)',
                  isSelected: selectedFilter.value == BinFilter.highFill,
                  onTap: () => selectedFilter.value = BinFilter.highFill,
                ),
                SizedBox(width: responsive.gapMediumSmall),
                _FilterButton(
                  label: 'Checked Today',
                  isSelected: selectedFilter.value == BinFilter.checked,
                  onTap: () => selectedFilter.value = BinFilter.checked,
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.gapLarge),

          // Bins list
          Expanded(
            child: binsState.when(
              data: (bins) {
                final filteredBins = filterBins(bins);

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
                    child: filteredBins.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: responsive.scale(64),
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: responsive.gapLarge),
                                Text(
                                  'No bins found',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                                SizedBox(height: responsive.gapMediumSmall),
                                Text(
                                  'Try adjusting your filters or search',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.gapLarge,
                            ),
                            itemCount: filteredBins.length,
                            itemBuilder: (context, index) {
                              final bin = filteredBins[index];
                              return _BinListItem(bin: bin);
                            },
                          ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error,
                      size: responsive.iconLarge,
                      color: Colors.red,
                    ),
                    SizedBox(height: responsive.gapLarge),
                    Text('Error loading bins: $error'),
                    SizedBox(height: responsive.gapLarge),
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
      ),
    );
  }
}

class _BinListItem extends StatelessWidget {
  final Bin bin;

  const _BinListItem({required this.bin});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final fillPercentage = bin.fillPercentage ?? 0;
    final fillColor = BinHelpers.getFillColor(fillPercentage);

    return Container(
      margin: EdgeInsets.only(bottom: responsive.gapMedium),
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
        onTap: () => context.push('/bin/${bin.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(responsive.gapLarge),
          child: Row(
            children: [
              // Bin number circle
              Container(
                width: responsive.iconLarge,
                height: responsive.iconLarge,
                decoration: BoxDecoration(
                  color: fillColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    bin.binNumber.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.fontMedium,
                    ),
                  ),
                ),
              ),

              SizedBox(width: responsive.gapLarge),

              // Bin details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bin.currentStreet,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: responsive.gapSmall),
                    Text(
                      '${bin.city}, ${bin.zip}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: responsive.gapMediumSmall),
                    Row(
                      children: [
                        // Fill percentage
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.gapMediumSmall,
                            vertical: responsive.gapSmall,
                          ),
                          decoration: BoxDecoration(
                            color: fillColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              responsive.scale(6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.water_drop,
                                size: responsive.scale(14),
                                color: fillColor,
                              ),
                              SizedBox(width: responsive.gapSmall),
                              Text(
                                '$fillPercentage%',
                                style: TextStyle(
                                  color: fillColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: responsive.scale(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: responsive.gapMediumSmall),
                        // Checked badge
                        if (bin.checked)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.gapMediumSmall,
                              vertical: responsive.gapSmall,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                responsive.scale(6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: responsive.scale(14),
                                  color: AppColors.successGreen,
                                ),
                                SizedBox(width: responsive.gapSmall),
                                Text(
                                  'Checked',
                                  style: TextStyle(
                                    color: AppColors.successGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: responsive.scale(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom filter button with clean chip design
class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.gapLarge,
          vertical: responsive.gapMediumSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(responsive.scale(20)),
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
