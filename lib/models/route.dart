import 'package:freezed_annotation/freezed_annotation.dart';

part 'route.freezed.dart';
part 'route.g.dart';

@freezed
class RouteTemplate with _$RouteTemplate {
  const factory RouteTemplate({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'geographic_area') @Default('') String geographicArea,
    @JsonKey(name: 'bin_count') @Default(0) int binCount,
    @JsonKey(name: 'estimated_duration_hours') double? estimatedDurationHours,
    @JsonKey(name: 'created_at') required int createdAt,
    @JsonKey(name: 'updated_at') required int updatedAt,
    @Default([]) List<RouteBin> bins,
  }) = _RouteTemplate;

  factory RouteTemplate.fromJson(Map<String, dynamic> json) =>
      _$RouteTemplateFromJson(json);
}

@freezed
class RouteBin with _$RouteBin {
  const factory RouteBin({
    required String id,
    @JsonKey(name: 'bin_number') required int binNumber,
    @JsonKey(name: 'current_street') @Default('') String currentStreet,
    @Default('') String city,
    @Default('') String zip,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'fill_percentage') int? fillPercentage,
    @Default('active') String status,
    @JsonKey(name: 'sequence_order') @Default(0) int sequenceOrder,
  }) = _RouteBin;

  const RouteBin._();

  factory RouteBin.fromJson(Map<String, dynamic> json) =>
      _$RouteBinFromJson(json);

  String get address {
    final parts = <String>[];
    if (currentStreet.isNotEmpty) parts.add(currentStreet);
    if (city.isNotEmpty) parts.add(city);
    if (zip.isNotEmpty) parts.add(zip);
    return parts.isEmpty ? 'No address' : parts.join(', ');
  }
}
