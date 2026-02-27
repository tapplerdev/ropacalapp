import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';

part 'bin.freezed.dart';
part 'bin.g.dart';

@freezed
class Bin with _$Bin {
  const factory Bin({
    required String id,
    @JsonKey(name: 'bin_number') required int binNumber,
    @JsonKey(name: 'current_street') required String currentStreet,
    required String city,
    required String zip,
    @JsonKey(name: 'last_moved') DateTime? lastMoved,
    @JsonKey(name: 'last_checked') DateTime? lastChecked,
    required BinStatus status,
    @JsonKey(name: 'fill_percentage') int? fillPercentage,
    @Default(false) bool checked,
    @JsonKey(name: 'move_requested') @Default(false) bool moveRequested,
    @JsonKey(name: 'move_request_id') String? moveRequestId,
    double? latitude,
    double? longitude,
  }) = _Bin;

  const Bin._();

  factory Bin.fromJson(Map<String, dynamic> json) => _$BinFromJson(json);

  /// Computed address field for compatibility with RouteTask address pattern
  String get address {
    final parts = <String>[];
    if (currentStreet.isNotEmpty) parts.add(currentStreet);
    if (city.isNotEmpty) parts.add(city);
    if (zip.isNotEmpty) parts.add(zip);
    return parts.isEmpty ? 'No address' : parts.join(', ');
  }
}
