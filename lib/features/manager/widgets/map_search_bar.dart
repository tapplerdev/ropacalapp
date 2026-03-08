import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/models/potential_location.dart';

/// Search result types
enum SearchResultType { driver, bin, location }

class MapSearchResult {
  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  final double? latitude;
  final double? longitude;

  const MapSearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    this.latitude,
    this.longitude,
  });
}

/// Floating search bar for the manager map
/// Green circular button that smoothly expands into a full-width search field
class MapSearchBar extends StatefulWidget {
  final List<ActiveDriver> drivers;
  final List<Bin> bins;
  final List<PotentialLocation> locations;
  final void Function(MapSearchResult result) onResultSelected;
  final ValueChanged<bool>? onExpandChanged;

  const MapSearchBar({
    super.key,
    required this.drivers,
    required this.bins,
    required this.locations,
    required this.onResultSelected,
    this.onExpandChanged,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<MapSearchResult> _results = [];

  // Expand/collapse animation
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  // Results slide animation
  late AnimationController _resultsController;
  late Animation<double> _resultsAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _resultsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _resultsAnimation = CurvedAnimation(
      parent: _resultsController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _expandController.dispose();
    _resultsController.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _isExpanded = true);
    widget.onExpandChanged?.call(true);
    _expandController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _collapse() {
    _focusNode.unfocus();
    widget.onExpandChanged?.call(false);
    _resultsController.reverse();
    _expandController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _results = [];
        });
        _controller.clear();
      }
    });
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      _resultsController.reverse();
      return;
    }

    final q = query.toLowerCase();
    final results = <MapSearchResult>[];

    // Search drivers
    for (final driver in widget.drivers) {
      if (driver.driverName.toLowerCase().contains(q)) {
        results.add(MapSearchResult(
          type: SearchResultType.driver,
          id: driver.driverId,
          title: driver.driverName,
          subtitle: driver.status.name,
          latitude: driver.currentLocation?.latitude,
          longitude: driver.currentLocation?.longitude,
        ));
      }
    }

    // Search bins
    for (final bin in widget.bins) {
      final binNum = '${bin.binNumber}';
      if (binNum.contains(q) ||
          bin.currentStreet.toLowerCase().contains(q) ||
          bin.city.toLowerCase().contains(q)) {
        results.add(MapSearchResult(
          type: SearchResultType.bin,
          id: bin.id,
          title: 'Bin #$binNum',
          subtitle: bin.address,
          latitude: bin.latitude,
          longitude: bin.longitude,
        ));
      }
    }

    // Search potential locations
    for (final loc in widget.locations) {
      if (loc.street.toLowerCase().contains(q) ||
          loc.city.toLowerCase().contains(q) ||
          loc.zip.contains(q)) {
        results.add(MapSearchResult(
          type: SearchResultType.location,
          id: loc.id,
          title: loc.street,
          subtitle: '${loc.city}, ${loc.zip}',
          latitude: loc.latitude,
          longitude: loc.longitude,
        ));
      }
    }

    setState(() => _results = results.take(8).toList());
    if (_results.isNotEmpty) {
      _resultsController.forward();
    } else {
      _resultsController.forward(); // Show "no results" too
    }
  }

  void _selectResult(MapSearchResult result) {
    widget.onResultSelected(result);
    _collapse();
  }

  IconData _iconForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.driver:
        return Icons.local_shipping;
      case SearchResultType.bin:
        return Icons.delete_outline;
      case SearchResultType.location:
        return Icons.add_location_alt;
    }
  }

  Color _colorForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.driver:
        return AppColors.primaryGreen;
      case SearchResultType.bin:
        return AppColors.brandBlueAccent;
      case SearchResultType.location:
        return AppColors.warningOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width - 32;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar — animates between circle (42px) and full-width pill
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final width = 42.0 + (fullWidth - 42.0) * _expandAnimation.value;
            final borderRadius = 22.0; // Stays pill-shaped throughout
            final bgColor = ColorTween(
              begin: AppColors.primaryGreen,
              end: Colors.white,
            ).evaluate(_expandAnimation)!;

            return Container(
              width: width,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: _expandAnimation.value < 0.5
                        ? AppColors.primaryGreen.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _expandAnimation.value < 0.3
                  // Show search icon only (collapsed state)
                  ? GestureDetector(
                      onTap: _expand,
                      child: const Center(
                        child: Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    )
                  // Show text field (expanding/expanded)
                  : Opacity(
                      opacity: ((_expandAnimation.value - 0.3) / 0.7)
                          .clamp(0.0, 1.0),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.search,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              onChanged: _search,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Search bins, drivers, locations...',
                                hintStyle: TextStyle(
                                  color: AppColors.iconGrey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _collapse,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.grey.shade600,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),

        // Animated results dropdown
        if (_isExpanded)
          SizeTransition(
            sizeFactor: _resultsAnimation,
            axisAlignment: -1.0,
            child: _controller.text.isNotEmpty
                ? _results.isNotEmpty
                    ? _buildResultsList(fullWidth)
                    : _buildNoResults(fullWidth)
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildResultsList(double width) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: width,
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: _results.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 60,
            color: Colors.grey.shade100,
          ),
          itemBuilder: (context, index) {
            final r = _results[index];
            final color = _colorForType(r.type);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectResult(r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _iconForType(r.type),
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r.subtitle,
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
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoResults(double width) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, color: Colors.grey.shade300, size: 32),
          const SizedBox(height: 8),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
