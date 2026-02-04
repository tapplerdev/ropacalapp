import 'package:flutter/material.dart';
import 'package:ropacalapp/core/services/geocoding_service.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'dart:async';

/// HERE Maps autocomplete text field widget
/// Drop-in replacement for Google Places Autocomplete
class HerePlacesAutocompleteField extends StatefulWidget {
  final TextEditingController textEditingController;
  final FocusNode? focusNode;
  final InputDecoration? inputDecoration;
  final TextStyle? textStyle;
  final int debounceTime;
  final Function(HerePlaceSelection) onPlaceSelected;
  final BoxDecoration? boxDecoration;
  final Widget? seperatedBuilder;
  final double? containerHorizontalPadding;
  final double? containerVerticalPadding;
  final Widget Function(
    BuildContext context,
    int index,
    HereSuggestion suggestion,
  )? itemBuilder;
  final bool isCrossBtnShown;

  const HerePlacesAutocompleteField({
    super.key,
    required this.textEditingController,
    this.focusNode,
    this.inputDecoration,
    this.textStyle,
    this.debounceTime = 600,
    required this.onPlaceSelected,
    this.boxDecoration,
    this.seperatedBuilder,
    this.containerHorizontalPadding,
    this.containerVerticalPadding,
    this.itemBuilder,
    this.isCrossBtnShown = true,
  });

  @override
  State<HerePlacesAutocompleteField> createState() =>
      _HerePlacesAutocompleteFieldState();
}

class _HerePlacesAutocompleteFieldState
    extends State<HerePlacesAutocompleteField> {
  List<HereSuggestion> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOverlayVisible = false;
  bool _userHasTyped = false;  // Track if user has actually typed
  String _lastValue = '';  // Track last value to detect programmatic changes

  @override
  void initState() {
    super.initState();
    _lastValue = widget.textEditingController.text;
    widget.textEditingController.addListener(_onTextChanged);
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(_onTextChanged);
    widget.focusNode?.removeListener(_onFocusChanged);
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.textEditingController.text;

    // Detect if this is a user typing or programmatic change
    final hasFocus = widget.focusNode?.hasFocus ?? false;

    // If field has focus and text changed, user is typing
    if (hasFocus && query != _lastValue) {
      _userHasTyped = true;
    }

    // If text changed but field doesn't have focus, it's programmatic (auto-fill)
    if (!hasFocus && query != _lastValue) {
      _userHasTyped = false;
      _lastValue = query;
      _removeOverlay();
      return;
    }

    _lastValue = query;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      _removeOverlay();
      _userHasTyped = false;  // Reset when cleared
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    // Only show autocomplete if user has actually typed
    if (!_userHasTyped) {
      return;
    }

    if (query.length < 3) {
      return; // Don't search for queries less than 3 characters
    }

    setState(() {
      _isLoading = true;
    });

    _debounce = Timer(Duration(milliseconds: widget.debounceTime), () async {
      await _fetchSuggestions(query);
    });
  }

  void _onFocusChanged() {
    if (!(widget.focusNode?.hasFocus ?? true)) {
      // Delay removing overlay to allow item click
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !(widget.focusNode?.hasFocus ?? false)) {
          _removeOverlay();
        }
      });
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      AppLogger.general('🗺️ HERE AUTOCOMPLETE: Fetching suggestions for: $query');

      final results = await GeocodingService.hereAutosuggest(
        query: query,
        limit: 5,
      );

      final suggestions = results
          .map(
            (item) => HereSuggestion(
              id: item['id'] as String,
              title: item['title'] as String,
              address: item['address'] as String?,
            ),
          )
          .toList();

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });

        if (suggestions.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      AppLogger.e('Error fetching HERE suggestions', error: e);
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    if (_isOverlayVisible) {
      _overlayEntry?.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isOverlayVisible = true;
  }

  void _removeOverlay() {
    if (_isOverlayVisible) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isOverlayVisible = false;
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: widget.boxDecoration ??
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.containerHorizontalPadding ?? 10,
                  vertical: widget.containerVerticalPadding ?? 8,
                ),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) =>
                    widget.seperatedBuilder ??
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 1,
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];

                  if (widget.itemBuilder != null) {
                    return GestureDetector(
                      onTap: () => _onSuggestionTapped(suggestion),
                      child: widget.itemBuilder!(context, index, suggestion),
                    );
                  }

                  // Default item builder
                  return _buildDefaultItem(suggestion, index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultItem(HereSuggestion suggestion, int index) {
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
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onSuggestionTapped(suggestion),
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
                        colors: [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
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
                          suggestion.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (suggestion.address != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            suggestion.address!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
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
  }

  Future<void> _onSuggestionTapped(HereSuggestion suggestion) async {
    AppLogger.general('🗺️ HERE AUTOCOMPLETE: Place selected: ${suggestion.title}');

    // Close overlay immediately
    _removeOverlay();

    // Reset typing flag since user selected from dropdown
    _userHasTyped = false;
    _lastValue = suggestion.title;

    // Update text field
    widget.textEditingController.text = suggestion.title;

    // Fetch full place details
    try {
      final placeDetails = await GeocodingService.hereLookup(
        hereId: suggestion.id,
      );

      if (placeDetails != null) {
        final selection = HerePlaceSelection(
          street: placeDetails['street'] ?? '',
          city: placeDetails['city'] ?? '',
          zip: placeDetails['zip'] ?? '',
          state: placeDetails['state'] ?? '',
          latitude: placeDetails['latitude'] ?? '',
          longitude: placeDetails['longitude'] ?? '',
          formattedAddress: placeDetails['formattedAddress'] ?? '',
        );

        widget.onPlaceSelected(selection);
      }
    } catch (e) {
      AppLogger.e('Error fetching place details', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.textEditingController,
        focusNode: widget.focusNode,
        style: widget.textStyle,
        decoration: widget.inputDecoration,
      ),
    );
  }
}

/// HERE Maps suggestion model
class HereSuggestion {
  final String id;
  final String title;
  final String? address;

  HereSuggestion({
    required this.id,
    required this.title,
    this.address,
  });
}

/// HERE Maps place selection model
class HerePlaceSelection {
  final String street;
  final String city;
  final String zip;
  final String state;
  final String latitude;
  final String longitude;
  final String formattedAddress;

  HerePlaceSelection({
    required this.street,
    required this.city,
    required this.zip,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });
}
