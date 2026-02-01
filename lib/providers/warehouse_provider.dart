import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/warehouse_stop_calculator.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/services/config_service.dart';

part 'warehouse_provider.g.dart';

/// ConfigService provider
@riverpod
ConfigService configService(ConfigServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ConfigService(apiService);
}

/// Warehouse location provider - fetches from backend config
@riverpod
class WarehouseLocationNotifier extends _$WarehouseLocationNotifier {
  @override
  Future<WarehouseLocation> build() async {
    print('🏭 WarehouseLocationNotifier: Fetching warehouse location...');

    final configService = ref.read(configServiceProvider);
    final warehouse = await configService.getWarehouseLocation();

    print('🏭 WarehouseLocationNotifier: Got warehouse at ${warehouse.address}');
    return warehouse;
  }

  /// Manually refresh warehouse location
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final configService = ref.read(configServiceProvider);
      return await configService.getWarehouseLocation();
    });
  }
}
