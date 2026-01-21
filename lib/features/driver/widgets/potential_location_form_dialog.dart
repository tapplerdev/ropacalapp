import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/services/geocoding_service.dart';
import 'package:ropacalapp/providers/potential_location_provider.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:google_places_flutter/model/place_type.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Modern dialog for creating a new potential location request
class PotentialLocationFormDialog extends HookConsumerWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const PotentialLocationFormDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final streetController = useTextEditingController();
    final cityController = useTextEditingController();
    final zipController = useTextEditingController();
    final notesController = useTextEditingController();
    final streetFocusNode = useFocusNode();

    final isReverseGeocoding = useState(false);
    final reverseGeocodingError = useState<String?>(null);

    final potentialLocationState =
        ref.watch(potentialLocationNotifierProvider);

    // Reverse geocode on mount if coordinates provided
    useEffect(
      () {
        if (initialLatitude != null && initialLongitude != null) {
          isReverseGeocoding.value = true;
          reverseGeocodingError.value = null;

          GeocodingService.reverseGeocode(
            latitude: initialLatitude!,
            longitude: initialLongitude!,
          ).then((result) {
            isReverseGeocoding.value = false;

            if (result != null) {
              streetController.text = result['street'] ?? '';
              cityController.text = result['city'] ?? '';
              zipController.text = result['zip'] ?? '';
            } else {
              reverseGeocodingError.value =
                  'Could not determine address. Please enter manually.';
            }
          }).catchError((error) {
            isReverseGeocoding.value = false;
            reverseGeocodingError.value = 'Error: $error';
            AppLogger.e('Reverse geocoding error', error: error);
          });
        }
        return null;
      },
      [],
    );

    // Handle success
    ref.listen(
      potentialLocationNotifierProvider,
      (previous, next) {
        next.whenOrNull(
          data: (_) {
            if (previous is AsyncLoading) {
              Navigator.of(context).pop();
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
              ref.read(potentialLocationNotifierProvider.notifier).reset();
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggest Location',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Help us expand our service',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // GPS Info Banner - Compact
                      if (initialLatitude != null && initialLongitude != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue[400]!.withValues(alpha: 0.15),
                                Colors.blue[300]!.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blue[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue[600],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.gps_fixed,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Using GPS Location',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                    Text(
                                      '${initialLatitude!.toStringAsFixed(4)}, '
                                      '${initialLongitude!.toStringAsFixed(4)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (initialLatitude != null && initialLongitude != null)
                        const SizedBox(height: 20),

                      // Reverse Geocoding Loading
                      if (isReverseGeocoding.value)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.green[600]!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Finding address...',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Reverse Geocoding Error
                      if (reverseGeocodingError.value != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange[700],
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  reverseGeocodingError.value!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (isReverseGeocoding.value ||
                          reverseGeocodingError.value != null)
                        const SizedBox(height: 20),

                      // Form fields with modern design
                      // Google Places Autocomplete for Street Address
                      _buildAutocompleteField(
                        controller: streetController,
                        cityController: cityController,
                        zipController: zipController,
                        focusNode: streetFocusNode,
                        enabled: !isReverseGeocoding.value,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildModernTextField(
                              controller: cityController,
                              label: 'City',
                              hint: 'Dallas',
                              icon: Icons.location_city,
                              enabled: !isReverseGeocoding.value,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildModernTextField(
                              controller: zipController,
                              label: 'ZIP Code',
                              hint: '75206',
                              icon: Icons.pin,
                              keyboardType: TextInputType.number,
                              enabled: !isReverseGeocoding.value,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildModernTextField(
                        controller: notesController,
                        label: 'Additional Notes',
                        hint: 'Landlord request, 3 tenants, etc.',
                        icon: Icons.note_alt_outlined,
                        maxLines: 3,
                        enabled: !isReverseGeocoding.value,
                        isOptional: true,
                      ),
                      const SizedBox(height: 28),

                      // Modern action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: potentialLocationState.isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: potentialLocationState.isLoading ||
                                      isReverseGeocoding.value
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        await ref
                                            .read(
                                              potentialLocationNotifierProvider
                                                  .notifier,
                                            )
                                            .createPotentialLocation(
                                              street:
                                                  streetController.text.trim(),
                                              city: cityController.text.trim(),
                                              zip: zipController.text.trim(),
                                              latitude: initialLatitude,
                                              longitude: initialLongitude,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                disabledBackgroundColor: Colors.grey[300],
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Submit Location',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required TextEditingController cityController,
    required TextEditingController zipController,
    required FocusNode focusNode,
    required bool enabled,
  }) {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Street Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GooglePlaceAutoCompleteTextField(
            textEditingController: controller,
            googleAPIKey: apiKey,
            focusNode: focusNode,
            inputDecoration: InputDecoration(
              hintText: 'Start typing address...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.green[600],
                size: 22,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            debounceTime: 600,
            countries: const ['us'],
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (Prediction prediction) async {
              // Parse the place details and auto-fill form fields
              AppLogger.general(
                'Place selected: ${prediction.description}',
              );
              AppLogger.general(
                'Lat: ${prediction.lat}, Lng: ${prediction.lng}',
              );

              // Update controllers with parsed address components
              if (prediction.structuredFormatting != null) {
                final mainText =
                    prediction.structuredFormatting!.mainText ?? '';
                final secondaryText =
                    prediction.structuredFormatting!.secondaryText ?? '';

                // Set street address from main text
                controller.text = mainText;

                // Parse city from secondary text (first part)
                final parts = secondaryText.split(',');
                if (parts.isNotEmpty) {
                  cityController.text = parts[0].trim();
                }

                // Try to extract ZIP code from full description first
                final fullDesc = prediction.description ?? '';
                final zipMatch = RegExp(r'\b\d{5}(?:-\d{4})?\b')
                    .firstMatch(fullDesc);

                if (zipMatch != null) {
                  // Found ZIP in description
                  zipController.text = zipMatch.group(0)!.split('-')[0];
                  AppLogger.general(
                    'ZIP found in description: ${zipController.text}',
                  );
                } else if (prediction.lat != null &&
                    prediction.lng != null) {
                  // Fallback: Use reverse geocoding to get ZIP
                  AppLogger.general(
                    'No ZIP in description, using reverse geocoding',
                  );
                  try {
                    final geocodeResult = await GeocodingService.reverseGeocode(
                      latitude: double.parse(prediction.lat!),
                      longitude: double.parse(prediction.lng!),
                    );
                    if (geocodeResult != null &&
                        geocodeResult['zip'] != null) {
                      zipController.text = geocodeResult['zip']!;
                      AppLogger.general(
                        'ZIP from geocoding: ${zipController.text}',
                      );
                    }
                  } catch (e) {
                    AppLogger.e('Error reverse geocoding', error: e);
                  }
                }
              }
            },
            itemClick: (Prediction prediction) {
              // This is called when user clicks on a suggestion
              AppLogger.general(
                'Item clicked - Description: ${prediction.description}',
              );
              AppLogger.general(
                'Main text: ${prediction.structuredFormatting?.mainText}',
              );
              AppLogger.general(
                'Secondary: ${prediction.structuredFormatting?.secondaryText}',
              );

              // Parse and auto-fill all fields
              if (prediction.structuredFormatting != null) {
                final mainText =
                    prediction.structuredFormatting!.mainText ?? '';
                final secondaryText =
                    prediction.structuredFormatting!.secondaryText ?? '';

                // Set street address from main text
                controller.text = mainText;
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );

                // Parse city from secondary text (first part before comma)
                final parts = secondaryText.split(',');
                if (parts.isNotEmpty) {
                  cityController.text = parts[0].trim();
                }

                // Try to extract ZIP from full description
                // Description format: "Street, City, State ZIP, Country"
                final fullDesc = prediction.description ?? '';
                final zipMatch = RegExp(r'\b\d{5}(?:-\d{4})?\b')
                    .firstMatch(fullDesc);
                if (zipMatch != null) {
                  zipController.text = zipMatch.group(0)!.split('-')[0];
                }
              } else {
                // Fallback: full description if no structured formatting
                controller.text = prediction.description ?? '';
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              }
            },
            // Beautiful dropdown container styling
            boxDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                  spreadRadius: -5,
                ),
              ],
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            // Elegant dividers between items
            seperatedBuilder: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            containerHorizontalPadding: 10,
            containerVerticalPadding: 8,
            // Modern item styling with hover effect
            itemBuilder: (context, index, Prediction prediction) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 200 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 10 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green[400]!,
                                    Colors.green[600]!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.green.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prediction.structuredFormatting?.mainText ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (prediction.structuredFormatting
                                          ?.secondaryText !=
                                      null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      prediction
                                          .structuredFormatting!.secondaryText!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        letterSpacing: -0.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            isCrossBtnShown: true,
            placeType: PlaceType.address,
          ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (isOptional) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            maxLines: maxLines,
            keyboardType: keyboardType,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: maxLines > 1
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12, left: 12),
                      child: Icon(icon, color: Colors.green[600], size: 22),
                    )
                  : Icon(icon, color: Colors.green[600], size: 22),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.green[600]!,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              errorStyle: const TextStyle(fontSize: 12, height: 0.8),
            ),
            validator: validator,
            textCapitalization: maxLines > 1
                ? TextCapitalization.sentences
                : TextCapitalization.words,
          ),
        ),
      ],
    );
  }
}
