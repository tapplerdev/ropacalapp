import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/models/potential_location.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/providers/potential_locations_list_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';

/// Bottom sheet for selecting potential locations to add as placement tasks.
/// Multi-select with checkboxes, sorting chips, enriched cards, map preview.
class PotentialLocationPickerSheet extends HookConsumerWidget {
  const PotentialLocationPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final selectedSort = useState('newest');
    final selectedIds = useState<Set<String>>({});
    final previewLocation = useState<PotentialLocation?>(null);
    final locationsAsync = ref.watch(potentialLocationsListNotifierProvider);
    final binsAsync = ref.watch(binsListProvider);

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
            child: previewLocation.value != null
                ? _MapPreview(
                    key: const ValueKey('map'),
                    location: previewLocation.value!,
                    bins: binsAsync.valueOrNull ?? [],
                    onBack: () => previewLocation.value = null,
                  )
                : _LocationList(
                    key: const ValueKey('list'),
                    searchQuery: searchQuery,
                    selectedSort: selectedSort,
                    selectedIds: selectedIds,
                    locationsAsync: locationsAsync,
                    scrollController: scrollController,
                    onViewMap: (location) =>
                        previewLocation.value = location,
                  ),
          ),
        );
      },
    );
  }
}

/// List view with search, sorting, and multi-select
class _LocationList extends StatelessWidget {
  final ValueNotifier<String> searchQuery;
  final ValueNotifier<String> selectedSort;
  final ValueNotifier<Set<String>> selectedIds;
  final AsyncValue<List<PotentialLocation>> locationsAsync;
  final ScrollController scrollController;
  final void Function(PotentialLocation) onViewMap;

  const _LocationList({
    super.key,
    required this.searchQuery,
    required this.selectedSort,
    required this.selectedIds,
    required this.locationsAsync,
    required this.scrollController,
    required this.onViewMap,
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
            'Add Placements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => searchQuery.value = v,
            decoration: InputDecoration(
              hintText: 'Search locations...',
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
        // Sorting chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _SortChip(
                label: 'Newest',
                isSelected: selectedSort.value == 'newest',
                onTap: () => selectedSort.value = 'newest',
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Oldest',
                isSelected: selectedSort.value == 'oldest',
                onTap: () => selectedSort.value = 'oldest',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Location list
        Expanded(
          child: locationsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
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
                      'Error loading locations: $e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            data: (locations) {
              final query = searchQuery.value.toLowerCase();
              var filtered = locations.where((l) {
                if (query.isEmpty) return true;
                return l.address.toLowerCase().contains(query) ||
                    l.street.toLowerCase().contains(query) ||
                    l.city.toLowerCase().contains(query);
              }).toList();

              // Sort
              filtered.sort((a, b) {
                final aDate = DateTime.tryParse(a.createdAtIso) ?? DateTime(2000);
                final bDate = DateTime.tryParse(b.createdAtIso) ?? DateTime(2000);
                return selectedSort.value == 'newest'
                    ? bDate.compareTo(aDate)
                    : aDate.compareTo(bDate);
              });

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_location_alt,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        locations.isEmpty
                            ? 'No potential locations available'
                            : 'No locations match your search',
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
                  final location = filtered[index];
                  final isSelected = selectedIds.value.contains(location.id);
                  return _LocationCard(
                    location: location,
                    isSelected: isSelected,
                    onTap: () {
                      final updated = Set<String>.from(selectedIds.value);
                      if (isSelected) {
                        updated.remove(location.id);
                      } else {
                        updated.add(location.id);
                      }
                      selectedIds.value = updated;
                    },
                    onViewMap: () => onViewMap(location),
                  );
                },
              );
            },
          ),
        ),

        // Confirm button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedIds.value.isEmpty
                    ? null
                    : () {
                        final locations = locationsAsync.valueOrNull;
                        if (locations == null) return;
                        final selected = locations
                            .where((l) => selectedIds.value.contains(l.id))
                            .toList();
                        Navigator.of(context).pop(selected);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  selectedIds.value.isEmpty
                      ? 'Select locations'
                      : 'Add ${selectedIds.value.length} Placement${selectedIds.value.length > 1 ? 's' : ''}',
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

/// Map preview showing potential location pin + nearby bin markers
class _MapPreview extends StatelessWidget {
  final PotentialLocation location;
  final List<Bin> bins;
  final VoidCallback onBack;

  const _MapPreview({
    super.key,
    required this.location,
    required this.bins,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with back button
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 16, 8),
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
                      location.street,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${location.city}, ${location.zip}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Map
        Expanded(
          child: GoogleMapsMapView(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                latitude: location.latitude ?? 0,
                longitude: location.longitude ?? 0,
              ),
              zoom: 15,
            ),
            initialMapType: MapType.normal,
            initialZoomControlsEnabled: false,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
            },
            onViewCreated: (controller) async {
              await _addMarkers(controller);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addMarkers(GoogleMapViewController controller) async {
    final markerOptions = <MarkerOptions>[];

    // 1. Add potential location pin
    final locationIcon =
        await GoogleNavigationMarkerService.createPotentialLocationMarkerIcon(
      isPending: true,
      withPulse: false,
    );
    markerOptions.add(
      MarkerOptions(
        position: LatLng(
          latitude: location.latitude ?? 0,
          longitude: location.longitude ?? 0,
        ),
        icon: locationIcon,
        anchor: const MarkerAnchor(u: 0.5, v: 1.0),
        zIndex: 9998.0,
        infoWindow: InfoWindow(
          title: 'Potential Location',
          snippet: '${location.street}, ${location.city}',
        ),
      ),
    );

    // 2. Add bin markers
    for (final bin in bins) {
      if (bin.latitude == null || bin.longitude == null) continue;
      final binIcon =
          await GoogleNavigationMarkerService.createBinMarkerIcon(
        bin.binNumber,
        bin.fillPercentage ?? 0,
      );
      markerOptions.add(
        MarkerOptions(
          position: LatLng(
            latitude: bin.latitude!,
            longitude: bin.longitude!,
          ),
          icon: binIcon,
          anchor: const MarkerAnchor(u: 0.5, v: 0.5),
          zIndex: 9999.0,
          infoWindow: InfoWindow(
            title: 'Bin #${bin.binNumber}',
            snippet:
                '${bin.address} - ${bin.fillPercentage ?? 0}% full',
          ),
        ),
      );
    }

    await controller.addMarkers(markerOptions);
  }
}

/// Location card with checkbox, details, and map button
class _LocationCard extends StatelessWidget {
  final PotentialLocation location;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onViewMap;

  const _LocationCard({
    required this.location,
    required this.isSelected,
    required this.onTap,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoords = location.latitude != null && location.longitude != null;

    return Material(
      color: isSelected
          ? AppColors.primaryGreen.withValues(alpha: 0.05)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Location icon
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_location,
                    size: 20,
                    color: Colors.orange.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.street,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${location.city}, ${location.zip}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (location.notes != null &&
                        location.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        location.notes!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Requester + time ago
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _buildRequesterLine(
                              location.requestedByName,
                              location.createdAtIso,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // View on Map button
              if (hasCoords)
                GestureDetector(
                  onTap: onViewMap,
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.map_outlined,
                      size: 18,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildRequesterLine(String requestedByName, String createdAtIso) {
    final parts = <String>[];
    if (requestedByName.isNotEmpty) parts.add(requestedByName);
    final timeAgo = _timeAgo(createdAtIso);
    if (timeAgo.isNotEmpty) parts.add(timeAgo);
    return parts.isEmpty ? 'Unknown' : parts.join(' · ');
  }
}

/// Sorting chip
class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
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
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
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

/// Convert ISO date string to relative time
String _timeAgo(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  } catch (_) {
    return '';
  }
}
