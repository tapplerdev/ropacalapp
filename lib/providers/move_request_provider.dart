import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/services/geofence_service.dart';
import 'package:ropacalapp/models/move_request.dart';
import 'package:ropacalapp/core/enums/move_request_status.dart';
import 'package:ropacalapp/providers/api_provider.dart';

part 'move_request_provider.g.dart';

/// Provider for the currently active move request
///
/// Manages the lifecycle of bin relocation requests:
/// 1. pending → Driver navigates to pickup location
/// 2. pickedUp → Driver transports bin to drop-off location
/// 3. completed → Bin placed at new location
@Riverpod(keepAlive: true)
class ActiveMoveRequest extends _$ActiveMoveRequest {
  @override
  MoveRequest? build() => null;

  /// Set active move request (called when WebSocket receives assignment)
  void setMoveRequest(MoveRequest request) {
    AppLogger.general('🚚 Active move request set: ${request.id}');
    AppLogger.general('   Bin ID: ${request.binId}');
    AppLogger.general('   Pickup: ${request.pickupAddress}');
    AppLogger.general('   Dropoff: ${request.dropoffAddress}');
    state = request;
  }

  /// Clear active move request
  void clearMoveRequest() {
    AppLogger.general('🚚 Active move request cleared');
    state = null;
  }

  /// Mark pickup as complete
  Future<void> completePickup({
    required String photoUrl,
    bool hasDamage = false,
    String? notes,
  }) async {
    if (state == null) {
      AppLogger.general(
        '⚠️ Cannot complete pickup - no active move request',
        level: AppLogger.warning,
      );
      return;
    }

    try {
      AppLogger.general('📦 Completing pickup for move request ${state!.id}');

      final apiService = ref.read(apiServiceProvider);
      await apiService.post(
        '/api/driver/move-requests/${state!.id}/pickup',
        {
          'pickup_photo_url': photoUrl,
          'picked_up_at': DateTime.now().toIso8601String(),
          'has_damage': hasDamage,
          if (notes != null) 'notes': notes,
        },
      );

      state = state!.copyWith(
        status: MoveRequestStatus.pickedUp,
        notes: notes,
      );

      AppLogger.general('✅ Pickup complete - now transporting to drop-off');
      AppLogger.general('   Next stop: ${state!.dropoffAddress}');
    } catch (e, stack) {
      AppLogger.general(
        '❌ Error completing pickup: $e',
        level: AppLogger.error,
      );
      AppLogger.general('Stack trace: $stack');
      rethrow;
    }
  }

  /// Mark placement as complete
  Future<void> completePlacement({
    required String photoUrl,
    String? notes,
    bool hasIssue = false,
  }) async {
    if (state == null) {
      AppLogger.general(
        '⚠️ Cannot complete placement - no active move request',
        level: AppLogger.warning,
      );
      return;
    }

    if (state!.status != MoveRequestStatus.pickedUp) {
      AppLogger.general(
        '⚠️ Cannot complete placement - bin not picked up yet',
        level: AppLogger.warning,
      );
      return;
    }

    try {
      AppLogger.general('📍 Completing placement for move request ${state!.id}');

      final apiService = ref.read(apiServiceProvider);
      await apiService.post(
        '/api/driver/move-requests/${state!.id}/complete',
        {
          'placement_photo_url': photoUrl,
          'completed_at': DateTime.now().toIso8601String(),
          'has_issue': hasIssue,
          if (notes != null) 'notes': notes,
        },
      );

      state = state!.copyWith(
        status: MoveRequestStatus.completed,
        completedAt: DateTime.now().millisecondsSinceEpoch,
        notes: notes,
      );

      AppLogger.general('✅ Placement complete - move request finished');
      AppLogger.general('   Bin #${state!.binId} now at ${state!.dropoffAddress}');

      // Clear active move request after completion
      Future.delayed(const Duration(seconds: 2), () {
        clearMoveRequest();
      });
    } catch (e, stack) {
      AppLogger.general(
        '❌ Error completing placement: $e',
        level: AppLogger.error,
      );
      AppLogger.general('Stack trace: $stack');
      rethrow;
    }
  }

  /// Check if driver is within pickup geofence
  bool isWithinPickupGeofence(LatLng currentLocation) {
    if (state == null || state!.status != MoveRequestStatus.pending) {
      return false;
    }

    return GeofenceService.isWithinGeofence(
      currentLocation: currentLocation,
      targetLocation: LatLng(
        latitude: state!.pickupLatitude,
        longitude: state!.pickupLongitude,
      ),
    );
  }

  /// Check if driver is within drop-off geofence
  bool isWithinDropoffGeofence(LatLng currentLocation) {
    if (state == null || state!.status != MoveRequestStatus.pickedUp) {
      return false;
    }

    final dropoffLat = state!.dropoffLatitude;
    final dropoffLng = state!.dropoffLongitude;

    if (dropoffLat == null || dropoffLng == null) {
      return false; // No drop-off location for pickup-only moves
    }

    return GeofenceService.isWithinGeofence(
      currentLocation: currentLocation,
      targetLocation: LatLng(
        latitude: dropoffLat,
        longitude: dropoffLng,
      ),
    );
  }

  /// Get distance to pickup location in meters
  double? getDistanceToPickup(LatLng currentLocation) {
    if (state == null) return null;

    return GeofenceService.getDistanceToTargetInMeters(
      currentLocation: currentLocation,
      targetLocation: LatLng(
        latitude: state!.pickupLatitude,
        longitude: state!.pickupLongitude,
      ),
    );
  }

  /// Get distance to drop-off location in meters
  double? getDistanceToDropoff(LatLng currentLocation) {
    if (state == null) return null;

    final dropoffLat = state!.dropoffLatitude;
    final dropoffLng = state!.dropoffLongitude;

    if (dropoffLat == null || dropoffLng == null) {
      return null; // No drop-off location for pickup-only moves
    }

    return GeofenceService.getDistanceToTargetInMeters(
      currentLocation: currentLocation,
      targetLocation: LatLng(
        latitude: dropoffLat,
        longitude: dropoffLng,
      ),
    );
  }
}
