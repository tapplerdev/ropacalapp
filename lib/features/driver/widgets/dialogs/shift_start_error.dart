import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ropacalapp/features/driver/widgets/dialogs/location_permission_dialog.dart';

/// The single place that decides how a failed shift start is shown to a driver.
///
/// There are two Start buttons — [driver_map_page] and [shift_acceptance_page]
/// — and they used to disagree. One mapped GPS failures onto the location
/// dialog; the other dumped the raw exception into a red SnackBar, which is how
/// a driver ended up reading "Exception: GPS_TIMEOUT_NEW_STREAM" in the field.
///
/// The matching is case-insensitive on purpose: the strings that reach here are
/// a mix of SCREAMING_SNAKE sentinels we throw ourselves
/// (LOCATION_PERMISSION_DENIED) and plugin exception text
/// (PermissionDeniedException, LocationServiceDisabledException). The old
/// checks tested `contains('location')` and `contains('Location')`, so an
/// upper-case sentinel slipped through both.
Future<void> showShiftStartError(BuildContext context, Object error) async {
  final text = error.toString().toLowerCase();

  final isLocationProblem = error is TimeoutException ||
      text.contains('location') ||
      text.contains('gps') ||
      text.contains('permission');

  if (isLocationProblem) {
    await showLocationPermissionDialog(context);
    return;
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Failed to start shift: $error'),
      backgroundColor: Colors.red,
    ),
  );
}
