// Temporary stub - will be replaced with Google Navigation implementation
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mapbox_route_provider.g.dart';

@riverpod
class MapboxRouteMetadata extends _$MapboxRouteMetadata {
  @override
  dynamic build() => null;

  void clearRouteData() {
    state = null;
  }
}
