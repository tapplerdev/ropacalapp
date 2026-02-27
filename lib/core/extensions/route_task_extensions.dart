import 'package:ropacalapp/models/route_task.dart';

/// Extension methods for RouteTask to handle nullable fields safely
extension RouteTaskExtensions on RouteTask {
  /// Get non-null address with fallback
  String get safeAddress => address ?? 'No address';

  /// Get non-null fill percentage with fallback
  int get safeFillPercentage => fillPercentage ?? 0;

  /// Get non-null bin number with fallback
  int get safeBinNumber => binNumber ?? 0;

  /// Get non-null bin ID with fallback
  String get safeBinId => binId ?? '';

  /// Check if address is empty or null
  bool get hasAddress => address != null && address!.isNotEmpty;

  /// Check if this task has a valid bin reference
  bool get hasBin => binId != null && binId!.isNotEmpty;
}
