import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/route.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';

part 'routes_provider.g.dart';

/// Provider for fetching route templates from the backend.
/// Routes are blueprints that define a sequence of bins to visit.
@riverpod
class RoutesNotifier extends _$RoutesNotifier {
  @override
  Future<List<RouteTemplate>> build() async {
    AppLogger.general('📋 RoutesNotifier: Fetching routes from backend...');

    final managerService = ref.read(managerServiceProvider);
    final routesJson = await managerService.getRoutes();

    // For each route, fetch the full details with bins
    final routes = <RouteTemplate>[];
    for (final routeJson in routesJson) {
      final routeId = routeJson['id'] as String;
      try {
        final fullRoute = await managerService.getRouteWithBins(routeId);
        routes.add(RouteTemplate.fromJson(fullRoute));
      } catch (e) {
        AppLogger.general('⚠️ Failed to fetch route $routeId: $e');
        // Still add the route without bins
        routes.add(RouteTemplate.fromJson(routeJson));
      }
    }

    AppLogger.general('📋 RoutesNotifier: Loaded ${routes.length} routes');
    return routes;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}
