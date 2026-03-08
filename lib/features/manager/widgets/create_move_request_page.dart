import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/models/potential_location.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/potential_locations_list_provider.dart';
import 'package:ropacalapp/providers/move_requests_list_provider.dart';
import 'package:ropacalapp/features/shared/location_picker_page.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';

/// Haversine distance in miles between two lat/lng points
double _haversineDistanceMiles(
    double lat1, double lon1, double lat2, double lon2) {
  const R = 3958.8; // Earth radius in miles
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

class CreateMoveRequestPage extends ConsumerStatefulWidget {
  /// Optional bin to pre-select (e.g. when navigating from bin detail page)
  final Bin? initialBin;

  const CreateMoveRequestPage({super.key, this.initialBin});

  @override
  ConsumerState<CreateMoveRequestPage> createState() =>
      _CreateMoveRequestPageState();
}

class _CreateMoveRequestPageState extends ConsumerState<CreateMoveRequestPage> {
  // Form state
  Bin? _selectedBin;
  String? _moveType; // 'store', 'relocation', 'redeployment'

  // Destination
  String? _destinationType; // 'potential_location' or 'custom'
  PotentialLocation? _selectedPotentialLocation;
  Map<String, dynamic>? _customLocation; // {street, city, zip, latitude, longitude}

  // Schedule
  String _dateOption = '24h';
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 24));

  // Reason
  String? _reasonCategory;
  bool _createNoGoZone = false;
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBin != null) {
      _selectedBin = widget.initialBin;
      // Auto-set move type for in_storage bins
      if (_selectedBin!.status == BinStatus.inStorage) {
        _moveType = 'redeployment';
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _needsDestination =>
      _moveType == 'relocation' || _moveType == 'redeployment';

  bool get _hasDestination {
    if (!_needsDestination) return true;
    return _selectedPotentialLocation != null || _customLocation != null;
  }

  bool get _canSubmit =>
      _selectedBin != null &&
      _moveType != null &&
      _hasDestination &&
      !_isSubmitting;

  String get _destinationAddress {
    if (_selectedPotentialLocation != null) {
      final loc = _selectedPotentialLocation!;
      return [loc.street, loc.city, loc.zip]
          .where((s) => s.isNotEmpty)
          .join(', ');
    }
    if (_customLocation != null) {
      return [
        _customLocation!['street'],
        _customLocation!['city'],
        _customLocation!['zip'],
      ].where((s) => s != null && s.toString().isNotEmpty).join(', ');
    }
    return '';
  }

  void _updateDateFromOption(String option) {
    setState(() {
      _dateOption = option;
      final now = DateTime.now();
      switch (option) {
        case '24h':
          _scheduledDate = now.add(const Duration(hours: 24));
        case '3days':
          _scheduledDate = now.add(const Duration(days: 3));
        case 'week':
          _scheduledDate = now.add(const Duration(days: 7));
        // 'custom' handled by date picker
      }
    });
  }

  Future<void> _pickCustomDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    setState(() {
      _dateOption = 'custom';
      _scheduledDate = DateTime(
        date.year,
        date.month,
        date.day,
        12, // Default to noon
      );
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      final managerService = ref.read(managerServiceProvider);
      final scheduledUnix = _scheduledDate.millisecondsSinceEpoch ~/ 1000;

      // Build destination fields
      double? newLat;
      double? newLng;
      String? newStreet;
      String? newCity;
      String? newZip;
      String? sourcePotentialLocationId;

      if (_needsDestination) {
        if (_selectedPotentialLocation != null) {
          final loc = _selectedPotentialLocation!;
          newLat = loc.latitude;
          newLng = loc.longitude;
          newStreet = loc.street;
          newCity = loc.city;
          newZip = loc.zip;
          sourcePotentialLocationId = loc.id;
        } else if (_customLocation != null) {
          newLat = _customLocation!['latitude'] as double?;
          newLng = _customLocation!['longitude'] as double?;
          newStreet = _customLocation!['street'] as String?;
          newCity = _customLocation!['city'] as String?;
          newZip = _customLocation!['zip'] as String?;
        }
      }

      await managerService.scheduleBinMove(
        binId: _selectedBin!.id,
        moveType: _moveType!,
        scheduledDate: scheduledUnix,
        newLatitude: newLat,
        newLongitude: newLng,
        newStreet: newStreet,
        newCity: newCity,
        newZip: newZip,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        reasonCategory: _reasonCategory,
        createNoGoZone:
            _reasonCategory == 'relocation_request' ? _createNoGoZone : null,
        sourcePotentialLocationId: sourcePotentialLocationId,
      );

      // Refresh the move requests list
      ref.read(moveRequestsListNotifierProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pop(true);
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
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Move request created successfully',
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to create move request: $e',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
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
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Schedule Move',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 1. BIN SELECTOR ===
            _buildSectionHeader('Select Bin', Icons.delete_outline, required: true),
            const SizedBox(height: 8),
            _buildBinSelector(),
            const SizedBox(height: 20),

            // === 2. MOVE TYPE ===
            _buildSectionHeader('Move Type', Icons.swap_horiz, required: true),
            const SizedBox(height: 8),
            _buildMoveTypeSelector(),
            const SizedBox(height: 20),

            // === 3. DESTINATION (conditional) ===
            if (_needsDestination) ...[
              _buildSectionHeader('Destination', Icons.location_on_outlined,
                  required: true),
              const SizedBox(height: 8),
              _buildDestinationSection(),
              const SizedBox(height: 20),
            ],

            // === 4. SCHEDULE DATE ===
            _buildSectionHeader('Schedule Date', Icons.calendar_today_outlined,
                required: true),
            const SizedBox(height: 8),
            _buildDateSection(),
            const SizedBox(height: 20),

            // === 5. REASON CATEGORY (for relocation/redeployment) ===
            if (_moveType == 'relocation' || _moveType == 'redeployment') ...[
              _buildSectionHeader(
                  'Reason Category', Icons.category_outlined),
              const SizedBox(height: 8),
              _buildReasonCategoryDropdown(),
              if (_reasonCategory == 'relocation_request') ...[
                const SizedBox(height: 12),
                _buildNoGoZoneToggle(),
              ],
              const SizedBox(height: 20),
            ],

            // === 6. NOTES ===
            _buildSectionHeader('Notes', Icons.note_alt_outlined),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _notesController,
              hint: 'Additional details...',
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // === 8. SUBMIT BUTTON ===
            _buildSubmitButton(),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Section Header
  // ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon,
      {bool required = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text('*', style: TextStyle(color: Colors.red[400], fontSize: 14)),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // 1. Bin Selector
  // ─────────────────────────────────────────────────────────
  Widget _buildBinSelector() {
    if (_selectedBin != null) {
      return _buildSelectedBinCard();
    }
    return InkWell(
      onTap: () => _showBinPickerSheet(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add, color: Colors.grey[500], size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Tap to select a bin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedBinCard() {
    final bin = _selectedBin!;
    return InkWell(
      onTap: () => _showBinPickerSheet(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${bin.binNumber}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bin.currentStreet,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${bin.city}, ${bin.zip}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            _buildBinStatusBadge(bin.status),
            const SizedBox(width: 8),
            Icon(Icons.swap_horiz, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildBinStatusBadge(BinStatus status) {
    final (color, label) = switch (status) {
      BinStatus.active => (Colors.green, 'Active'),
      BinStatus.inStorage => (Colors.blue, 'In Storage'),
      BinStatus.pendingMove => (Colors.orange, 'Pending Move'),
      BinStatus.missing => (Colors.red, 'Missing'),
      BinStatus.retired => (Colors.grey, 'Retired'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showBinPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BinPickerSheet(
        filterInStorage: _moveType == 'redeployment',
        onSelect: (bin) {
          setState(() {
            _selectedBin = bin;
            // Auto-set move type based on bin status
            if (bin.status == BinStatus.inStorage) {
              _moveType = 'redeployment';
              // Reset destination since type changed
              _selectedPotentialLocation = null;
              _customLocation = null;
              _destinationType = null;
            } else if (_moveType == 'redeployment') {
              // Clear redeployment if bin is not in storage
              _moveType = null;
              _selectedPotentialLocation = null;
              _customLocation = null;
              _destinationType = null;
            }
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 2. Move Type Selector
  // ─────────────────────────────────────────────────────────
  Widget _buildMoveTypeSelector() {
    return Row(
      children: [
        _buildMoveTypeChip(
          'store',
          'Store',
          Icons.warehouse_outlined,
          Colors.purple,
        ),
        const SizedBox(width: 8),
        _buildMoveTypeChip(
          'relocation',
          'Relocate',
          Icons.swap_horiz,
          Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildMoveTypeChip(
          'redeployment',
          'Redeploy',
          Icons.outbox_outlined,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildMoveTypeChip(
      String value, String label, IconData icon, Color color) {
    final isSelected = _moveType == value;
    // Disable logic based on selected bin status
    final bool isDisabled;
    if (_selectedBin != null) {
      if (_selectedBin!.status == BinStatus.inStorage) {
        // In-storage bins can only be redeployed
        isDisabled = value != 'redeployment';
      } else {
        // Field bins cannot be redeployed
        isDisabled = value == 'redeployment';
      }
    } else {
      isDisabled = false;
    }

    return Expanded(
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                setState(() {
                  _moveType = value;
                  // Reset destination when changing type
                  _selectedPotentialLocation = null;
                  _customLocation = null;
                  _destinationType = null;
                  // Reset bin if switching to redeployment and bin doesn't match
                  if (value == 'redeployment' &&
                      _selectedBin != null &&
                      _selectedBin!.status != BinStatus.inStorage) {
                    _selectedBin = null;
                  }
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isDisabled ? 0.35 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.4)
                    : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? color : Colors.grey[400],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 3. Destination Section
  // ─────────────────────────────────────────────────────────
  Widget _buildDestinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Destination type chooser
        Row(
          children: [
            _buildDestTypeChip(
              'potential_location',
              'Locations',
              Icons.list_alt,
            ),
            const SizedBox(width: 8),
            _buildDestTypeChip(
              'custom',
              'Pick on Map',
              Icons.map_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Selected destination display
        if (_selectedPotentialLocation != null || _customLocation != null)
          _buildSelectedDestinationCard()
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _moveType == 'redeployment'
                        ? 'Select where to deploy this bin'
                        : 'Select the new location for this bin',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDestTypeChip(String value, String label, IconData icon) {
    // Highlight based on which destination method has an active selection
    final bool isSelected;
    if (_selectedPotentialLocation != null) {
      isSelected = value == 'potential_location';
    } else if (_customLocation != null) {
      isSelected = value == 'custom';
    } else {
      isSelected = _destinationType == value;
    }

    return Expanded(
      child: InkWell(
        onTap: () async {
          if (value == 'potential_location') {
            setState(() => _destinationType = value);
            _showPotentialLocationPicker();
          } else {
            setState(() => _destinationType = value);
            final result = await Navigator.of(context).push<Map<String, dynamic>>(
              MaterialPageRoute(
                builder: (_) => LocationPickerPage(
                  returnLocationOnly: true,
                  initialLatitude: _selectedBin?.latitude,
                  initialLongitude: _selectedBin?.longitude,
                ),
              ),
            );
            if (result != null && mounted) {
              setState(() {
                _customLocation = result;
                _selectedPotentialLocation = null;
              });
            }
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primaryGreen : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryGreen : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on,
                color: AppColors.primaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPotentialLocation != null
                      ? 'Potential Location'
                      : 'Custom Location',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _destinationAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[400], size: 18),
            onPressed: () {
              setState(() {
                _selectedPotentialLocation = null;
                _customLocation = null;
                _destinationType = null;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showPotentialLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false, // Disable sheet drag so map can pan freely
      backgroundColor: Colors.transparent,
      builder: (context) => _PotentialLocationPickerSheet(
        selectedBin: _selectedBin,
        onSelect: (location) {
          setState(() {
            _selectedPotentialLocation = location;
            _customLocation = null;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 4. Date Section
  // ─────────────────────────────────────────────────────────
  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDateChip('24h', '24 Hours'),
            const SizedBox(width: 8),
            _buildDateChip('3days', '3 Days'),
            const SizedBox(width: 8),
            _buildDateChip('week', '1 Week'),
            const SizedBox(width: 8),
            _buildDateChip('custom', 'Custom'),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.event, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 10),
              Text(
                DateFormat('MMM d, yyyy').format(_scheduledDate),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip(String value, String label) {
    final isSelected = _dateOption == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (value == 'custom') {
            _pickCustomDate();
          } else {
            _updateDateFromOption(value);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen.withValues(alpha: 0.4)
                  : Colors.grey.shade200,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryGreen : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 5. Reason Category
  // ─────────────────────────────────────────────────────────
  Widget _buildReasonCategoryDropdown() {
    const categoryLabels = {
      'landlord_complaint': 'Landlord Complaint',
      'theft': 'Theft',
      'vandalism': 'Vandalism',
      'missing': 'Missing Bin',
      'relocation_request': 'Relocation Request',
      'other': 'Other',
    };

    final label = _reasonCategory != null
        ? categoryLabels[_reasonCategory] ?? _reasonCategory!
        : null;

    return InkWell(
      onTap: _showReasonCategoryPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label ?? 'None',
                style: TextStyle(
                  fontSize: 14,
                  color: label != null ? Colors.black87 : Colors.grey[400],
                  fontWeight: label != null ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGoZoneToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.block, size: 18, color: Colors.red[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Create No-Go Zone',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ),
          Switch.adaptive(
            value: _createNoGoZone,
            onChanged: (v) => setState(() => _createNoGoZone = v),
            activeColor: Colors.red[600],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 6 & 7. Text Fields
  // ─────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 8. Submit Button
  // ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _canSubmit ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_send, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Schedule Move Request',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Reason Category Bottom Sheet Picker
  // ─────────────────────────────────────────────────────────
  void _showReasonCategoryPicker() {
    final categories = <(String?, String, IconData, String)>[
      (null, 'None', Icons.remove_circle_outline, 'No category'),
      ('landlord_complaint', 'Landlord Complaint', Icons.house_outlined, 'Property owner request'),
      ('theft', 'Theft', Icons.warning_amber, 'Bin was stolen'),
      ('vandalism', 'Vandalism', Icons.broken_image_outlined, 'Bin was damaged'),
      ('missing', 'Missing Bin', Icons.search_off, 'Bin cannot be found'),
      ('relocation_request', 'Relocation Request', Icons.swap_horiz, 'Requested move to new site'),
      ('other', 'Other', Icons.more_horiz, 'Other reason'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.category_outlined, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Reason Category',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            // Options
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: categories.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, indent: 56, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _reasonCategory == cat.$1;
                return Material(
                  color: isSelected
                      ? AppColors.primaryGreen.withValues(alpha: 0.06)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _reasonCategory = cat.$1;
                        if (cat.$1 != 'relocation_request') {
                          _createNoGoZone = false;
                        }
                      });
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGreen.withValues(alpha: 0.12)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              cat.$3,
                              size: 18,
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.$2,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  cat.$4,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: AppColors.primaryGreen, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BIN PICKER — FULL SCREEN BOTTOM SHEET
// =============================================================================

enum _BinStatusFilter { all, active, inStorage, pendingMove, missing }

class _BinPickerSheet extends ConsumerStatefulWidget {
  final bool filterInStorage;
  final ValueChanged<Bin> onSelect;

  const _BinPickerSheet({
    required this.filterInStorage,
    required this.onSelect,
  });

  @override
  ConsumerState<_BinPickerSheet> createState() => _BinPickerSheetState();
}

class _BinPickerSheetState extends ConsumerState<_BinPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  late _BinStatusFilter _statusFilter;

  @override
  void initState() {
    super.initState();
    // Auto-set filter to In Storage for redeployment
    _statusFilter =
        widget.filterInStorage ? _BinStatusFilter.inStorage : _BinStatusFilter.all;
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _countForStatus(List<Bin> bins, _BinStatusFilter filter) {
    if (filter == _BinStatusFilter.all) return bins.length;
    final status = _filterToBinStatus(filter);
    return status == null ? 0 : bins.where((b) => b.status == status).length;
  }

  BinStatus? _filterToBinStatus(_BinStatusFilter filter) {
    return switch (filter) {
      _BinStatusFilter.all => null,
      _BinStatusFilter.active => BinStatus.active,
      _BinStatusFilter.inStorage => BinStatus.inStorage,
      _BinStatusFilter.pendingMove => BinStatus.pendingMove,
      _BinStatusFilter.missing => BinStatus.missing,
    };
  }

  List<Bin> _applyFilters(List<Bin> bins) {
    var filtered = bins.toList();

    // Status filter
    if (_statusFilter != _BinStatusFilter.all) {
      final status = _filterToBinStatus(_statusFilter);
      if (status != null) {
        filtered = filtered.where((b) => b.status == status).toList();
      }
    }

    // Search
    if (_query.isNotEmpty) {
      filtered = filtered.where((b) {
        final num = b.binNumber.toString();
        final addr = b.address.toLowerCase();
        return num.contains(_query) || addr.contains(_query);
      }).toList();
    }

    // Sort by bin number
    filtered.sort((a, b) => a.binNumber.compareTo(b.binNumber));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final binsAsync = ref.watch(binsListProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Title row with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline,
                      color: AppColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.filterInStorage
                            ? 'Select Warehouse Bin'
                            : 'Select Bin',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Choose the bin to schedule a move for',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[500]),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by bin # or address...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey[400], size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: Colors.grey[500], size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Status filter chips
          binsAsync.when(
            data: (bins) => Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _BinStatusFilter.values) ...[
                      if (filter != _BinStatusFilter.values.first)
                        const SizedBox(width: 6),
                      _buildFilterChip(
                        label: '${switch (filter) {
                          _BinStatusFilter.all => 'All',
                          _BinStatusFilter.active => 'Active',
                          _BinStatusFilter.inStorage => 'In Storage',
                          _BinStatusFilter.pendingMove => 'Pending Move',
                          _BinStatusFilter.missing => 'Missing',
                        }} (${_countForStatus(bins, filter)})',
                        isSelected: _statusFilter == filter,
                        onTap: () =>
                            setState(() => _statusFilter = filter),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey[200]),

          // List
          Expanded(
            child: binsAsync.when(
              data: (bins) {
                final filtered = _applyFilters(bins);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty
                              ? 'No bins match your search'
                              : widget.filterInStorage
                                  ? 'No bins in storage'
                                  : 'No bins found',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try a different search or filter',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final bin = filtered[index];
                    return _BinListTile(
                      bin: bin,
                      onTap: () => widget.onSelect(bin),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryGreen),
              ),
              error: (e, _) => Center(
                child: Text('Error loading bins: $e',
                    style: TextStyle(color: Colors.red[600])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryGreen : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _BinListTile extends StatelessWidget {
  final Bin bin;
  final VoidCallback onTap;

  const _BinListTile({required this.bin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (bin.status) {
      BinStatus.active => (Colors.green, 'Active'),
      BinStatus.inStorage => (Colors.blue, 'In Storage'),
      BinStatus.pendingMove => (Colors.orange, 'Pending Move'),
      BinStatus.missing => (Colors.red, 'Missing'),
      BinStatus.retired => (Colors.grey, 'Retired'),
    };

    // Format last checked relative time
    String? lastCheckedText;
    if (bin.lastChecked != null) {
      final diff = DateTime.now().difference(bin.lastChecked!);
      if (diff.inMinutes < 60) {
        lastCheckedText = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        lastCheckedText = '${diff.inHours}h ago';
      } else {
        lastCheckedText = '${diff.inDays}d ago';
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Bin number badge
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: statusColor.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Text(
                    '#${bin.binNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (bin.fillPercentage != null) ...[
                    // Fill bar
                    Container(
                      height: 3,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            (bin.fillPercentage! / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bin.fillPercentage! > 80
                                ? Colors.red
                                : bin.fillPercentage! > 50
                                    ? Colors.orange
                                    : Colors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bin.fillPercentage}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Address + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bin.currentStreet,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bin.city}, ${bin.zip}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  if (lastCheckedText != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Checked $lastCheckedText',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// POTENTIAL LOCATION PICKER — FULL SCREEN WITH LIST | MAP TOGGLE
// =============================================================================
class _PotentialLocationPickerSheet extends ConsumerStatefulWidget {
  final Bin? selectedBin;
  final ValueChanged<PotentialLocation> onSelect;

  const _PotentialLocationPickerSheet({
    this.selectedBin,
    required this.onSelect,
  });

  @override
  ConsumerState<_PotentialLocationPickerSheet> createState() =>
      _PotentialLocationPickerSheetState();
}

class _PotentialLocationPickerSheetState
    extends ConsumerState<_PotentialLocationPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _showMap = false;

  // Map state
  GoogleMapViewController? _mapController;
  final Map<String, PotentialLocation> _markerToLocation = {};
  PotentialLocation? _mapSelectedLocation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double? _distanceFromBin(PotentialLocation loc) {
    final bin = widget.selectedBin;
    if (bin == null || bin.latitude == null || bin.longitude == null) return null;
    if (loc.latitude == null || loc.longitude == null) return null;
    return _haversineDistanceMiles(
      bin.latitude!,
      bin.longitude!,
      loc.latitude!,
      loc.longitude!,
    );
  }

  String _formatDistance(double miles) {
    if (miles < 0.1) return '< 0.1 mi';
    if (miles < 10) return '${miles.toStringAsFixed(1)} mi';
    return '${miles.round()} mi';
  }

  List<PotentialLocation> _filterAndSort(List<PotentialLocation> locations) {
    var filtered = locations.toList();

    if (_query.isNotEmpty) {
      filtered = filtered.where((loc) {
        final addr = '${loc.street} ${loc.city} ${loc.zip}'.toLowerCase();
        return addr.contains(_query);
      }).toList();
    }

    // Sort by distance from selected bin (nearest first)
    if (widget.selectedBin != null &&
        widget.selectedBin!.latitude != null) {
      filtered.sort((a, b) {
        final dA = _distanceFromBin(a);
        final dB = _distanceFromBin(b);
        if (dA == null && dB == null) return 0;
        if (dA == null) return 1;
        if (dB == null) return -1;
        return dA.compareTo(dB);
      });
    }

    return filtered;
  }

  Future<void> _addMarkersToMap(List<PotentialLocation> locations) async {
    final controller = _mapController;
    if (controller == null) return;

    _markerToLocation.clear();

    final markerOptions = <MarkerOptions>[];
    final locationsList = <PotentialLocation>[];

    for (final loc in locations) {
      if (loc.latitude == null || loc.longitude == null) continue;

      final icon =
          await GoogleNavigationMarkerService.createPotentialLocationMarkerIcon(
        isPending: true,
        withPulse: false,
      );

      markerOptions.add(
        MarkerOptions(
          position: LatLng(
            latitude: loc.latitude!,
            longitude: loc.longitude!,
          ),
          icon: icon,
          infoWindow: InfoWindow(
            title: loc.street,
            snippet: '${loc.city}, ${loc.zip}',
          ),
        ),
      );
      locationsList.add(loc);
    }

    final addedMarkers = await controller.addMarkers(markerOptions);
    final markers = addedMarkers.whereType<Marker>().toList();

    for (var i = 0; i < markers.length && i < locationsList.length; i++) {
      _markerToLocation[markers[i].markerId] = locationsList[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(potentialLocationsListNotifierProvider);

    // Camera center: selected bin location, or default Dallas
    final centerLat = widget.selectedBin?.latitude ?? 32.886534;
    final centerLng = widget.selectedBin?.longitude ?? -96.7642497;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Title + close + view toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.location_on,
                      color: AppColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Destination',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (widget.selectedBin != null)
                        Text(
                          'Sorted by distance from Bin #${widget.selectedBin!.binNumber}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        )
                      else
                        Text(
                          'Choose a potential location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                // List / Map toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewToggle(
                        icon: Icons.list,
                        isSelected: !_showMap,
                        onTap: () => setState(() => _showMap = false),
                      ),
                      _buildViewToggle(
                        icon: Icons.map_outlined,
                        isSelected: _showMap,
                        onTap: () => setState(() => _showMap = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[500]),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search (only in list view)
          if (!_showMap) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by address...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey[400], size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Colors.grey[500], size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: Colors.grey[200]),
          ],

          // Content: List or Map
          Expanded(
            child: _showMap
                ? _buildMapView(locationsAsync, centerLat, centerLng)
                : _buildListView(locationsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? AppColors.primaryGreen : Colors.grey[500],
        ),
      ),
    );
  }

  // ─── LIST VIEW ───
  Widget _buildListView(AsyncValue<List<PotentialLocation>> locationsAsync) {
    return locationsAsync.when(
      data: (locations) {
        final filtered = _filterAndSort(locations);

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'No potential locations found',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final loc = filtered[index];
            final distance = _distanceFromBin(loc);

            return InkWell(
              onTap: () => widget.onSelect(loc),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.location_on,
                          color: AppColors.primaryGreen, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.street,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${loc.city}, ${loc.zip}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                          if (loc.notes != null &&
                              loc.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.note_alt_outlined,
                                    size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    loc.notes!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: distance < 1
                              ? Colors.green.withValues(alpha: 0.1)
                              : distance < 5
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDistance(distance),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: distance < 1
                                ? Colors.green[700]
                                : distance < 5
                                    ? Colors.orange[700]
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ] else
                      Icon(Icons.chevron_right,
                          color: Colors.grey[400], size: 18),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: TextStyle(color: Colors.red[600])),
      ),
    );
  }

  // ─── MAP VIEW ───
  Widget _buildMapView(
    AsyncValue<List<PotentialLocation>> locationsAsync,
    double centerLat,
    double centerLng,
  ) {
    final hasSelection = _mapSelectedLocation != null;

    return Stack(
      children: [
        GoogleMapsMapView(
          key: const ValueKey('potential_location_picker_map'),
          initialCameraPosition: CameraPosition(
            target: LatLng(latitude: centerLat, longitude: centerLng),
            zoom: 13,
          ),
          initialMapType: MapType.normal,
          initialZoomControlsEnabled: false,
          onViewCreated: (GoogleMapViewController controller) async {
            _mapController = controller;
            await controller.setMyLocationEnabled(true);
            await controller.settings.setMyLocationButtonEnabled(false);

            // Add bin marker first
            await _addBinMarkerToMap();

            // Then add potential location markers
            locationsAsync.whenData((locations) {
              _addMarkersToMap(locations);
            });
          },
          onMarkerClicked: (String markerId) {
            final location = _markerToLocation[markerId];
            if (location != null) {
              setState(() => _mapSelectedLocation = location);
              // Animate camera to the selected marker
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(
                      latitude: location.latitude!,
                      longitude: location.longitude!,
                    ),
                    zoom: 14,
                  ),
                ),
              );
            }
          },
        ),

        // Bottom card for selected location — animated slide up
        Positioned(
          bottom: 24 + MediaQuery.of(context).padding.bottom,
          left: 16,
          right: 16,
          child: AnimatedSlide(
            offset: hasSelection ? Offset.zero : const Offset(0, 1.5),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: hasSelection ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: hasSelection
                  ? _buildMapSelectionCard(_mapSelectedLocation!)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  /// Add a static bin marker on the map so the user can see where their bin is
  Future<void> _addBinMarkerToMap() async {
    final controller = _mapController;
    final bin = widget.selectedBin;
    if (controller == null || bin == null) return;
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
        infoWindow: InfoWindow(
          title: 'Bin #${bin.binNumber}',
          snippet: bin.address,
        ),
      ),
    ]);
  }

  Widget _buildMapSelectionCard(PotentialLocation loc) {
    final distance = _distanceFromBin(loc);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on,
                    color: AppColors.primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.street,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${loc.city}, ${loc.zip}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (distance != null) ...[
                          Text(
                            '  •  ',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[400]),
                          ),
                          Text(
                            _formatDistance(distance),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Dismiss button
              IconButton(
                icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                onPressed: () =>
                    setState(() => _mapSelectedLocation = null),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => widget.onSelect(loc),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Select This Location',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
