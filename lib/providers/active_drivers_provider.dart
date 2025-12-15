import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/exceptions/shift_ended_exception.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/providers/api_provider.dart';
import 'package:ropacalapp/services/manager_service.dart';

part 'active_drivers_provider.g.dart';

/// Provider for ManagerService
@riverpod
ManagerService managerService(ManagerServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ManagerService(apiService);
}

/// Provider for active drivers list
@riverpod
class ActiveDrivers extends _$ActiveDrivers {
  @override
  Future<List<ActiveDriver>> build() async {
    return fetchActiveDrivers();
  }

  /// Fetch active drivers from backend
  Future<List<ActiveDriver>> fetchActiveDrivers() async {
    try {
      AppLogger.general('📋 Fetching active drivers...');

      final managerService = ref.read(managerServiceProvider);
      final data = await managerService.getActiveDrivers();

      final drivers = data
          .map((json) => ActiveDriver.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.general('✅ Loaded ${drivers.length} active driver(s)');

      return drivers;
    } catch (e, stack) {
      AppLogger.general(
        '❌ Error fetching active drivers: $e',
        level: AppLogger.error,
      );
      AppLogger.general('Stack trace: $stack');
      rethrow;
    }
  }

  /// Manually refresh active drivers list
  Future<void> refresh() async {
    AppLogger.general('🔄 Refreshing active drivers...');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => fetchActiveDrivers());
    AppLogger.general('✅ Active drivers refreshed');
  }
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
