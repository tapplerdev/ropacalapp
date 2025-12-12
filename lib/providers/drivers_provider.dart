import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/driver_status.dart';
import 'package:ropacalapp/models/driver_location.dart';
import 'package:ropacalapp/providers/api_provider.dart';

part 'drivers_provider.g.dart';

/// Provider for managing list of drivers (for manager dashboard)
@Riverpod(keepAlive: true)
class DriversNotifier extends _$DriversNotifier {
  @override
  Future<List<DriverStatus>> build() async {
    // Fetch initial list of drivers
    return _fetchDrivers();
  }

  /// Fetch all drivers from backend
  Future<List<DriverStatus>> _fetchDrivers() async {
    try {
      AppLogger.general('🚗 Fetching all drivers...');

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/api/manager/drivers');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> driversJson = data['data'];

        final drivers = driversJson.map((json) {
          return DriverStatus.fromJson(json as Map<String, dynamic>);
        }).toList();

        AppLogger.general('✅ Loaded ${drivers.length} drivers');
        return drivers;
      }

      AppLogger.general('⚠️ No drivers data in response');
      return [];
    } catch (e) {
      AppLogger.general('❌ Error fetching drivers: $e');
      rethrow;
    }
  }

  /// Update a driver's location (called from WebSocket)
  void updateDriverLocation(DriverLocation location) {
    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.general('🔵 DRIVERS_PROVIDER: updateDriverLocation called');
    AppLogger.general('   Driver ID: ${location.driverId}');
    AppLogger.general('   Location: (${location.latitude}, ${location.longitude})');
    AppLogger.general('   Timestamp: ${location.timestamp}');
    AppLogger.general('   Current state type: ${state.runtimeType}');

    state.when(
      data: (drivers) {
        AppLogger.general('   ✅ State is AsyncData');
        AppLogger.general('   Current drivers count: ${drivers.length}');
        for (final driver in drivers) {
          AppLogger.general('      - ${driver.name} (${driver.driverId})');
        }

        var foundMatch = false;
        final updatedDrivers = drivers.map((driver) {
          if (driver.driverId == location.driverId) {
            foundMatch = true;
            AppLogger.general('   🎯 MATCH FOUND: ${driver.name}');
            AppLogger.general('      Old location: ${driver.lastLocation?.latitude}, ${driver.lastLocation?.longitude}');
            AppLogger.general('      New location: ${location.latitude}, ${location.longitude}');
            return driver.copyWith(lastLocation: location);
          }
          return driver;
        }).toList();

        if (!foundMatch) {
          AppLogger.general('   ⚠️  NO MATCH: Driver ${location.driverId} not found in list!');
        }

        AppLogger.general('   📝 Setting new state...');
        state = AsyncData(updatedDrivers);
        AppLogger.general('   ✅ State updated successfully');
        AppLogger.general('   New state contains ${updatedDrivers.length} drivers');
      },
      loading: () {
        AppLogger.general('   ⚠️  State is AsyncLoading - cannot update!');
      },
      error: (error, stack) {
        AppLogger.general('   ❌ State is AsyncError - cannot update!');
        AppLogger.general('      Error: $error');
      },
    );

    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Update a driver's shift status (called from WebSocket driver_shift_change)
  void updateDriverStatus(String driverId, String status, String? shiftId) {
    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.general('🔵 DRIVERS_PROVIDER: updateDriverStatus called');
    AppLogger.general('   Driver ID: $driverId');
    AppLogger.general('   Status: $status');
    AppLogger.general('   Shift ID: $shiftId');
    AppLogger.general('   Current state type: ${state.runtimeType}');

    state.when(
      data: (drivers) {
        AppLogger.general('   ✅ State is AsyncData');
        AppLogger.general('   Current drivers count: ${drivers.length}');

        var foundMatch = false;
        final updatedDrivers = drivers.map((driver) {
          if (driver.driverId == driverId) {
            foundMatch = true;
            AppLogger.general('   🎯 MATCH FOUND: ${driver.name}');
            AppLogger.general('      Old status: ${driver.status}');
            AppLogger.general('      New status: $status');

            // Parse string status to ShiftStatus enum
            final shiftStatus = _parseShiftStatus(status);

            // If shift ended/inactive, clear location to hide marker
            final updatedLocation = (shiftStatus == ShiftStatus.inactive ||
                    shiftStatus == ShiftStatus.ended)
                ? null
                : driver.lastLocation;

            AppLogger.general(
              '      Location cleared: ${updatedLocation == null && driver.lastLocation != null}',
            );

            return driver.copyWith(
              status: shiftStatus,
              shiftId: shiftId,
              lastLocation: updatedLocation,
            );
          }
          return driver;
        }).toList();

        if (!foundMatch) {
          AppLogger.general('   ⚠️  NO MATCH: Driver $driverId not found in list!');
        }

        AppLogger.general('   📝 Setting new state...');
        state = AsyncData(updatedDrivers);
        AppLogger.general('   ✅ State updated successfully');
      },
      loading: () {
        AppLogger.general('   ⚠️  State is AsyncLoading - cannot update!');
      },
      error: (error, stack) {
        AppLogger.general('   ❌ State is AsyncError - cannot update!');
        AppLogger.general('      Error: $error');
      },
    );

    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Parse string status to ShiftStatus enum
  ShiftStatus _parseShiftStatus(String status) {
    switch (status) {
      case 'ready':
        return ShiftStatus.ready;
      case 'active':
        return ShiftStatus.active;
      case 'paused':
        return ShiftStatus.paused;
      case 'ended':
        return ShiftStatus.ended;
      default:
        return ShiftStatus.inactive;
    }
  }

  /// Refresh the driver list
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDrivers());
  }
}
