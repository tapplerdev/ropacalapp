import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// Which layers are visible on the manager map
class MapLayerVisibility {
  final bool drivers;
  final bool bins;
  final bool potentialLocations;

  const MapLayerVisibility({
    this.drivers = true,
    this.bins = true,
    this.potentialLocations = true,
  });

  MapLayerVisibility copyWith({
    bool? drivers,
    bool? bins,
    bool? potentialLocations,
  }) {
    return MapLayerVisibility(
      drivers: drivers ?? this.drivers,
      bins: bins ?? this.bins,
      potentialLocations: potentialLocations ?? this.potentialLocations,
    );
  }
}

/// Floating layers control — green circular button that opens a styled bottom sheet
class MapLayersControl extends StatelessWidget {
  final MapLayerVisibility visibility;
  final ValueChanged<MapLayerVisibility> onChanged;

  const MapLayersControl({
    super.key,
    required this.visibility,
    required this.onChanged,
  });

  void _showLayersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LayersSheet(
        visibility: visibility,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLayersSheet(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
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
        child: const Icon(
          Icons.layers,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

/// Bottom sheet with toggle switches for each layer
class _LayersSheet extends StatefulWidget {
  final MapLayerVisibility visibility;
  final ValueChanged<MapLayerVisibility> onChanged;

  const _LayersSheet({
    required this.visibility,
    required this.onChanged,
  });

  @override
  State<_LayersSheet> createState() => _LayersSheetState();
}

class _LayersSheetState extends State<_LayersSheet> {
  late MapLayerVisibility _visibility;

  @override
  void initState() {
    super.initState();
    _visibility = widget.visibility;
  }

  void _toggle(String layer) {
    setState(() {
      switch (layer) {
        case 'drivers':
          _visibility = _visibility.copyWith(drivers: !_visibility.drivers);
          break;
        case 'bins':
          _visibility = _visibility.copyWith(bins: !_visibility.bins);
          break;
        case 'locations':
          _visibility = _visibility.copyWith(
            potentialLocations: !_visibility.potentialLocations,
          );
          break;
      }
    });
    widget.onChanged(_visibility);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.layers,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Map Layers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Layer toggles
          _LayerToggle(
            icon: Icons.local_shipping,
            label: 'Drivers',
            color: AppColors.primaryGreen,
            isActive: _visibility.drivers,
            onTap: () => _toggle('drivers'),
          ),
          Divider(height: 1, indent: 60, color: Colors.grey.shade100),
          _LayerToggle(
            icon: Icons.delete_outline,
            label: 'Bins',
            color: AppColors.brandBlueAccent,
            isActive: _visibility.bins,
            onTap: () => _toggle('bins'),
          ),
          Divider(height: 1, indent: 60, color: Colors.grey.shade100),
          _LayerToggle(
            icon: Icons.add_location_alt,
            label: 'Potential Locations',
            color: AppColors.warningOrange,
            isActive: _visibility.potentialLocations,
            onTap: () => _toggle('locations'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _LayerToggle({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Switch.adaptive(
                value: isActive,
                onChanged: (_) => onTap(),
                activeColor: AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
