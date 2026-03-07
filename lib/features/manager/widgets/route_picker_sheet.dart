import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/route.dart';
import 'package:ropacalapp/providers/routes_provider.dart';

/// Bottom sheet for selecting a route template.
/// Two-step flow with slide animation: browse routes → tap to preview bins → confirm.
class RoutePickerSheet extends HookConsumerWidget {
  const RoutePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final previewRoute = useState<RouteTemplate?>(null);
    final routesAsync = ref.watch(routesNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: previewRoute.value != null
                ? _RoutePreview(
                    key: const ValueKey('preview'),
                    route: previewRoute.value!,
                    scrollController: scrollController,
                    onBack: () => previewRoute.value = null,
                    onConfirm: () =>
                        Navigator.of(context).pop(previewRoute.value),
                  )
                : _RouteList(
                    key: const ValueKey('list'),
                    searchQuery: searchQuery,
                    routesAsync: routesAsync,
                    scrollController: scrollController,
                    onRouteTap: (route) => previewRoute.value = route,
                  ),
          ),
        );
      },
    );
  }
}

/// Step 1: Browse and search routes
class _RouteList extends StatelessWidget {
  final ValueNotifier<String> searchQuery;
  final AsyncValue<List<RouteTemplate>> routesAsync;
  final ScrollController scrollController;
  final ValueChanged<RouteTemplate> onRouteTap;

  const _RouteList({
    super.key,
    required this.searchQuery,
    required this.routesAsync,
    required this.scrollController,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            'Select Route',
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
              hintText: 'Search routes...',
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
        // Route list
        Expanded(
          child: routesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading routes: $e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            data: (routes) {
              final query = searchQuery.value.toLowerCase();
              final filtered = routes.where((r) {
                if (query.isEmpty) return true;
                return r.name.toLowerCase().contains(query) ||
                    r.geographicArea.toLowerCase().contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        routes.isEmpty
                            ? 'No routes created yet'
                            : 'No routes match your search',
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
                  final route = filtered[index];
                  return _RouteCard(
                    route: route,
                    onTap: () => onRouteTap(route),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Route card in the list view
class _RouteCard extends StatelessWidget {
  final RouteTemplate route;
  final VoidCallback onTap;

  const _RouteCard({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route,
                  size: 22,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (route.geographicArea.isNotEmpty) ...[
                          Icon(Icons.location_on,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              route.geographicArea,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Icon(Icons.delete_outline,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          '${route.binCount} bins',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (route.estimatedDurationHours != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.access_time,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Text(
                            '${route.estimatedDurationHours!.toStringAsFixed(1)}h',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
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
}

/// Step 2: Preview a route's bins before confirming
class _RoutePreview extends StatelessWidget {
  final RouteTemplate route;
  final ScrollController scrollController;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const _RoutePreview({
    super.key,
    required this.route,
    required this.scrollController,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final bins = List<RouteBin>.from(route.bins)
      ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

    return Column(
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

        // Header with back button
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (route.geographicArea.isNotEmpty) ...[
                          Icon(Icons.location_on,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Text(
                            route.geographicArea,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Icon(Icons.delete_outline,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          '${bins.length} bins',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Divider(height: 1, color: Colors.grey.shade200),

        // Bin list
        Expanded(
          child: bins.isEmpty
              ? Center(
                  child: Text(
                    'No bins in this route',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: bins.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final bin = bins[index];
                    return _BinRow(bin: bin, index: index);
                  },
                ),
        ),

        // Confirm button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Add Route (${bins.length} bins)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Single bin row in the preview list
class _BinRow extends StatelessWidget {
  final RouteBin bin;
  final int index;

  const _BinRow({required this.bin, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Sequence number
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bin info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bin #${bin.binNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bin.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Fill percentage
          if (bin.fillPercentage != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    _fillColor(bin.fillPercentage!).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${bin.fillPercentage}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _fillColor(bin.fillPercentage!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _fillColor(int percentage) {
    if (percentage >= 80) return Colors.red;
    if (percentage >= 50) return Colors.orange;
    return Colors.green;
  }
}
