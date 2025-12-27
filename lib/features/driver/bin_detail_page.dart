import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/bin_helpers.dart';
import 'package:ropacalapp/core/utils/responsive_helper.dart';
import 'package:ropacalapp/features/driver/widgets/check_in_dialog.dart';
import 'package:ropacalapp/features/driver/widgets/move_dialog.dart';
import 'package:ropacalapp/features/driver/widgets/tab_button.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/providers/bins_provider.dart';

class BinDetailPage extends HookConsumerWidget {
  final String binId;

  const BinDetailPage({super.key, required this.binId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binsState = ref.watch(binsListProvider);
    final selectedTab = useState(0);

    return Scaffold(
      body: binsState.when(
        data: (bins) {
          final bin = bins.firstWhere((b) => b.id == binId);

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, bin),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildFillLevelCard(context, bin),
                    _buildInfoCard(context, bin),
                    SizedBox(height: ResponsiveHelper(context).gapLarge),
                    _buildActionButtons(context, ref, bin),
                    SizedBox(height: ResponsiveHelper(context).gapLarge),
                    _buildHistoryTabs(context, selectedTab),
                    SizedBox(height: ResponsiveHelper(context).gapLarge),
                    _buildHistoryContent(context, selectedTab.value, bin),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Bin bin) {
    final responsive = ResponsiveHelper(context);
    const expandedHeight = 200.0;
    const collapsedHeight = kToolbarHeight;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      centerTitle: true,
      backgroundColor: AppColors.darkBackground,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Calculate collapse factor (0.0 = collapsed, 1.0 = expanded)
          final collapseFactor =
              ((constraints.maxHeight - collapsedHeight) /
                      (expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);

          // Fade out icon and badge when collapsing
          final contentOpacity = collapseFactor.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            centerTitle: true,
            titlePadding: EdgeInsets.only(
              left: responsive.cardMargin,
              right: responsive.cardMargin,
              bottom: responsive.cardMargin,
            ),
            title: Text(
              'Bin #${bin.binNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(color: AppColors.darkBackground),
              child: SafeArea(
                child: Opacity(
                  opacity: contentOpacity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: responsive.iconAppBar,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      SizedBox(height: responsive.gapMedium),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.gapMedium,
                          vertical: responsive.scale(6),
                        ),
                        decoration: BoxDecoration(
                          color: bin.status == BinStatus.active
                              ? AppColors.successGreen
                              : AppColors.alertRed,
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius,
                          ),
                        ),
                        child: Text(
                          bin.status == BinStatus.active ? 'ACTIVE' : 'MISSING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.scale(12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.appBarBottomSpacing),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFillLevelCard(BuildContext context, Bin bin) {
    final fillPercentage = bin.fillPercentage ?? 0;
    final color = BinHelpers.getFillColor(fillPercentage);
    final responsive = ResponsiveHelper(context);

    return Card(
      margin: EdgeInsets.all(responsive.cardMarginLarge),
      child: Padding(
        padding: EdgeInsets.all(responsive.cardPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fill Level',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '$fillPercentage%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.gapLarge),
            ClipRRect(
              borderRadius: BorderRadius.circular(responsive.borderRadiusSmall),
              child: LinearProgressIndicator(
                value: fillPercentage / 100,
                minHeight: responsive.progressIndicatorHeight,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            SizedBox(height: responsive.gapMediumSmall),
            Text(
              _getFillDescription(fillPercentage),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
            if (bin.lastChecked != null) ...[
              SizedBox(height: responsive.gapMedium),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: responsive.iconSmall,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: responsive.gapSmall),
                  Text(
                    'Last checked ${_formatDate(bin.lastChecked!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Bin bin) {
    final responsive = ResponsiveHelper(context);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: responsive.locationCardMargin),
      child: Padding(
        padding: EdgeInsets.all(responsive.cardPaddingXXLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: responsive.gapLarge),
            _buildInfoRow(
              context,
              Icons.location_on,
              'Address',
              '${bin.currentStreet}\n${bin.city}, ${bin.zip}',
            ),
            if (bin.latitude != null && bin.longitude != null) ...[
              Divider(height: responsive.scale(32)),
              _buildInfoRow(
                context,
                Icons.map,
                'Coordinates',
                '${bin.latitude}, ${bin.longitude}',
              ),
            ],
            if (bin.lastMoved != null) ...[
              Divider(height: responsive.scale(32)),
              _buildInfoRow(
                context,
                Icons.local_shipping,
                'Last Moved',
                _formatDate(bin.lastMoved!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final responsive = ResponsiveHelper(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: responsive.iconMediumSmall,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: responsive.gapLarge),
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
              SizedBox(height: responsive.gapXSmall),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Bin bin) {
    final responsive = ResponsiveHelper(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.buttonPaddingHorizontalLarge,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showCheckInDialog(context, ref, bin),
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: responsive.tabButtonPadding,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: responsive.iconMedium,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: responsive.gapSmallMedium),
                    Text(
                      'Check In',
                      style: TextStyle(
                        fontSize: responsive.fontSmall,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: responsive.gapMediumSmall),
          Expanded(
            child: InkWell(
              onTap: () => _showMoveDialog(context, ref, bin),
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: responsive.tabButtonPadding,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: responsive.iconMedium,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: responsive.gapSmallMedium),
                    Text(
                      'Move Bin',
                      style: TextStyle(
                        fontSize: responsive.fontSmall,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
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

  Widget _buildHistoryTabs(
    BuildContext context,
    ValueNotifier<int> selectedTab,
  ) {
    final responsive = ResponsiveHelper(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.buttonPaddingHorizontalLarge,
      ),
      child: Row(
        children: [
          Expanded(
            child: TabButton(
              label: 'Check History',
              icon: Icons.history,
              isSelected: selectedTab.value == 0,
              onTap: () => selectedTab.value = 0,
            ),
          ),
          SizedBox(width: responsive.gapMediumSmall),
          Expanded(
            child: TabButton(
              label: 'Move History',
              icon: Icons.local_shipping,
              isSelected: selectedTab.value == 1,
              onTap: () => selectedTab.value = 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent(BuildContext context, int selectedTab, Bin bin) {
    if (selectedTab == 0) {
      return _buildCheckHistory(context, bin);
    } else {
      return _buildMoveHistory(context, bin);
    }
  }

  Widget _buildCheckHistory(BuildContext context, Bin bin) {
    final responsive = ResponsiveHelper(context);

    // Placeholder - will be populated with real data from provider
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.buttonPaddingHorizontalLarge,
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(responsive.cardPaddingLarge),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: responsive.iconLarge,
                color: Colors.grey[400],
              ),
              SizedBox(height: responsive.gapMedium),
              Text(
                'No check history yet',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              SizedBox(height: responsive.gapMediumSmall),
              Text(
                'Check-ins will appear here',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoveHistory(BuildContext context, Bin bin) {
    final responsive = ResponsiveHelper(context);

    // Placeholder - will be populated with real data from provider
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.buttonPaddingHorizontalLarge,
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(responsive.cardPaddingLarge),
          child: Column(
            children: [
              Icon(
                Icons.local_shipping,
                size: responsive.iconLarge,
                color: Colors.grey[400],
              ),
              SizedBox(height: responsive.gapMedium),
              Text(
                'No move history yet',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              SizedBox(height: responsive.gapMediumSmall),
              Text(
                'Bin movements will appear here',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCheckInDialog(BuildContext context, WidgetRef ref, Bin bin) {
    showDialog(
      context: context,
      builder: (context) => CheckInDialog(bin: bin),
    );
  }

  void _showMoveDialog(BuildContext context, WidgetRef ref, Bin bin) {
    showDialog(
      context: context,
      builder: (context) => MoveDialog(bin: bin),
    );
  }

  String _getFillDescription(int percentage) {
    if (percentage > BinConstants.criticalFillThreshold) {
      return 'High fill - needs attention';
    }
    if (percentage > BinConstants.mediumFillThreshold) {
      return 'Moderate fill';
    }
    return 'Low fill - good condition';
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
