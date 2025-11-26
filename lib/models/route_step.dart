import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'route_step.freezed.dart';
part 'route_step.g.dart';

@freezed
class RouteStep with _$RouteStep {
  const factory RouteStep({
    required String instruction,
    required double distance, // in meters
    required double duration, // in seconds
    required String maneuverType, // "turn-left", "turn-right", "straight", etc.
    required LatLng location,
    String? modifier, // "left", "right", "slight left", etc.
    String? name, // Street name
  }) = _RouteStep;

  factory RouteStep.fromJson(Map<String, dynamic> json) =>
      _$RouteStepFromJson(json);
}

// Custom JSON converter for LatLng
class LatLngConverter implements JsonConverter<LatLng, List<dynamic>> {
  const LatLngConverter();

  @override
  LatLng fromJson(List<dynamic> json) {
    return LatLng(
      json[1] as double,
      json[0] as double,
    ); // OSRM returns [lon, lat]
  }

  @override
  List<dynamic> toJson(LatLng object) => [object.longitude, object.latitude];
}
