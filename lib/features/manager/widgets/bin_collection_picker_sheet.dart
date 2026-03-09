import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/providers/bins_provider.dart';

/// Bottom sheet for selecting bins to add as collection tasks.
/// Supports both list-based selection and interactive map selection.
class BinCollectionPickerSheet extends HookConsumerWidget {
  final Set<String> existingBinIds;

  const BinCollectionPickerSheet({
    super.key,
    this.existingBinIds = const {},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final selectedFilter = useState('all');
    final selectedIds = useState<Set<String>>({});
    final previewBin = useState<Bin?>(null);
    final showMapSelect = useState(false);
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
            child: showMapSelect.value
                ? _MapSelectView(
                    key: const ValueKey('map_select'),
                    bins: _getEligibleBins(binsAsync),
                    selectedIds: selectedIds,
                    existingBinIds: existingBinIds,
                    onBack: () => showMapSelect.value = false,
                  )
                : previewBin.value != null
                    ? _MapPreview(
                        key: const ValueKey('map_preview'),
                        bin: previewBin.value!,
                        onBack: () => previewBin.value = null,
                      )
                    : _BinList(
                        key: const ValueKey('list'),
                        searchQuery: searchQuery,
                        selectedFilter: selectedFilter,
                        selectedIds: selectedIds,
                        binsAsync: binsAsync,
                        existingBinIds: existingBinIds,
                        scrollController: scrollController,
                        onViewMap: (bin) => previewBin.value = bin,
                        onShowMapSelect: () => showMapSelect.value = true,
                      ),
          ),
        );
      },
    );
  }

  /// Get eligible bins (active + missing) from async state
  List<Bin> _getEligibleBins(AsyncValue<List<Bin>> binsAsync) {
    final bins = binsAsync.valueOrNull ?? [];
    return bins
        .where((b) =>
            b.status == BinStatus.active || b.status == BinStatus.missing)
        .where((b) => b.latitude != null && b.longitude != null)
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════
// List View
// ═══════════════════════════════════════════════════════════════

/// List view with search, filter chips, and multi-select
class _BinList extends StatelessWidget {
  final ValueNotifier<String> searchQuery;
  final ValueNotifier<String> selectedFilter;
  final ValueNotifier<Set<String>> selectedIds;
  final AsyncValue<List<Bin>> binsAsync;
  final Set<String> existingBinIds;
  final ScrollController scrollController;
  final void Function(Bin) onViewMap;
  final VoidCallback onShowMapSelect;

  const _BinList({
    super.key,
    required this.searchQuery,
    required this.selectedFilter,
    required this.selectedIds,
    required this.binsAsync,
    required this.existingBinIds,
    required this.scrollController,
    required this.onViewMap,
    required this.onShowMapSelect,
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
        // Title row with map toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Add Collections',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: onShowMapSelect,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Map',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => searchQuery.value = v,
            decoration: InputDecoration(
              hintText: 'Search by bin # or address...',
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
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedFilter.value == 'all',
                  onTap: () => selectedFilter.value = 'all',
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Critical (≥80%)',
                  isSelected: selectedFilter.value == 'critical',
                  onTap: () => selectedFilter.value = 'critical',
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'High (50-79%)',
                  isSelected: selectedFilter.value == 'high',
                  onTap: () => selectedFilter.value = 'high',
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Medium (25-49%)',
                  isSelected: selectedFilter.value == 'medium',
                  onTap: () => selectedFilter.value = 'medium',
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Low (0-24%)',
                  isSelected: selectedFilter.value == 'low',
                  onTap: () => selectedFilter.value = 'low',
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Missing',
                  isSelected: selectedFilter.value == 'missing',
                  onTap: () => selectedFilter.value = 'missing',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Bin list
        Expanded(
          child: binsAsync.when(
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
                      'Error loading bins: $e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            data: (bins) {
              // Filter to collectable bins only (active + missing)
              var filtered = bins
                  .where((b) =>
                      b.status == BinStatus.active ||
                      b.status == BinStatus.missing)
                  .toList();

              // Apply search
              final query = searchQuery.value.toLowerCase();
              if (query.isNotEmpty) {
                filtered = filtered.where((b) {
                  return b.binNumber.toString().contains(query) ||
                      b.currentStreet.toLowerCase().contains(query) ||
                      b.city.toLowerCase().contains(query);
                }).toList();
              }

              // Apply fill level filter
              filtered = _applyFilter(filtered, selectedFilter.value);

              // Sort by fill percentage descending (fullest first)
              filtered.sort((a, b) {
                final aFill = a.fillPercentage ?? 0;
                final bFill = b.fillPercentage ?? 0;
                return bFill.compareTo(aFill);
              });

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        bins.isEmpty
                            ? 'No bins available'
                            : 'No bins match your search',
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
                  final bin = filtered[index];
                  final isAlreadyInShift = existingBinIds.contains(bin.id);
                  final isSelected = selectedIds.value.contains(bin.id);
                  return _BinCard(
                    bin: bin,
                    isSelected: isSelected,
                    isAlreadyInShift: isAlreadyInShift,
                    onTap: isAlreadyInShift
                        ? null
                        : () {
                            final updated =
                                Set<String>.from(selectedIds.value);
                            if (isSelected) {
                              updated.remove(bin.id);
                            } else {
                              updated.add(bin.id);
                            }
                            selectedIds.value = updated;
                          },
                    onViewMap: () => onViewMap(bin),
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
                        final bins = binsAsync.valueOrNull;
                        if (bins == null) return;
                        final selected = bins
                            .where((b) => selectedIds.value.contains(b.id))
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
                      ? 'Select bins'
                      : 'Add ${selectedIds.value.length} Collection${selectedIds.value.length > 1 ? 's' : ''}',
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

  List<Bin> _applyFilter(List<Bin> bins, String filter) {
    switch (filter) {
      case 'critical':
        return bins.where((b) => (b.fillPercentage ?? 0) >= 80).toList();
      case 'high':
        return bins.where((b) {
          final fill = b.fillPercentage ?? 0;
          return fill >= 50 && fill < 80;
        }).toList();
      case 'medium':
        return bins.where((b) {
          final fill = b.fillPercentage ?? 0;
          return fill >= 25 && fill < 50;
        }).toList();
      case 'low':
        return bins.where((b) => (b.fillPercentage ?? 0) < 25).toList();
      case 'missing':
        return bins.where((b) => b.status == BinStatus.missing).toList();
      default:
        return bins;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Interactive Map Selection View
// ═══════════════════════════════════════════════════════════════

/// Full-screen interactive map for selecting bins by tapping markers.
/// Selected markers get a blue glow ring baked into the icon bitmap.
class _MapSelectView extends StatefulWidget {
  final List<Bin> bins;
  final ValueNotifier<Set<String>> selectedIds;
  final Set<String> existingBinIds;
  final VoidCallback onBack;

  const _MapSelectView({
    super.key,
    required this.bins,
    required this.selectedIds,
    required this.existingBinIds,
    required this.onBack,
  });

  @override
  State<_MapSelectView> createState() => _MapSelectViewState();
}

class _MapSelectViewState extends State<_MapSelectView> {
  GoogleMapViewController? _controller;
  final Map<String, Bin> _markerToBin = {}; // markerId -> Bin
  final Map<String, String> _binToMarkerId = {}; // binId -> markerId
  final Map<String, Marker> _markerObjects = {}; // markerId -> Marker object

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        GoogleMapsMapView(
          initialCameraPosition: const CameraPosition(
            target: LatLng(latitude: 40.0, longitude: -74.5),
            zoom: 10,
          ),
          initialMapType: MapType.normal,
          initialZoomControlsEnabled: false,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
          },
          onViewCreated: _onMapCreated,
          onMarkerClicked: _onMarkerTapped,
        ),

        // Top bar overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 12, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select on Map',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap bins to add to collection',
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
        ),

        // Bottom bar overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: widget.selectedIds,
                builder: (context, ids, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          ids.isEmpty
                              ? 'No bins selected yet'
                              : '${ids.length} bin${ids.length > 1 ? 's' : ''} selected',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ids.isEmpty
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: widget.onBack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onMapCreated(GoogleMapViewController controller) async {
    _controller = controller;

    if (widget.bins.isEmpty) return;

    // Create markers for all eligible bins
    final markerOptions = <MarkerOptions>[];
    final binsWithCoords = <Bin>[];

    for (final bin in widget.bins) {
      final icon = await GoogleNavigationMarkerService.createBinMarkerIcon(
        bin.binNumber,
        bin.fillPercentage ?? 0,
      );

      markerOptions.add(MarkerOptions(
        position: LatLng(
          latitude: bin.latitude!,
          longitude: bin.longitude!,
        ),
        icon: icon,
        anchor: const MarkerAnchor(u: 0.5, v: 0.5),
        zIndex: 9999.0,
        infoWindow: InfoWindow(
          title: 'Bin #${bin.binNumber}',
          snippet: '${bin.fillPercentage ?? 0}% full',
        ),
      ));
      binsWithCoords.add(bin);
    }

    final addedMarkers = await controller.addMarkers(markerOptions);
    final markers = addedMarkers.whereType<Marker>().toList();

    // Build lookups
    for (int i = 0; i < markers.length && i < binsWithCoords.length; i++) {
      final marker = markers[i];
      final bin = binsWithCoords[i];
      _markerToBin[marker.markerId] = bin;
      _binToMarkerId[bin.id] = marker.markerId;
      _markerObjects[marker.markerId] = marker;
    }

    // Swap icons for any already-selected bins
    for (final binId in widget.selectedIds.value) {
      final markerId = _binToMarkerId[binId];
      final bin = _markerToBin.values.where((b) => b.id == binId).firstOrNull;
      if (markerId != null && bin != null) {
        await _swapToSelectedIcon(markerId, bin);
      }
    }

    // Fit camera to show all markers
    if (binsWithCoords.length >= 2) {
      double minLat = double.infinity, maxLat = -double.infinity;
      double minLng = double.infinity, maxLng = -double.infinity;
      for (final bin in binsWithCoords) {
        if (bin.latitude! < minLat) minLat = bin.latitude!;
        if (bin.latitude! > maxLat) maxLat = bin.latitude!;
        if (bin.longitude! < minLng) minLng = bin.longitude!;
        if (bin.longitude! > maxLng) maxLng = bin.longitude!;
      }
      await controller.moveCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(latitude: minLat, longitude: minLng),
          northeast: LatLng(latitude: maxLat, longitude: maxLng),
        ),
        padding: 80,
      ));
    } else if (binsWithCoords.length == 1) {
      await controller.moveCamera(CameraUpdate.newLatLngZoom(
        LatLng(
          latitude: binsWithCoords[0].latitude!,
          longitude: binsWithCoords[0].longitude!,
        ),
        14,
      ));
    }
  }

  void _onMarkerTapped(String markerId) {
    final bin = _markerToBin[markerId];
    if (bin == null) return;

    // Ignore bins already in the shift
    if (widget.existingBinIds.contains(bin.id)) return;

    final updated = Set<String>.from(widget.selectedIds.value);
    if (updated.contains(bin.id)) {
      // Deselect — swap back to normal icon
      updated.remove(bin.id);
      _swapToNormalIcon(markerId, bin);
    } else {
      // Select — swap to selected (blue glow) icon
      updated.add(bin.id);
      _swapToSelectedIcon(markerId, bin);
    }
    widget.selectedIds.value = updated;
  }

  /// Replace marker with blue-glow selected variant
  Future<void> _swapToSelectedIcon(String markerId, Bin bin) async {
    if (_controller == null) return;

    final oldMarker = _markerObjects[markerId];
    if (oldMarker == null) return;

    final selectedIcon =
        await GoogleNavigationMarkerService.createSelectedBinMarkerIcon(
      bin.binNumber,
      bin.fillPercentage ?? 0,
    );

    // Remove old marker, add new one with selected icon
    await _controller!.removeMarkers([oldMarker]);

    final newMarkers = await _controller!.addMarkers([
      MarkerOptions(
        position: LatLng(
          latitude: bin.latitude!,
          longitude: bin.longitude!,
        ),
        icon: selectedIcon,
        anchor: const MarkerAnchor(u: 0.5, v: 0.5),
        zIndex: 10000.0,
        infoWindow: InfoWindow(
          title: 'Bin #${bin.binNumber}',
          snippet: '${bin.fillPercentage ?? 0}% full',
        ),
      ),
    ]);

    final newMarker = newMarkers.whereType<Marker>().firstOrNull;
    if (newMarker != null) {
      // Update all lookups with the new marker
      _markerToBin.remove(markerId);
      _markerObjects.remove(markerId);

      _markerToBin[newMarker.markerId] = bin;
      _binToMarkerId[bin.id] = newMarker.markerId;
      _markerObjects[newMarker.markerId] = newMarker;
    }
  }

  /// Replace marker with normal (non-selected) icon
  Future<void> _swapToNormalIcon(String markerId, Bin bin) async {
    if (_controller == null) return;

    final oldMarker = _markerObjects[markerId];
    if (oldMarker == null) return;

    final normalIcon = await GoogleNavigationMarkerService.createBinMarkerIcon(
      bin.binNumber,
      bin.fillPercentage ?? 0,
    );

    await _controller!.removeMarkers([oldMarker]);

    final newMarkers = await _controller!.addMarkers([
      MarkerOptions(
        position: LatLng(
          latitude: bin.latitude!,
          longitude: bin.longitude!,
        ),
        icon: normalIcon,
        anchor: const MarkerAnchor(u: 0.5, v: 0.5),
        zIndex: 9999.0,
        infoWindow: InfoWindow(
          title: 'Bin #${bin.binNumber}',
          snippet: '${bin.fillPercentage ?? 0}% full',
        ),
      ),
    ]);

    final newMarker = newMarkers.whereType<Marker>().firstOrNull;
    if (newMarker != null) {
      _markerToBin.remove(markerId);
      _markerObjects.remove(markerId);

      _markerToBin[newMarker.markerId] = bin;
      _binToMarkerId[bin.id] = newMarker.markerId;
      _markerObjects[newMarker.markerId] = newMarker;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Single Bin Map Preview (read-only)
// ═══════════════════════════════════════════════════════════════

/// Map preview showing a single bin marker
class _MapPreview extends StatelessWidget {
  final Bin bin;
  final VoidCallback onBack;

  const _MapPreview({
    super.key,
    required this.bin,
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
                      'Bin #${bin.binNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${bin.currentStreet}, ${bin.city}',
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
              _FillBadge(fillPercentage: bin.fillPercentage ?? 0),
            ],
          ),
        ),
        // Map
        Expanded(
          child: GoogleMapsMapView(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                latitude: bin.latitude ?? 0,
                longitude: bin.longitude ?? 0,
              ),
              zoom: 16,
            ),
            initialMapType: MapType.normal,
            initialZoomControlsEnabled: false,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
            },
            onViewCreated: (controller) async {
              await _addMarker(controller);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addMarker(GoogleMapViewController controller) async {
    if (bin.latitude == null || bin.longitude == null) return;

    final icon = await GoogleNavigationMarkerService.createBinMarkerIcon(
      bin.binNumber,
      bin.fillPercentage ?? 0,
    );

    await controller.addMarkers([
      MarkerOptions(
        position: LatLng(
          latitude: bin.latitude!,
          longitude: bin.longitude!,
        ),
        icon: icon,
        anchor: const MarkerAnchor(u: 0.5, v: 0.5),
        zIndex: 9999.0,
        infoWindow: InfoWindow(
          title: 'Bin #${bin.binNumber}',
          snippet: '${bin.address} - ${bin.fillPercentage ?? 0}% full',
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared Widgets
// ═══════════════════════════════════════════════════════════════

/// Bin card with checkbox, fill indicator, and map button
class _BinCard extends StatelessWidget {
  final Bin bin;
  final bool isSelected;
  final bool isAlreadyInShift;
  final VoidCallback? onTap;
  final VoidCallback onViewMap;

  const _BinCard({
    required this.bin,
    required this.isSelected,
    required this.isAlreadyInShift,
    required this.onTap,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoords = bin.latitude != null && bin.longitude != null;
    final fill = bin.fillPercentage ?? 0;

    return Opacity(
      opacity: isAlreadyInShift ? 0.5 : 1.0,
      child: Material(
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
                      color: isAlreadyInShift
                          ? Colors.grey.shade300
                          : isSelected
                              ? AppColors.primaryGreen
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isAlreadyInShift
                            ? Colors.grey.shade300
                            : isSelected
                                ? AppColors.primaryGreen
                                : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isAlreadyInShift
                        ? Icon(Icons.check,
                            size: 16, color: Colors.grey.shade500)
                        : isSelected
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Bin icon
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Bin # + fill badge + status badges
                      Row(
                        children: [
                          Text(
                            'Bin #${bin.binNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _FillBadge(fillPercentage: fill),
                          if (bin.status == BinStatus.missing) ...[
                            const SizedBox(width: 4),
                            _Badge(
                              label: 'MISSING',
                              color: Colors.red.shade600,
                            ),
                          ],
                          if (isAlreadyInShift) ...[
                            const SizedBox(width: 4),
                            _Badge(
                              label: 'IN SHIFT',
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Row 2: Address
                      Text(
                        bin.currentStreet,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Row 3: City, Zip
                      Text(
                        '${bin.city}, ${bin.zip}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      if (bin.moveRequested) ...[
                        const SizedBox(height: 6),
                        _Badge(
                          label: 'MOVE REQ. PENDING',
                          color: Colors.amber.shade700,
                        ),
                      ],
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
      ),
    );
  }
}

/// Fill percentage badge with color coding
class _FillBadge extends StatelessWidget {
  final int fillPercentage;

  const _FillBadge({required this.fillPercentage});

  @override
  Widget build(BuildContext context) {
    final color = _fillColor(fillPercentage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$fillPercentage%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _fillColor(int fill) {
    if (fill >= 80) return Colors.red.shade600;
    if (fill >= 50) return Colors.orange.shade600;
    if (fill >= 25) return Colors.amber.shade700;
    return Colors.green.shade600;
  }
}

/// Small colored badge
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Filter chip
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
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected ? null : Border.all(color: Colors.grey.shade300),
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
