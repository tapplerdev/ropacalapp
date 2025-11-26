# DETAILED CODE SNIPPETS FOR COPYING

## CRITICAL FIX #1: Add segmentProgress to useEffect dependencies

**Location:** driver_map_page.dart, Line 207
**Current Code:**
```dart
}, [binsState.value, locationState.value, routeState.value, markerCache, 
    simulationState.simulatedPosition, simulationState.isSimulating, 
    simulationState.routePolyline]);
```

**Fixed Code:**
```dart
}, [binsState.value, locationState.value, routeState.value, markerCache, 
    simulationState.simulatedPosition, simulationState.isSimulating, 
    simulationState.routePolyline,
    simulationState.segmentProgress,      // ADD THIS LINE - tracks smooth movement
    simulationState.currentSegmentIndex,  // ADD THIS LINE - tracks segment changes
]);
```

---

## CRITICAL FIX #2: Implement smooth polyline rendering with interpolation

**Location:** driver_map_page.dart, Lines 113-181
**Replace the entire polyline rendering logic with:**

```dart
// Add route polyline (independent of routeBins - works during simulation too!)
final routePoints = <LatLng>[];

// During simulation: use the detailed OSRM polyline with smooth interpolation
if (simulationState.isSimulating && simulationState.routePolyline.isNotEmpty) {
  // For simulation: show remaining route starting from CURRENT INTERPOLATED position
  if (simulationState.currentSegmentIndex < simulationState.routePolyline.length - 1) {
    // Calculate current interpolated position within segment (smooth!)
    final fromPoint = simulationState.routePolyline[simulationState.currentSegmentIndex];
    final toPoint = simulationState.routePolyline[simulationState.currentSegmentIndex + 1];
    
    // Interpolate between the two points based on segment progress
    final lat = fromPoint.latitude + 
        (toPoint.latitude - fromPoint.latitude) * simulationState.segmentProgress;
    final lng = fromPoint.longitude + 
        (toPoint.longitude - fromPoint.longitude) * simulationState.segmentProgress;
    final currentInterpolated = latlong.LatLng(lat, lng);
    
    // Start polyline from interpolated position (smooth vehicle position)
    routePoints.add(LatLng(currentInterpolated.latitude, currentInterpolated.longitude));
    
    // Add remaining route points (from next segment onwards)
    final remainingPoints = simulationState.routePolyline
        .skip(simulationState.currentSegmentIndex + 1);
    routePoints.addAll(
      remainingPoints.map((point) => LatLng(point.latitude, point.longitude))
    );
  } else {
    // At or near end of route
    routePoints.addAll(
      simulationState.routePolyline.map((point) =>
        LatLng(point.latitude, point.longitude)
      ),
    );
  }

  final routePolyline = Polyline(
    polylineId: const PolylineId('route'),
    points: routePoints,
    color: AppColors.primaryBlue,
    width: 8, // Thicker during simulation for visibility
    startCap: Cap.roundCap,
    endCap: Cap.roundCap,
    jointType: JointType.round,
    visible: true,
    zIndex: 100,
  );

  polylines.value = {routePolyline};

  AppLogger.map('✅ SIMULATION Route polyline set');
  AppLogger.map('   Remaining points: ${routePoints.length}');
  AppLogger.map('   Current segment: ${simulationState.currentSegmentIndex}/${simulationState.routePolyline.length - 1}');
  AppLogger.map('   Segment progress: ${(simulationState.segmentProgress * 100).toStringAsFixed(1)}%');
  AppLogger.map('   Color: ${routePolyline.color}');
  AppLogger.map('   Width: ${routePolyline.width}');
} else if (routeBins != null && routeBins.isNotEmpty) {
  // Normal mode: draw simple lines from current location through bins
  if (location != null) {
    routePoints.add(LatLng(location.latitude, location.longitude));
  }
  routePoints.addAll(
    routeBins
        .where((b) => b.latitude != null && b.longitude != null)
        .map((b) => LatLng(b.latitude!, b.longitude!)),
  );

  if (routePoints.isNotEmpty) {
    final routePolyline = Polyline(
      polylineId: const PolylineId('route'),
      points: routePoints,
      color: AppColors.primaryBlue,
      width: 4,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
      visible: true,
      zIndex: 100,
    );

    polylines.value = {routePolyline};

    AppLogger.map('✅ NORMAL Route polyline set');
    AppLogger.map('   Points: ${routePoints.length}');
  } else {
    polylines.value = {};
    AppLogger.map('❌ No route points to draw');
  }
} else {
  polylines.value = {};
  AppLogger.map('❌ No route polyline (not simulating, no routeBins)');
}
```

---

## CRITICAL FIX #3: Add camera throttling to prevent jank

**Location:** driver_map_page.dart, Lines 209-242
**Add this state at the top of the build method, after the other state declarations:**

```dart
// Camera update throttling to prevent animation conflicts
final lastCameraUpdate = useRef<DateTime>(DateTime.now());

// Smooth bearing to reduce rotation jitter
final smoothedBearing = useRef<double?>(null);
```

**Then replace the entire camera following useEffect with:**

```dart
// Camera following during simulation with throttling and smoothing
useEffect(() {
  if (!simulationState.isSimulating || 
      simulationState.simulatedPosition == null || 
      mapController.value == null) {
    return null;
  }

  // Schedule camera update for next frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mapController.value == null || simulationState.simulatedPosition == null) {
      return;
    }

    // Throttle camera updates to prevent animation conflicts
    final now = DateTime.now();
    if (now.difference(lastCameraUpdate.value).inMilliseconds < 100) {
      return; // Skip this update - too soon after last one
    }
    lastCameraUpdate.value = now;

    // Get raw bearing from simulation state
    final rawBearing = simulationState.bearing ?? 0.0;

    // Apply exponential smoothing to bearing to reduce jitter
    if (smoothedBearing.value == null) {
      smoothedBearing.value = rawBearing; // Initialize on first update
    } else {
      // Exponential moving average: 70% old value + 30% new value
      smoothedBearing.value = smoothedBearing.value! * 0.7 + rawBearing * 0.3;
    }
    final bearing = smoothedBearing.value!;

    // Select camera settings based on navigation mode
    final zoom = simulationState.isNavigationMode 
        ? BinConstants.navigationZoom 
        : 16.0;
    final tilt = simulationState.isNavigationMode 
        ? BinConstants.navigationTilt 
        : 0.0;
    final cameraBearing = simulationState.isNavigationMode 
        ? bearing 
        : 0.0; // North-up in 2D mode

    // Safely animate camera with error handling for disposed controller
    try {
      mapController.value!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: simulationState.simulatedPosition!,
            zoom: zoom,
            bearing: cameraBearing,
            tilt: tilt,
          ),
        ),
      );
    } catch (e) {
      // Controller was disposed - ignore error
      AppLogger.map('Camera animation skipped - controller disposed', 
                    level: AppLogger.debug);
    }
  });

  return null;
}, [
  simulationState.simulatedPosition,
  simulationState.isSimulating,
  simulationState.isNavigationMode,
  simulationState.bearing, // Watch bearing for smoothing
]);
```

---

## HIGH PRIORITY FIX #4: Add route bounds fitting on map creation

**Location:** driver_map_page.dart, Lines 266-279
**Replace the entire onMapCreated callback with:**

```dart
onMapCreated: (controller) {
  mapController.value = controller;
  AppLogger.map('🗺️  Google Map created');
  AppLogger.map('   Markers count: ${markers.value.length}');
  AppLogger.map('   Polylines count: ${polylines.value.length}');
  
  if (polylines.value.isNotEmpty) {
    final polyline = polylines.value.first;
    AppLogger.map('   Polyline points: ${polyline.points.length}');
    AppLogger.map('   Polyline color: ${polyline.color}');
    AppLogger.map('   Polyline visible: ${polyline.visible}');
    AppLogger.map('   Polyline width: ${polyline.width}');
    AppLogger.map('   Polyline zIndex: ${polyline.zIndex}');

    // Fit camera to show full route now that map is created
    if (polyline.points.isNotEmpty) {
      // Calculate bounds from all route points
      double minLat = polyline.points.first.latitude;
      double maxLat = polyline.points.first.latitude;
      double minLng = polyline.points.first.longitude;
      double maxLng = polyline.points.first.longitude;

      for (final point in polyline.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      AppLogger.map('📐 Fitting camera to route bounds');
      AppLogger.map('   Southwest: (${bounds.southwest.latitude}, ${bounds.southwest.longitude})');
      AppLogger.map('   Northeast: (${bounds.northeast.latitude}, ${bounds.northeast.longitude})');

      // Delay to ensure map is fully initialized
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100), // 100px padding
          ).then((_) {
            AppLogger.map('✅ Camera fitted to bounds successfully');
          }).catchError((e) {
            AppLogger.map('❌ Failed to fit camera to bounds: $e');
          });
        } catch (e) {
          AppLogger.map('❌ Error creating camera update: $e');
        }
      });
    }
  }
},
```

---

## HIGH PRIORITY FIX #5: Add blue dot overlay for 3D navigation mode

**Location:** driver_map_page.dart, Line 280 (after GoogleMap widget, before SafeArea)
**Add this code:**

```dart
// Custom overlay: Blue dot at screen center (3D navigation mode only)
// In 3D mode camera is locked to user position, so centered overlay works perfectly
if (simulationState.isNavigationMode && locationState.value != null)
  const NavigationBlueDotOverlay(),
```

**Important:** You need to import the widget at the top of the file:
```dart
import 'package:ropacalapp/features/driver/widgets/navigation_blue_dot_overlay.dart';
```

---

## HIGH PRIORITY FIX #6: Add route change detection

**Location:** driver_map_page.dart, after the markers/polylines useEffect (after line 207)
**Add this new useEffect:**

```dart
// Detect route changes and reset simulation indices
final lastRouteId = useState<String?>(null);

useEffect(() {
  if (simulationState.isSimulating && simulationState.routePolyline.isNotEmpty) {
    // Create a unique ID for this route (length + first point)
    final routeId = '${simulationState.routePolyline.length}_'
        '${simulationState.routePolyline.first.latitude.toStringAsFixed(6)}_'
        '${simulationState.routePolyline.first.longitude.toStringAsFixed(6)}';

    // If route changed while simulation is running, stop and reset
    if (lastRouteId.value != null && lastRouteId.value != routeId) {
      AppLogger.navigation('🔄 ROUTE CHANGED DURING SIMULATION! Resetting simulation');
      AppLogger.navigation('   Old route ID: ${lastRouteId.value}');
      AppLogger.navigation('   New route ID: $routeId');

      // Stop simulation and reset
      ref.read(simulationNotifierProvider.notifier).stopSimulation();
    }

    lastRouteId.value = routeId;
  }
  return null;
}, [simulationState.routePolyline]);
```

---

## SUPPORTING CHANGES: Import navigation_blue_dot_overlay

**Location:** Top of driver_map_page.dart file
**Add this import:**

```dart
import 'package:ropacalapp/features/driver/widgets/navigation_blue_dot_overlay.dart';
```

---

## SUPPORTING CHANGES: Import dart:math for bearing calculations

**Location:** Top of driver_map_page.dart file (should already be there, but verify)
```dart
import 'dart:math' as math;
```

---

## OPTIONAL IMPROVEMENT: Add interpolate helper function

**Location:** driver_map_page.dart, add as a method in the DriverMapPage class
```dart
// Interpolate between two points
latlong.LatLng interpolate(latlong.LatLng from, latlong.LatLng to, double progress) {
  final lat = from.latitude + (to.latitude - from.latitude) * progress;
  final lng = from.longitude + (to.longitude - from.longitude) * progress;
  return latlong.LatLng(lat, lng);
}
```

**Note:** In the critical fix #2 above, we use inline interpolation to keep code in one place. This helper function is optional if you prefer to extract it.

---

## OPTIONAL NICE-TO-HAVE: Copy wrong turn simulation

**Location:** navigation_page.dart, Lines 225-338
**If you want automated wrong turn testing, copy the entire `simulateWrongTurn()` method**

This includes:
- calculateBearing() method (already in provider)
- simulateWrongTurn() method
- Integration with animation pause/resume
- Extensive logging

---

## IMPLEMENTATION ORDER (PRIORITIZED)

1. **First:** Fix #3 (add state for camera throttling)
2. **Second:** Fix #1 (add dependencies)
3. **Third:** Fix #2 (implement smooth polyline rendering)
4. **Fourth:** Fix #5 (add blue dot overlay import + widget)
5. **Fifth:** Fix #4 (add route bounds fitting)
6. **Sixth:** Fix #6 (add route change detection)
7. **Seventh:** Test everything thoroughly
8. **Eighth:** Optional improvements and nice-to-haves

---

## VALIDATION CHECKLIST

After each fix, verify:

**After Fix #1 (dependencies):**
- [ ] No compilation errors
- [ ] App still runs without crashes

**After Fix #2 (polyline rendering):**
- [ ] Polyline shows during simulation
- [ ] Polyline starts from current position (not origin)
- [ ] Polyline updates as vehicle moves
- [ ] No "remaining points" calculation errors

**After Fix #3 (camera throttling):**
- [ ] Camera follows vehicle
- [ ] Bearing rotates smoothly
- [ ] No animation jank (should feel 60 FPS)
- [ ] Frame rate check: ~60 FPS (use DevTools)

**After Fix #4 (bounds fitting):**
- [ ] When starting simulation, map zooms to show entire route
- [ ] Initial view shows full route (optional, nice-to-have)

**After Fix #5 (blue dot overlay):**
- [ ] Blue dot appears at screen center in 3D mode
- [ ] Blue dot disappears when switching to 2D mode
- [ ] Blue dot is centered correctly

**After Fix #6 (route change detection):**
- [ ] If route changes, simulation stops gracefully
- [ ] No array out-of-bounds errors
- [ ] Polyline updates when route changes

---

## KNOWN LIMITATIONS IN DRIVER_MAP_PAGE

After implementing these fixes, the following limitations remain (compared to navigation_page):

1. No local animation controller (uses provider's Timer.periodic instead)
   - Impact: None - functionally equivalent
   - Fix: Only if you need different animation behavior

2. No wrong turn simulation
   - Impact: Can't test off-route detection
   - Fix: Copy simulateWrongTurn() if needed

3. No distance-to-bin display on map
   - Impact: Users don't see remaining distance
   - Fix: Add distance display to bottom panel

4. Camera only updates during isNavigationMode
   - Impact: 2D mode camera may not follow vehicle
   - Fix: Already fixed in Fix #3

5. No user zoom preference persistence
   - Impact: Zoom resets when toggling modes
   - Fix: Add useState for userZoom similar to navigation_page

