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
    final searchQuery = useState('');
    final selectedFilter = useState(BinFilter.all);

    List<Bin> filterBins(List<Bin> bins) {
      var filtered = bins;

      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        filtered = filtered.where((bin) {
          final query = searchQuery.value.toLowerCase();
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
      appBar: AppBar(
        title: const Text('All Bins'),
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
            child: TextField(
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search by bin #, street, or city',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => searchQuery.value = '',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: responsive.gapLarge),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: selectedFilter.value == BinFilter.all,
                  onSelected: (_) => selectedFilter.value = BinFilter.all,
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                ),
                SizedBox(width: responsive.gapMediumSmall),
                FilterChip(
                  label: const Text('High Fill (>70%)'),
                  selected: selectedFilter.value == BinFilter.highFill,
                  onSelected: (_) => selectedFilter.value = BinFilter.highFill,
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: AppColors.warningOrange.withOpacity(0.2),
                ),
                SizedBox(width: responsive.gapMediumSmall),
                FilterChip(
                  label: const Text('Checked Today'),
                  selected: selectedFilter.value == BinFilter.checked,
                  onSelected: (_) => selectedFilter.value = BinFilter.checked,
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: AppColors.successGreen.withOpacity(0.2),
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

                if (filteredBins.isEmpty) {
                  return Center(
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        SizedBox(height: responsive.gapMediumSmall),
                        Text(
                          'Try adjusting your filters or search',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.gapLarge,
                  ),
                  itemCount: filteredBins.length,
                  itemBuilder: (context, index) {
                    final bin = filteredBins[index];
                    return _BinListItem(bin: bin);
                  },
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

    return Card(
      margin: EdgeInsets.only(bottom: responsive.gapMedium),
      child: InkWell(
        onTap: () => context.push('/bin/${bin.id}'),
        borderRadius: BorderRadius.circular(responsive.gapLarge),
        child: Padding(
          padding: EdgeInsets.all(responsive.gapLarge),
          child: Row(
            children: [
              // Bin number circle
              Container(
                width: responsive.iconLarge,
                height: responsive.iconLarge,
                decoration: BoxDecoration(
                  color: fillColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: fillColor,
                    width: responsive.scale(2),
                  ),
                ),
                child: Center(
                  child: Text(
                    bin.binNumber.toString(),
                    style: TextStyle(
                      color: fillColor,
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
                            color: fillColor.withOpacity(0.1),
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
                              color: AppColors.successGreen.withOpacity(0.1),
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
