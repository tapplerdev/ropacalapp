import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/services/manager_service.dart';

/// Reusable map preview widget supporting two modes:
/// - **Route mode**: Two markers + animated OSRM polyline (when destLat/destLng provided)
/// - **Single-pin mode**: One marker, no polyline (when destLat/destLng are null)
class RouteMapPreview extends StatefulWidget {
  /// Origin coordinates (required)
  final double originLat;
  final double originLng;

  /// Destination coordinates (optional — null = single-pin mode)
  final double? destLat;
  final double? destLng;

  /// Bin number for the pickup marker icon (route mode)
  final int? binNumber;

  /// Move type: 'store', 'relocation', 'redeployment' (affects destination marker icon)
  final String? moveType;

  /// Whether the destination is a potential location (orange pin vs red pin)
  final String? sourcePotentialLocationId;

  /// ManagerService for fetching OSRM directions (only needed in route mode)
  final ManagerService? managerService;

  /// Fixed height of the map container
  final double height;

  /// Whether to show the legend row below the map
  final bool showLegend;

  /// When true, map fills all available vertical space (use inside Expanded)
  final bool isExpanded;

  /// Marker type in single-pin mode: 'potential_location' or 'bin'
  final String singlePinType;

  const RouteMapPreview({
    super.key,
    required this.originLat,
    required this.originLng,
    this.destLat,
    this.destLng,
    this.binNumber,
    this.moveType,
    this.sourcePotentialLocationId,
    this.managerService,
    this.height = 180,
    this.showLegend = true,
    this.isExpanded = false,
    this.singlePinType = 'potential_location',
  });

  @override
  State<RouteMapPreview> createState() => _RouteMapPreviewState();
}

class _RouteMapPreviewState extends State<RouteMapPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawController;
  GoogleMapViewController? _mapController;

  // Road-following coordinates from OSRM
  List<LatLng> _routePoints = [];

  static const _polylineColor = Color(0xFF1E88E5); // Blue 600

  bool get _isRouteMode =>
      widget.destLat != null && widget.destLng != null;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _drawController.addListener(_onDrawTick);

    if (_isRouteMode) {
      _fetchDirections();
    }
  }

  @override
  void dispose() {
    _drawController.removeListener(_onDrawTick);
    _drawController.dispose();
    super.dispose();
  }

  /// Fetch road-following directions from backend (OSRM)
  Future<void> _fetchDirections() async {
    if (widget.managerService == null) return;

    final coords = await widget.managerService!.getDirections(
      originLat: widget.originLat,
      originLng: widget.originLng,
      destLat: widget.destLat!,
      destLng: widget.destLng!,
    );

    if (!mounted) return;

    _routePoints = coords
        .map((c) => LatLng(
              latitude: (c['latitude'] as num).toDouble(),
              longitude: (c['longitude'] as num).toDouble(),
            ))
        .toList();

    // If map is already ready, start drawing
    if (_mapController != null) {
      _drawController.forward();
    }
  }

  void _onDrawTick() {
    final controller = _mapController;
    if (controller == null || _routePoints.isEmpty) return;

    final t = _drawController.value;
    final pointCount =
        (t * _routePoints.length).ceil().clamp(1, _routePoints.length);
    final visiblePoints = _routePoints.sublist(0, pointCount);

    controller.clearPolylines();
    controller.addPolylines([
      PolylineOptions(
        points: visiblePoints,
        strokeColor: _polylineColor,
        strokeWidth: 4,
        visible: true,
        zIndex: 100,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final centerLat = _isRouteMode
        ? (widget.originLat + widget.destLat!) / 2
        : widget.originLat;
    final centerLng = _isRouteMode
        ? (widget.originLng + widget.destLng!) / 2
        : widget.originLng;
    final zoom = _isRouteMode
        ? _calculateZoom(
            widget.originLat, widget.originLng, widget.destLat!, widget.destLng!)
        : 15.0;

    final mapView = GoogleMapsMapView(
      initialCameraPosition: CameraPosition(
        target: LatLng(latitude: centerLat, longitude: centerLng),
        zoom: zoom,
      ),
      initialMapType: MapType.normal,
      initialZoomControlsEnabled: false,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      onViewCreated: (controller) async {
        _mapController = controller;
        if (_isRouteMode) {
          await _addRouteMarkers(controller);
          if (_routePoints.isNotEmpty) {
            _drawController.forward();
          }
        } else {
          await _addSingleMarker(controller);
        }
      },
    );

    // Wrap map in either Expanded (for full-screen) or fixed-height SizedBox
    final mapContainer = widget.isExpanded
        ? Expanded(child: mapView)
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(height: widget.height, child: mapView),
          );

    return Column(
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        mapContainer,
        if (widget.showLegend && _isRouteMode) _buildLegend(),
      ],
    );
  }

  /// Add markers for route mode (pickup + destination)
  Future<void> _addRouteMarkers(GoogleMapViewController controller) async {
    final markerOptions = <MarkerOptions>[];

    // 1. Pickup marker (bin at current location)
    final pickupIcon =
        await GoogleNavigationMarkerService.createBinMarkerIcon(
      widget.binNumber ?? 0,
      0,
    );
    markerOptions.add(
      MarkerOptions(
        position: LatLng(
            latitude: widget.originLat, longitude: widget.originLng),
        icon: pickupIcon,
        anchor: const MarkerAnchor(u: 0.5, v: 0.5),
        zIndex: 9999.0,
        infoWindow: InfoWindow(
          title: 'Pickup: Bin #${widget.binNumber ?? "?"}',
          snippet: 'Current location',
        ),
      ),
    );

    // 2. Destination marker — varies by move type and source
    final moveType = widget.moveType ?? 'relocation';
    final bool isStore = moveType == 'store';
    final bool hasPotentialLocation =
        widget.sourcePotentialLocationId != null &&
            widget.sourcePotentialLocationId!.isNotEmpty;

    late final ImageDescriptor destIcon;
    late final MarkerAnchor destAnchor;
    late final String destSnippet;

    if (isStore) {
      destIcon =
          await GoogleNavigationMarkerService.createWarehouseMarkerIcon();
      destAnchor = const MarkerAnchor(u: 0.5, v: 0.5);
      destSnippet = 'Warehouse Storage';
    } else if (hasPotentialLocation) {
      destIcon = await GoogleNavigationMarkerService
          .createPotentialLocationMarkerIcon(
        isPending: true,
        withPulse: false,
      );
      destAnchor = const MarkerAnchor(u: 0.5, v: 1.0);
      destSnippet = 'Potential Location';
    } else {
      destIcon =
          await GoogleNavigationMarkerService.createDestinationMarkerIcon();
      destAnchor = const MarkerAnchor(u: 0.5, v: 1.0);
      destSnippet = 'Manual Address';
    }

    markerOptions.add(
      MarkerOptions(
        position:
            LatLng(latitude: widget.destLat!, longitude: widget.destLng!),
        icon: destIcon,
        anchor: destAnchor,
        zIndex: 9998.0,
        infoWindow: InfoWindow(
          title: 'Dropoff',
          snippet: destSnippet,
        ),
      ),
    );

    await controller.addMarkers(markerOptions);
  }

  /// Add a single marker for single-pin mode
  Future<void> _addSingleMarker(GoogleMapViewController controller) async {
    late final ImageDescriptor icon;
    late final MarkerAnchor anchor;

    if (widget.singlePinType == 'potential_location') {
      icon = await GoogleNavigationMarkerService
          .createPotentialLocationMarkerIcon(
        isPending: true,
        withPulse: false,
      );
      anchor = const MarkerAnchor(u: 0.5, v: 1.0);
    } else {
      // bin type
      icon = await GoogleNavigationMarkerService.createBinMarkerIcon(
        widget.binNumber ?? 0,
        0,
      );
      anchor = const MarkerAnchor(u: 0.5, v: 0.5);
    }

    await controller.addMarkers([
      MarkerOptions(
        position: LatLng(
            latitude: widget.originLat, longitude: widget.originLng),
        icon: icon,
        anchor: anchor,
        zIndex: 9999.0,
      ),
    ]);
  }

  Widget _buildLegend() {
    final moveType = widget.moveType ?? 'relocation';
    final bool isStore = moveType == 'store';
    final bool hasPotentialLocation =
        widget.sourcePotentialLocationId != null &&
            widget.sourcePotentialLocationId!.isNotEmpty;

    IconData destIconData;
    Color destColor;
    String destLabel;

    if (isStore) {
      destIconData = Icons.warehouse;
      destColor = const Color(0xFF9C27B0);
      destLabel = 'Warehouse';
    } else if (hasPotentialLocation) {
      destIconData = Icons.location_on;
      destColor = const Color(0xFFFF9500);
      destLabel = 'Potential Location';
    } else {
      destIconData = Icons.location_on;
      destColor = const Color(0xFFE53935);
      destLabel = 'Destination';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Pickup',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Container(width: 10, height: 3, color: _polylineColor),
          const SizedBox(width: 6),
          Text(
            'Route',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Icon(destIconData, size: 14, color: destColor),
          const SizedBox(width: 4),
          Text(
            destLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  double _calculateZoom(
      double lat1, double lng1, double lat2, double lng2) {
    final latDiff = (lat1 - lat2).abs();
    final lngDiff = (lng1 - lng2).abs();
    final maxDiff = max(latDiff, lngDiff);

    if (maxDiff < 0.005) return 16;
    if (maxDiff < 0.01) return 15;
    if (maxDiff < 0.03) return 14;
    if (maxDiff < 0.06) return 13;
    if (maxDiff < 0.12) return 12;
    if (maxDiff < 0.25) return 11;
    if (maxDiff < 0.5) return 10;
    return 9;
  }
}
