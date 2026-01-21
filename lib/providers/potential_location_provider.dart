import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/services/api_service.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

part 'potential_location_provider.g.dart';

/// Provider for creating potential location requests
@riverpod
class PotentialLocationNotifier extends _$PotentialLocationNotifier {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Create a new potential location request
  Future<void> createPotentialLocation({
    required String street,
    required String city,
    required String zip,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);

      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('📍 CREATING POTENTIAL LOCATION');
      AppLogger.general('   Street: $street');
      AppLogger.general('   City: $city');
      AppLogger.general('   ZIP: $zip');
      AppLogger.general('   GPS: ${latitude != null ? "$latitude, $longitude" : "Not provided"}');
      AppLogger.general('   Notes: ${notes ?? "None"}');

      await apiService.createPotentialLocation(
        street: street,
        city: city,
        zip: zip,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );

      AppLogger.general('   ✅ Potential location created successfully');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    });
  }

  /// Reset state after success
  void reset() {
    state = const AsyncValue.data(null);
  }
}
