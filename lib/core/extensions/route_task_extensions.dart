import 'dart:convert';

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

  /// Skip reason recorded by the backend's SkipTask in task_data.
  /// Every RouteTask-producing endpoint sends task_data as an inline JSON
  /// object, so the direct keys are the live path; the base64 loop below is
  /// a defensive fallback only.
  String? get skipReason {
    if (!skipped || taskData == null) return null;
    final data = taskData!;

    if (data.containsKey('skip_reason')) {
      return data['skip_reason'] as String?;
    }
    if (data.containsKey('reason')) {
      return data['reason'] as String?;
    }

    for (final value in data.values) {
      if (value is String && value.length > 10) {
        try {
          final decoded = utf8.decode(base64.decode(value));
          final parsed = json.decode(decoded) as Map<String, dynamic>;
          return parsed['skip_reason'] as String? ??
              parsed['reason'] as String?;
        } catch (_) {
          // Not base64 JSON, keep looking
        }
      }
    }

    return null;
  }
}
