import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/services/geocoding_service.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/features/driver/widgets/circular_map_button.dart';
import 'package:ropacalapp/core/widgets/here_places_autocomplete_field.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/potential_location_provider.dart';
import 'package:ropacalapp/providers/warehouse_provider.dart';
// Keep import for rollback to dialog approach
// ignore: unused_import
import 'package:ropacalapp/features/driver/widgets/potential_location_form_dialog.dart';

/// Fullscreen map page for picking a potential location via a centered pin.
/// The user drags the map to position the pin, then confirms via bottom sheet form.
///
/// When [returnLocationOnly] is true, the page returns a Map with
/// {street, city, zip, latitude, longitude} instead of creating a potential location.
class LocationPickerPage extends HookConsumerWidget {
  final bool returnLocationOnly;
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerPage({
    super.key,
    this.returnLocationOnly = false,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Warehouse location as fallback (instead of hardcoded Dallas)
    final warehouseAsync = ref.watch(warehouseLocationNotifierProvider);
    final warehouseLat = warehouseAsync.valueOrNull?.latitude ?? 32.886534;
    final warehouseLng = warehouseAsync.valueOrNull?.longitude ?? -96.7642497;

    final mapController = useState<GoogleMapViewController?>(null);
    final isMapMoving = useState(false);
    final currentAddress = useState<String?>(null);
    final isGeocoding = useState(false);
    final initialLat = initialLatitude ?? warehouseLat;
    final initialLng = initialLongitude ?? warehouseLng;
    final hasInitialCoords = initialLatitude != null && initialLongitude != null;
    final centerLat = useState<double>(initialLat);
    final centerLng = useState<double>(initialLng);
    final geocodeTimer = useRef<Timer?>(null);

    // Reverse-geocoded address components (for form pre-fill)
    final geoStreet = useState('');
    final geoCity = useState('');
    final geoZip = useState('');

    // Search bar
    final searchController = useTextEditingController();
    final searchFocusNode = useFocusNode();

    // Get initial GPS position (skip if initial coords were provided)
    useEffect(() {
      if (hasInitialCoords) {
        // Reverse geocode the provided coordinates
        _reverseGeocode(
          initialLat,
          initialLng,
          currentAddress,
          isGeocoding,
          geoStreet,
          geoCity,
          geoZip,
        );
        return null;
      }

      final locationService = ref.read(locationServiceProvider);
      locationService.getCurrentLocation().then((pos) {
        if (pos != null) {
          centerLat.value = pos.latitude;
          centerLng.value = pos.longitude;

          final ctrl = mapController.value;
          if (ctrl != null) {
            ctrl.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(
                    latitude: pos.latitude,
                    longitude: pos.longitude,
                  ),
                  zoom: 16,
                ),
              ),
            );
          }

          _reverseGeocode(
            pos.latitude,
            pos.longitude,
            currentAddress,
            isGeocoding,
            geoStreet,
            geoCity,
            geoZip,
          );
        }
      });
      return null;
    }, []);

    // Cleanup timer on dispose
    useEffect(() {
      return () => geocodeTimer.value?.cancel();
    }, []);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // === MAP LAYER ===
          Listener(
            onPointerDown: (_) {
              isMapMoving.value = true;
              geocodeTimer.value?.cancel();
            },
            onPointerUp: (_) {
              isMapMoving.value = false;
              geocodeTimer.value = Timer(
                const Duration(milliseconds: 400),
                () async {
                  final ctrl = mapController.value;
                  if (ctrl == null) return;
                  final camPos = await ctrl.getCameraPosition();
                  centerLat.value = camPos.target.latitude;
                  centerLng.value = camPos.target.longitude;
                  _reverseGeocode(
                    camPos.target.latitude,
                    camPos.target.longitude,
                    currentAddress,
                    isGeocoding,
                    geoStreet,
                    geoCity,
                    geoZip,
                  );
                },
              );
            },
            child: GoogleMapsMapView(
              key: const ValueKey('location_picker_map'),
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  latitude: centerLat.value,
                  longitude: centerLng.value,
                ),
                zoom: 16,
              ),
              initialMapType: MapType.normal,
              initialZoomControlsEnabled: false,
              onViewCreated: (GoogleMapViewController controller) async {
                mapController.value = controller;
                await controller.setMyLocationEnabled(true);
                await controller.settings.setMyLocationButtonEnabled(false);
                AppLogger.general('LocationPickerPage map created');
              },
            ),
          ),

          // === CENTER PIN OVERLAY ===
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.translationValues(
                  0,
                  isMapMoving.value ? -8 : 0,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_pin,
                      size: 48,
                      color: isMapMoving.value
                          ? Colors.red.shade700
                          : Colors.red,
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isMapMoving.value ? 6 : 4,
                      height: isMapMoving.value ? 3 : 2,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === TOP BAR: Back button + Search ===
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: HerePlacesAutocompleteField(
                        textEditingController: searchController,
                        focusNode: searchFocusNode,
                        debounceTime: 500,
                        inputDecoration: InputDecoration(
                          hintText: 'Search address',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        textStyle: const TextStyle(fontSize: 14),
                        // Compact dropdown items
                        itemBuilder: (context, index, suggestion) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.green[600],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            suggestion.title,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (suggestion.address != null) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              suggestion.address!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        onPlaceSelected: (HerePlaceSelection place) {
                          searchFocusNode.unfocus();
                          final lat = double.tryParse(place.latitude);
                          final lng = double.tryParse(place.longitude);
                          if (lat != null && lng != null) {
                            centerLat.value = lat;
                            centerLng.value = lng;
                            geoStreet.value = place.street;
                            geoCity.value = place.city;
                            geoZip.value = place.zip;
                            currentAddress.value =
                                place.formattedAddress.isNotEmpty
                                    ? place.formattedAddress
                                    : '${place.street}, ${place.city}';

                            mapController.value?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(
                                    latitude: lat,
                                    longitude: lng,
                                  ),
                                  zoom: 17,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === MY LOCATION BUTTON ===
          Positioned(
            bottom: 280,
            right: 16,
            child: CircularMapButton(
              icon: Icons.my_location,
              backgroundColor: AppColors.primaryGreen,
              iconColor: Colors.white,
              onTap: () async {
                final locationService = ref.read(locationServiceProvider);
                final pos = await locationService.getCurrentLocation();
                if (pos != null) {
                  centerLat.value = pos.latitude;
                  centerLng.value = pos.longitude;

                  mapController.value?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(
                          latitude: pos.latitude,
                          longitude: pos.longitude,
                        ),
                        zoom: 17,
                      ),
                    ),
                  );

                  _reverseGeocode(
                    pos.latitude,
                    pos.longitude,
                    currentAddress,
                    isGeocoding,
                    geoStreet,
                    geoCity,
                    geoZip,
                  );
                }
              },
            ),
          ),

          // === BOTTOM ADDRESS CARD ===
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Address row with coordinates
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Colors.green[700],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pin Location',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                if (isGeocoding.value)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Colors.green[600],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Looking up address...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    currentAddress.value ??
                                        'Move the map to set location',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: currentAddress.value != null
                                          ? Colors.black87
                                          : Colors.grey[400],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (currentAddress.value != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    '${centerLat.value.toStringAsFixed(6)}, ${centerLng.value.toStringAsFixed(6)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: currentAddress.value == null
                              ? null
                              : () {
                                  if (returnLocationOnly) {
                                    Navigator.of(context).pop(<String, dynamic>{
                                      'street': geoStreet.value,
                                      'city': geoCity.value,
                                      'zip': geoZip.value,
                                      'latitude': centerLat.value,
                                      'longitude': centerLng.value,
                                    });
                                  } else {
                                    _showConfirmSheet(
                                      context,
                                      ref,
                                      street: geoStreet.value,
                                      city: geoCity.value,
                                      zip: geoZip.value,
                                      latitude: centerLat.value,
                                      longitude: centerLng.value,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            returnLocationOnly ? 'Select Location' : 'Confirm Location',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // ─── OLD DIALOG APPROACH (commented out for rollback) ───
                        // child: ElevatedButton(
                        //   onPressed: currentAddress.value == null
                        //       ? null
                        //       : () async {
                        //           final result = await showDialog<bool>(
                        //             context: context,
                        //             builder: (context) =>
                        //                 PotentialLocationFormDialog(
                        //               initialLatitude: centerLat.value,
                        //               initialLongitude: centerLng.value,
                        //             ),
                        //           );
                        //           if (result == true && context.mounted) {
                        //             Navigator.of(context).pop(true);
                        //           }
                        //         },
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: Colors.green[600],
                        //     foregroundColor: Colors.white,
                        //     disabledBackgroundColor: Colors.grey[300],
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(14),
                        //     ),
                        //     elevation: 0,
                        //   ),
                        //   child: const Text(
                        //     'Confirm Location',
                        //     style: TextStyle(
                        //       fontSize: 15,
                        //       fontWeight: FontWeight.w600,
                        //     ),
                        //   ),
                        // ),
                        // ─── END OLD DIALOG APPROACH ───
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show native bottom sheet with the confirm/submit form
  static void _showConfirmSheet(
    BuildContext context,
    WidgetRef ref, {
    required String street,
    required String city,
    required String zip,
    required double latitude,
    required double longitude,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ConfirmLocationSheet(
        street: street,
        city: city,
        zip: zip,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  /// Reverse geocode coordinates — stores both display string and components
  static Future<void> _reverseGeocode(
    double lat,
    double lng,
    ValueNotifier<String?> addressState,
    ValueNotifier<bool> loadingState,
    ValueNotifier<String> streetState,
    ValueNotifier<String> cityState,
    ValueNotifier<String> zipState,
  ) async {
    loadingState.value = true;
    try {
      final result = await GeocodingService.hereReverseGeocode(
        latitude: lat,
        longitude: lng,
      );
      if (result != null) {
        final s = result['street'] ?? '';
        final c = result['city'] ?? '';
        final z = result['zip'] ?? '';
        streetState.value = s;
        cityState.value = c;
        zipState.value = z;
        addressState.value = [s, c, z]
            .where((v) => v.isNotEmpty)
            .join(', ');
      } else {
        addressState.value = 'Unknown location';
      }
    } catch (e) {
      AppLogger.e('Reverse geocoding error', error: e);
      addressState.value = 'Could not determine address';
    } finally {
      loadingState.value = false;
    }
  }
}

/// Native modal bottom sheet with the form fields for confirming a location.
/// Uses its own ConsumerWidget so it can listen to the provider state.
class _ConfirmLocationSheet extends HookConsumerWidget {
  final String street;
  final String city;
  final String zip;
  final double latitude;
  final double longitude;

  const _ConfirmLocationSheet({
    required this.street,
    required this.city,
    required this.zip,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final streetController = useTextEditingController(text: street);
    final cityController = useTextEditingController(text: city);
    final zipController = useTextEditingController(text: zip);
    final notesController = useTextEditingController();

    final potentialLocationState = ref.watch(potentialLocationNotifierProvider);

    // Listen for success/error
    ref.listen(
      potentialLocationNotifierProvider,
      (previous, next) {
        next.whenOrNull(
          data: (_) {
            if (previous is AsyncLoading) {
              ref.read(potentialLocationNotifierProvider.notifier).reset();
              // Close the bottom sheet
              Navigator.of(context).pop();
              // Show success snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Location suggestion submitted!',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              // Pop the LocationPickerPage too
              Navigator.of(context).pop(true);
            }
          },
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Error: $error')),
                  ],
                ),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        );
      },
    );

    return Padding(
      // Push above keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: Colors.green[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Confirm Details',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Text(
                              'Verify the address and add notes',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Coordinates aligned right
                      Text(
                        '${latitude.toStringAsFixed(6)},\n${longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Street
                  _buildFormField(
                    controller: streetController,
                    label: 'Street',
                    icon: Icons.signpost_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),

                  // City + ZIP
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildFormField(
                          controller: cityController,
                          label: 'City',
                          icon: Icons.location_city_outlined,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _buildFormField(
                          controller: zipController,
                          label: 'ZIP',
                          icon: Icons.pin_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Notes
                  _buildFormField(
                    controller: notesController,
                    label: 'Notes (optional)',
                    icon: Icons.note_alt_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: potentialLocationState.isLoading
                          ? null
                          : () {
                              if (formKey.currentState!.validate()) {
                                ref
                                    .read(
                                      potentialLocationNotifierProvider
                                          .notifier,
                                    )
                                    .createPotentialLocation(
                                      street: streetController.text.trim(),
                                      city: cityController.text.trim(),
                                      zip: zipController.text.trim(),
                                      latitude: latitude,
                                      longitude: longitude,
                                      notes: notesController.text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : notesController.text.trim(),
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: potentialLocationState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Submit Location',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
        prefixIcon: Icon(icon, size: 18, color: Colors.green[600]),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[400]!, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        isDense: true,
      ),
    );
  }
}
