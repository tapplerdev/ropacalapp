import 'package:freezed_annotation/freezed_annotation.dart';

part 'bin_move.freezed.dart';
part 'bin_move.g.dart';

@freezed
class BinMove with _$BinMove {
  const factory BinMove({
    required int id,
    @JsonKey(name: 'bin_id') required String binId,
    @JsonKey(name: 'moved_from') required String movedFrom,
    @JsonKey(name: 'moved_to') required String movedTo,
    @JsonKey(name: 'moved_on') required DateTime movedOn,
  }) = _BinMove;

  factory BinMove.fromJson(Map<String, dynamic> json) =>
      _$BinMoveFromJson(json);
}
