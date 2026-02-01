import 'package:ropacalapp/core/services/api_service.dart';
import 'package:ropacalapp/core/utils/warehouse_stop_calculator.dart';

/// Service for fetching app configuration from backend
class ConfigService {
  final ApiService _apiService;

  ConfigService(this._apiService);

  /// Get warehouse location from backend config
  Future<WarehouseLocation> getWarehouseLocation() async {
    try {
      print('📤 REQUEST: GET /api/config/warehouse');

      final response = await _apiService.get('/api/config/warehouse');

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      final data = response.data as Map<String, dynamic>;

      final warehouse = WarehouseLocation(
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
        address: data['address'] as String,
      );

      print('   ✅ Warehouse location: ${warehouse.address}');
      return warehouse;
    } catch (e) {
      print('   ❌ ERROR fetching warehouse: $e');
      rethrow;
    }
  }
}
