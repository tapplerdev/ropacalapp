import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ropacalapp/models/move_request.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/potential_locations_list_provider.dart';
import 'package:ropacalapp/providers/move_request_provider.dart';
import 'package:ropacalapp/providers/move_requests_list_provider.dart';
import 'package:ropacalapp/core/notifications/notification_event.dart';

/// Executes side effects (provider invalidations, state updates) for events.
/// Centralizes logic previously scattered across auth_provider,
/// centrifugo_provider, and shift_provider.
class NotificationSideEffects {
  /// Execute the side effect for a given event.
  void execute(NotificationEvent event, Ref ref) {
    switch (event.eventType) {
      // -- Shift events --
      case 'shift_created':
      case 'shift_edited':
      case 'task_removed':
        ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();

      case 'shift_reassigned':
        ref.read(shiftNotifierProvider.notifier).resetToInactive();

      case 'shift_cancelled':
      case 'shift_deleted':
        ref.read(shiftNotifierProvider.notifier).handleShiftCancellation();

      // -- Route events --
      case 'route_assigned':
      case 'route_updated':
        ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();

      // -- Move request events --
      case 'move_request_assigned':
        final moveRequestData = event.payload['move_request'];
        if (moveRequestData is Map<String, dynamic>) {
          final moveRequest = MoveRequest.fromJson(moveRequestData);
          ref
              .read(activeMoveRequestProvider.notifier)
              .setMoveRequest(moveRequest);
        }
        ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();

      case 'move_request_created':
      case 'move_request_updated':
      case 'move_request_cancelled':
        ref.invalidate(moveRequestsListNotifierProvider);
        ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();

      // -- Bin events --
      case 'bin_updated':
      case 'bin_created':
      case 'bin_deleted':
        ref.invalidate(binsListProvider);

      // -- Potential location events --
      case 'potential_location_created':
      case 'potential_location_deleted':
        ref.invalidate(potentialLocationsListNotifierProvider);

      case 'potential_location_converted':
        ref.invalidate(potentialLocationsListNotifierProvider);
        ref.invalidate(binsListProvider);

      // -- Driver status events (manager side) --
      case 'driver_shift_change':
        final driverId = event.payload['driver_id'] as String?;
        final status = event.payload['status'] as String?;
        final shiftId = event.payload['shift_id'] as String?;
        if (driverId != null && status != null) {
          ref
              .read(driversNotifierProvider.notifier)
              .updateDriverStatus(driverId, status, shiftId);
        }

      // -- Shift broadcast (company channel) --
      case 'shift_updated':
        ref.invalidate(driversNotifierProvider);

      default:
        break;
    }
  }
}
