import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider to hold the driver map controller
/// This allows the map widget to remain stable while other components can access the controller
/// Using StateProvider to avoid build_runner circular dependency issues
final driverMapControllerProvider =
    StateProvider<GoogleMapViewController?>((ref) => null);

/// Provider to hold the manager map controller
/// This allows the map widget to remain stable while other components can access the controller
/// Using StateProvider to avoid build_runner circular dependency issues
final managerMapControllerProvider =
    StateProvider<GoogleNavigationViewController?>((ref) => null);
