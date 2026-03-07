import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/widgets/route_map_preview.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/services/manager_service.dart';

/// Bottom sheet for selecting pending move requests to add to a shift.
/// Each selected move request becomes a pickup + dropoff task pair.
class MoveRequestPickerSheet extends HookConsumerWidget {
  const MoveRequestPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final selectedType = useState('all');
    final selectedSort = useState('newest');
    final selectedIds = useState<Set<String>>({});
    final previewRequest = useState<Map<String, dynamic>?>(null);
    final moveRequestsFuture = useMemoized(
      () => ref.read(managerServiceProvider).getAllMoveRequests(status: 'pending'),
      [],
    );
    final snapshot = useFuture(moveRequestsFuture);

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
            child: previewRequest.value != null
                ? _buildMapPreview(
                    key: const ValueKey('map'),
                    request: previewRequest.value!,
                    managerService: ref.read(managerServiceProvider),
                    onBack: () => previewRequest.value = null,
                  )
                : _MoveRequestList(
                    key: const ValueKey('list'),
                    searchQuery: searchQuery,
                    selectedType: selectedType,
                    selectedSort: selectedSort,
                    selectedIds: selectedIds,
                    snapshot: snapshot,
                    scrollController: scrollController,
                    onViewMap: (request) => previewRequest.value = request,
                  ),
          ),
        );
      },
    );
  }
}

/// List view with search, sorting chips, and multi-select
class _MoveRequestList extends StatelessWidget {
  final ValueNotifier<String> searchQuery;
  final ValueNotifier<String> selectedType;
  final ValueNotifier<String> selectedSort;
  final ValueNotifier<Set<String>> selectedIds;
  final AsyncSnapshot<List<Map<String, dynamic>>> snapshot;
  final ScrollController scrollController;
  final void Function(Map<String, dynamic>) onViewMap;

  const _MoveRequestList({
    super.key,
    required this.searchQuery,
    required this.selectedType,
    required this.selectedSort,
    required this.selectedIds,
    required this.snapshot,
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
            'Add Move Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
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
        // Type filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _SortChip(
                label: 'All',
                isSelected: selectedType.value == 'all',
                onTap: () => selectedType.value = 'all',
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Store',
                isSelected: selectedType.value == 'store',
                onTap: () => selectedType.value = 'store',
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Relocate',
                isSelected: selectedType.value == 'relocation',
                onTap: () => selectedType.value = 'relocation',
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Redeploy',
                isSelected: selectedType.value == 'redeployment',
                onTap: () => selectedType.value = 'redeployment',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Sort chips
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
        // Move request list
        Expanded(
          child: _buildContent(context),
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
                        final requests = snapshot.data;
                        if (requests == null) return;
                        final selected = requests
                            .where((r) => selectedIds.value
                                .contains(r['id'] as String))
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
                      ? 'Select move requests'
                      : 'Add ${selectedIds.value.length} Move Request${selectedIds.value.length > 1 ? 's' : ''}',
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

  Widget _buildContent(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                'Error loading move requests: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final requests = snapshot.data ?? [];
    final query = searchQuery.value.toLowerCase();
    final typeFilter = selectedType.value;
    var filtered = requests.where((r) {
      // Type filter
      if (typeFilter != 'all') {
        final moveType = (r['move_type'] as String?) ?? '';
        if (moveType != typeFilter) return false;
      }
      // Search filter
      if (query.isEmpty) return true;
      final binNumber = (r['bin_number'] ?? '').toString();
      final address =
          '${r['current_street'] ?? ''} ${r['city'] ?? ''}'.toLowerCase();
      return binNumber.contains(query) || address.contains(query);
    }).toList();

    // Sort
    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(
              (a['created_at_iso'] as String?) ?? '') ??
          DateTime(2000);
      final bDate = DateTime.tryParse(
              (b['created_at_iso'] as String?) ?? '') ??
          DateTime(2000);
      return selectedSort.value == 'newest'
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.move_up, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              requests.isEmpty
                  ? 'No pending move requests'
                  : 'No requests match your search',
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
        final request = filtered[index];
        final id = request['id'] as String;
        final isSelected = selectedIds.value.contains(id);
        return _MoveRequestCard(
          request: request,
          isSelected: isSelected,
          onTap: () {
            final updated = Set<String>.from(selectedIds.value);
            if (isSelected) {
              updated.remove(id);
            } else {
              updated.add(id);
            }
            selectedIds.value = updated;
          },
          onViewMap: () => onViewMap(request),
        );
      },
    );
  }
}

/// Build a full-screen map preview with header + RouteMapPreview
Widget _buildMapPreview({
  Key? key,
  required Map<String, dynamic> request,
  required ManagerService managerService,
  required VoidCallback onBack,
}) {
  final binNumber = request['bin_number'] as int?;
  final moveType = (request['move_type'] as String?) ?? 'relocation';
  final origLat = (request['original_latitude'] as num?)?.toDouble() ?? 0;
  final origLng = (request['original_longitude'] as num?)?.toDouble() ?? 0;
  final newLat = (request['new_latitude'] as num?)?.toDouble() ?? 0;
  final newLng = (request['new_longitude'] as num?)?.toDouble() ?? 0;
  final sourcePotentialLocationId =
      request['source_potential_location_id'] as String?;

  final currentStreet = request['current_street'] as String? ?? '';
  final city = request['city'] as String? ?? '';
  final newStreet = request['new_street'] as String? ?? '';
  final newCity = request['new_city'] as String? ?? '';
  final destinationLabel = moveType == 'store'
      ? 'Warehouse Storage'
      : newStreet.isNotEmpty
          ? '$newStreet, $newCity'
          : 'Destination';

  return Column(
    key: key,
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
                    binNumber != null
                        ? 'Bin #$binNumber Move'
                        : 'Move Request',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentStreet.isNotEmpty
                        ? '$currentStreet, $city → $destinationLabel'
                        : 'View on map',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Map (fills remaining space)
      Expanded(
        child: RouteMapPreview(
          originLat: origLat,
          originLng: origLng,
          destLat: newLat,
          destLng: newLng,
          binNumber: binNumber,
          moveType: moveType,
          sourcePotentialLocationId: sourcePotentialLocationId,
          managerService: managerService,
          isExpanded: true,
          showLegend: true,
        ),
      ),
    ],
  );
}

/// Move request card with checkbox, enriched details, and map button
class _MoveRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onViewMap;

  const _MoveRequestCard({
    required this.request,
    required this.isSelected,
    required this.onTap,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    final binNumber = request['bin_number'];
    final moveType = (request['move_type'] as String?) ?? 'relocation';
    final currentStreet = request['current_street'] as String? ?? '';
    final city = request['city'] as String? ?? '';
    final urgency = (request['urgency'] as String?) ?? 'scheduled';
    final requestedBy = request['requested_by_name'] as String?;
    final createdAt = request['created_at_iso'] as String?;
    final scheduledDate = request['scheduled_date_iso'] as String?;

    // Destination address
    final newStreet = request['new_street'] as String? ?? '';
    final newCity = request['new_city'] as String? ?? '';
    final newZip = request['new_zip'] as String? ?? '';
    final destinationAddress = moveType == 'store'
        ? 'Warehouse Storage'
        : newStreet.isNotEmpty
            ? '$newStreet, $newCity $newZip'.trim()
            : 'No destination';

    // Urgency state
    final urgencyState = _getUrgencyState(urgency, scheduledDate);

    // Check if we have coords for map preview
    final hasCoords = (request['original_latitude'] as num?) != null &&
        (request['new_latitude'] as num?) != null;

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
              // Move type icon
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _moveTypeColor(moveType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.move_up,
                    size: 20,
                    color: _moveTypeColor(moveType),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Bin # + badges
                    Row(
                      children: [
                        Text(
                          binNumber != null
                              ? 'Bin #$binNumber'
                              : 'Move Request',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _Badge(
                          label: _moveTypeLabel(moveType),
                          color: _moveTypeColor(moveType),
                        ),
                        if (urgencyState != null) ...[
                          const SizedBox(width: 4),
                          _Badge(
                            label: urgencyState.label,
                            color: urgencyState.color,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Row 2: Current address
                    Text(
                      currentStreet.isNotEmpty
                          ? '$currentStreet, $city'
                          : 'No address',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Row 3: Destination
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destinationAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Row 4: Requester + time ago
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
                            _buildRequesterLine(requestedBy, createdAt),
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

  String _buildRequesterLine(String? requestedBy, String? createdAt) {
    final parts = <String>[];
    if (requestedBy != null && requestedBy.isNotEmpty) parts.add(requestedBy);
    if (createdAt != null) {
      final timeAgo = _timeAgo(createdAt);
      if (timeAgo.isNotEmpty) parts.add(timeAgo);
    }
    return parts.isEmpty ? 'Unknown' : parts.join(' · ');
  }

  _UrgencyState? _getUrgencyState(String urgency, String? scheduledDateIso) {
    if (urgency == 'urgent') {
      return _UrgencyState('URGENT', Colors.red.shade600);
    }
    if (scheduledDateIso != null) {
      try {
        final scheduledDate = DateTime.parse(scheduledDateIso);
        final now = DateTime.now();
        final diff = scheduledDate.difference(now);
        if (diff.isNegative) {
          return _UrgencyState('OVERDUE', Colors.red.shade600);
        } else if (diff.inDays <= 2) {
          return _UrgencyState('DUE SOON', Colors.orange.shade600);
        }
      } catch (_) {}
    }
    return null;
  }

  Color _moveTypeColor(String moveType) {
    switch (moveType.toLowerCase()) {
      case 'store':
        return Colors.blue.shade600;
      case 'redeployment':
        return Colors.teal.shade600;
      default:
        return Colors.purple.shade600;
    }
  }

  String _moveTypeLabel(String moveType) {
    switch (moveType.toLowerCase()) {
      case 'store':
        return 'STORE';
      case 'redeployment':
        return 'REDEPLOY';
      default:
        return 'RELOCATE';
    }
  }
}

class _UrgencyState {
  final String label;
  final Color color;
  const _UrgencyState(this.label, this.color);
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
