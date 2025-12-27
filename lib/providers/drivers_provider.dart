import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/exceptions/shift_ended_exception.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/driver_location.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/api_provider.dart';
import 'package:ropacalapp/services/manager_service.dart';

part 'drivers_provider.g.dart';

/// Provider for ManagerService
@riverpod
ManagerService managerService(ManagerServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ManagerService(apiService);
}

/// Provider for managing list of drivers (for manager dashboard)
/// This provider is WebSocket-enabled for real-time updates
@Riverpod(keepAlive: true)
class DriversNotifier extends _$DriversNotifier {
  @override
  Future<List<ActiveDriver>> build() async {
    // Fetch initial list of drivers
    return _fetchDrivers();
  }

  /// Fetch all drivers from backend
  Future<List<ActiveDriver>> _fetchDrivers() async {
    try {
      AppLogger.general('🚗 Fetching all drivers...');

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/api/manager/drivers');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> driversJson = data['data'];

        final drivers = driversJson.map((json) {
          return ActiveDriver.fromJson(json as Map<String, dynamic>);
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
    AppLogger.general('   Location: (${location.latitude}, ${location.longitude}');
    AppLogger.general('   Current state type: ${state.runtimeType}');

    state.when(
      data: (drivers) {
        AppLogger.general('   ✅ State is AsyncData');
        AppLogger.general('   Current drivers count: ${drivers.length}');
        for (final driver in drivers) {
          AppLogger.general('      - ${driver.driverName} (${driver.driverId})');
        }

        var foundMatch = false;
        final updatedDrivers = drivers.map((driver) {
          if (driver.driverId == location.driverId) {
            foundMatch = true;
            AppLogger.general('   🎯 MATCH FOUND: ${driver.driverName}');
            AppLogger.general('      Old location: ${driver.currentLocation?.latitude}, ${driver.currentLocation?.longitude}');
            AppLogger.general('      New location: ${location.latitude}, ${location.longitude}');
            return driver.copyWith(currentLocation: location);
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
            AppLogger.general('   🎯 MATCH FOUND: ${driver.driverName}');
            AppLogger.general('      Old status: ${driver.status}');
            AppLogger.general('      New status: $status');

            // Parse string status to ShiftStatus enum
            final shiftStatus = _parseShiftStatus(status);

            // If shift ended/inactive, clear location to hide marker
            final updatedLocation = (shiftStatus == ShiftStatus.inactive ||
                    shiftStatus == ShiftStatus.ended)
                ? null
                : driver.currentLocation;

            AppLogger.general(
              '      Location cleared: ${updatedLocation == null && driver.currentLocation != null}',
            );

            return driver.copyWith(
              status: shiftStatus,
              shiftId: shiftId ?? '',
              currentLocation: updatedLocation,
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

/// Provider for active drivers list (WebSocket-enabled)
/// Filters driversNotifierProvider for only active drivers
@riverpod
Future<List<ActiveDriver>> activeDrivers(ActiveDriversRef ref) async {
  final allDrivers = await ref.watch(driversNotifierProvider.future);

  // Filter for only active drivers (not idle/inactive)
  return allDrivers.where((driver) {
    return driver.status == ShiftStatus.active ||
           driver.status == ShiftStatus.paused ||
           driver.status == ShiftStatus.ready;
  }).toList();
}

/// Provider for a single driver's detailed shift information
@riverpod
class DriverShiftDetail extends _$DriverShiftDetail {
  @override
  Future<DriverShiftDetailData> build(String driverId) async {
    return fetchDriverShiftDetail(driverId);
  }

  /// Fetch detailed shift information with bins
  /// Throws [ShiftEndedException] if the shift has ended
  Future<DriverShiftDetailData> fetchDriverShiftDetail(String driverId) async {
    try {
      AppLogger.general('📋 Fetching driver shift details for: $driverId');

      final managerService = ref.read(managerServiceProvider);
      final data = await managerService.getDriverShiftDetails(driverId);

      // If data is null, the shift has ended (404 response)
      if (data == null) {
        AppLogger.general('ℹ️  Shift has ended for driver: $driverId');
        throw ShiftEndedException(driverId);
      }

      // Parse driver and shift info
      final driver = ActiveDriver.fromJson(data);

      // Parse bins array
      final bins = (data['bins'] as List)
          .map((json) => RouteBin.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.general('✅ Loaded driver shift with ${bins.length} bins');

      return DriverShiftDetailData(driver: driver, bins: bins);
    } catch (e, stack) {
      // If it's already a ShiftEndedException, just rethrow
      if (e is ShiftEndedException) {
        rethrow;
      }

      AppLogger.general(
        '❌ Error fetching driver shift details: $e',
        level: AppLogger.error,
      );
      AppLogger.general('Stack trace: $stack');
      rethrow;
    }
  }
}

/// Data class combining driver info with their route bins
class DriverShiftDetailData {
  final ActiveDriver driver;
  final List<RouteBin> bins;

  DriverShiftDetailData({required this.driver, required this.bins});
}
