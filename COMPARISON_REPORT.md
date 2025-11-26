# DETAILED COMPARISON: navigation_page.dart vs driver_map_page.dart

## EXECUTIVE SUMMARY
**driver_map_page.dart is CRITICALLY INCOMPLETE for route simulation and polyline rendering.**

The working navigation_page.dart has extensive camera control, smooth polyline updates, and sophisticated bearing/heading management that are completely missing from driver_map_page.dart. This comparison reveals 6 critical gaps and 3 high-priority issues.

---

## 1. CAMERA CONTROL & FOLLOWING DURING SIMULATION

### navigation_page.dart (WORKING - Lines 657-744)
**Features:**
- Multi-mode camera system:
  - Navigation mode (3D): Close zoom (BinConstants.navigationZoom), tilted (BinConstants.navigationTilt), rotates with bearing
  - Map mode (2D): User zoom, flat (0° tilt), north-up (0° bearing)
- Sophisticated bearing smoothing (Lines 698-705):
  ```dart
  if (smoothedBearing.value == null) {
    smoothedBearing.value = rawBearing;
  } else {
    // Exponential moving average: 70% old + 30% new
    smoothedBearing.value = smoothedBearing.value! * BinConstants.bearingSmoothingFactor 
                           + rawBearing * (1 - BinConstants.bearingSmoothingFactor);
  }
  ```
- **Throttling mechanism** (Lines 708-712):
  ```dart
  final now = DateTime.now();
  if (now.difference(lastCameraUpdate.value).inMilliseconds < BinConstants.cameraUpdateThrottleMs) {
    return; // Skip this update
  }
  lastCameraUpdate.value = now;
  ```
- Uses WidgetsBinding.addPostFrameCallback() to prevent concurrent modifications (Line 663)
- Uses BOTH simulatedPosition AND navigationState bearing (Lines 672-681)
- Includes error handling with try-catch (Lines 716-731)
- Cleanup function returns isActive flag (Lines 735-737)

### driver_map_page.dart (CURRENT - Lines 209-242)
**Features:**
- MINIMAL camera control:
  ```dart
  CameraPosition(
    target: simulationState.simulatedPosition!,
    zoom: BinConstants.navigationZoom,
    bearing: simulationState.smoothedBearing ?? simulationState.bearing,
    tilt: BinConstants.navigationTilt,
  )
  ```
- **MISSING:** 2D map mode camera settings
- **MISSING:** Bearing smoothing (delegates to provider)
- **MISSING:** Throttling mechanism (will cause jank/animation conflicts)
- **MISSING:** Early return if not in navigationMode before camera update
- Has error handling but minimal
- **Problem:** Updates camera every single frame during simulation without throttling

### VERDICT: CRITICAL GAP
**Camera control in driver_map_page is 70% of navigation_page but missing:**
- Throttling (causes performance jitter)
- 2D mode support
- Local bearing smoothing
- User zoom preference in 2D

---

## 2. POLYLINE UPDATES & DYNAMIC RENDERING

### navigation_page.dart (WORKING - Lines 512-645)
**Features:**
- **Dynamic polyline that shows REMAINING route during simulation** (Lines 522-551):
  ```dart
  if (isSimulating.value && 
      currentSegmentIndex.value < navigationState.routePolyline.length - 1) {
    // Calculate current interpolated position within segment
    final fromPoint = navigationState.routePolyline[currentSegmentIndex.value];
    final toPoint = navigationState.routePolyline[currentSegmentIndex.value + 1];
    final currentInterpolated = interpolate(fromPoint, toPoint, segmentProgress.value);
    
    // Start polyline from interpolated position
    routeCoordinates = [
      LatLng(currentInterpolated.latitude, currentInterpolated.longitude),
    ];
    
    // Add remaining route points from next segment onwards
    final remainingPoints = navigationState.routePolyline.skip(currentSegmentIndex.value + 1);
    routeCoordinates.addAll(remainingPoints.map((point) => LatLng(point.latitude, point.longitude)));
  }
  ```
- Shows SMOOTH interpolated position as the polyline start (not just segment points)
- **Dependencies:** (Lines 637-645)
  ```dart
  [
    navigationState?.routePolyline,
    navigationState?.currentBinIndex,
    currentSimulationIndex.value,
    simulatedPosition.value,
    currentSegmentIndex.value,        // Track segment changes
    segmentProgress.value,             // Track smooth progress within segment
    markerCache,
  ]
  ```
- Includes extensive debugging comments (some commented out for performance)
- Polyline properties: 8px width, round caps, round joints, high zIndex (100)
- Creates ONE polyline object with proper IDs

### driver_map_page.dart (CURRENT - Lines 113-181)
**Features:**
- **Basic polyline that shows FULL route** (Lines 118-124):
  ```dart
  if (simulationState.isSimulating && simulationState.routePolyline.isNotEmpty) {
    routePoints.addAll(
      simulationState.routePolyline.map((point) => 
        LatLng(point.latitude, point.longitude)
      ),
    );
  }
  ```
- Shows entire remaining route, not just from current position
- **MISSING:** Smooth interpolation of current position
- **MISSING:** Showing "remaining route" concept
- **Dependencies:** (Line 207)
  ```dart
  [binsState.value, locationState.value, routeState.value, markerCache, 
   simulationState.simulatedPosition, simulationState.isSimulating, 
   simulationState.routePolyline]
  ```
- Has logging but less detailed
- Polyline properties: varies by mode (8px during simulation, 4px otherwise)
- Creates ONE polyline object

### VERDICT: HIGH PRIORITY GAP
**Polyline rendering is FUNCTIONALLY DIFFERENT:**
- navigation_page creates REMAINING ROUTE polylines (better UX)
- driver_map_page creates FULL ROUTE polylines (doesn't show progress)
- Missing smooth interpolation (showing exact vehicle position)

---

## 3. STATE MANAGEMENT & useEffect DEPENDENCIES

### navigation_page.dart (WORKING)
**useEffect #1: Route change detection** (Lines 65-89)
- Detects when route changes during active simulation
- Resets simulation indices
- Dependencies: `[navigationState?.routePolyline]`
- Scope: CRITICAL for preventing out-of-bounds errors

**useEffect #2: Polylines & Markers** (Lines 513-645)
- 7 dependencies in array:
  ```dart
  [
    navigationState?.routePolyline,      // Route changed
    navigationState?.currentBinIndex,    // Bin selection changed
    currentSimulationIndex.value,        // Vehicle moved
    simulatedPosition.value,             // Vehicle position changed
    currentSegmentIndex.value,           // Segment changed (smooth)
    segmentProgress.value,               // Smooth progress within segment
    markerCache,                         // Marker icons loaded
  ]
  ```
- **CRITICAL:** Watches segmentProgress (10+ FPS updates) for smooth polyline animation

**useEffect #3: Camera following** (Lines 658-744)
- 6 dependencies:
  ```dart
  [
    locationState.value,                // GPS location changed
    simulatedPosition.value,            // Simulated position changed
    navigationState?.currentBearing,    // Bearing changed
    isNavigationMode.value,             // Mode toggled
    isSimulating.value,                 // Simulation started/stopped
  ]
  ```
- Includes cleanup function

### driver_map_page.dart (CURRENT)
**useEffect #1: Markers & Polylines** (Lines 49-207)
- 7 dependencies:
  ```dart
  [binsState.value, locationState.value, routeState.value, markerCache, 
   simulationState.simulatedPosition, simulationState.isSimulating, 
   simulationState.routePolyline]
  ```
- **MISSING:** currentSegmentIndex
- **MISSING:** segmentProgress
- **MISSING:** currentBinIndex (is in navigationState in nav_page)
- Does NOT watch smooth segment progress

**useEffect #2: Camera following** (Lines 210-242)
- 5 dependencies:
  ```dart
  [simulationState.simulatedPosition, simulationState.isSimulating, 
   simulationState.isNavigationMode, simulationState.smoothedBearing]
  ```
- **MISSING:** locationState (only uses simulationState)
- **MISSING:** locationState for 2D mode

**MISSING useEffect:** Route change detection!

### VERDICT: CRITICAL GAP
**Missing dependencies = stale closure bugs:**
- segmentProgress not watched = polyline doesn't update on smooth movement
- currentSegmentIndex not in some dependencies = marker rendering lags
- No route change detection = potential array out-of-bounds

---

## 4. MAP CONTROLLER USAGE & CAMERA UPDATES

### navigation_page.dart (WORKING)
**Initial camera setup** (Lines 759-775):
```dart
final initialPosition = currentLocation != null
    ? CameraPosition(
        target: LatLng(currentLocation.latitude, currentLocation.longitude),
        zoom: 15.0,
        bearing: navigationState.currentBearing ?? 0.0,
        tilt: 0.0, // 2D flat view
      )
    : CameraPosition(
        target: LatLng(
          navigationState.currentLocation.latitude,
          navigationState.currentLocation.longitude,
        ),
        zoom: 15.0,
        bearing: navigationState.currentBearing ?? 0.0,
        tilt: 0.0,
      );
```

**onMapCreated callback** (Lines 793-844):
- Fits camera to route bounds AFTER map is created
- Uses LatLngBounds calculation (Lines 807-817)
- Delays 300ms for map initialization (Line 829)
- Includes error handling (Lines 835-840)

**animateCamera calls:**
- In camera useEffect (Line 717): Main camera following
- In onMapCreated (Line 831): Initial bounds fitting

### driver_map_page.dart (CURRENT)
**Initial camera setup** (Lines 254-257):
```dart
initialCameraPosition: CameraPosition(
  target: initialCenter,
  zoom: 10.0,
),
```
- STATIC zoom (10.0 vs navigation_page's 15.0 or dynamic)
- Uses useMemoized initialCenter (Lines 41-46)

**onMapCreated callback** (Lines 266-279):
- Only logs map creation
- **MISSING:** Route bounds fitting
- **MISSING:** Initial zoom adjustment

**animateCamera calls:**
- In camera useEffect (Line 224): Camera following
- In ActiveShiftBottomSheet.onNavigateToNextBin (Line 587): Animate to next bin
- In FloatingActionButton.onPressed recenter (Line 550): Manual recenter

### VERDICT: MEDIUM GAP
**Missing initial bounds fitting:**
- navigation_page fits route to screen after creation
- driver_map_page shows fixed zoom on initialCenter
- driver_map_page is ready for simulation but lacks initial route view

---

## 5. SIMULATION INTEGRATION

### navigation_page.dart (WORKING)
**State management** (Lines 31-48):
```dart
final mapController = useState<GoogleMapController?>(null);
final markers = useState<Set<Marker>>({});
final polylines = useState<Set<Polyline>>({});
final userZoomLevel = useState<double>(16.0);
final isSimulating = useState<bool>(false);
final currentSimulationIndex = useState<int>(0);
final simulatedPosition = useState<LatLng?>(null);

// Smooth interpolation
final currentSegmentIndex = useState<int>(0);
final segmentProgress = useState<double>(0.0);

// Animation
final animationController = useAnimationController(duration: const Duration(seconds: 60));
final routeProgress = useState<double>(0.0);

// Route tracking
final lastRouteId = useState<String?>(null);

// Navigation mode
final isNavigationMode = useState<bool>(false);

// Camera throttling
final lastCameraUpdate = useRef<DateTime>(DateTime.now());

// Bearing smoothing
final smoothedBearing = useRef<double?>(null);
```

**Simulation function** (Lines 341-510):
- startSimulation() handles BOTH start and stop (toggle)
- Creates animation controller with dynamic duration
- Adds listener for 60 FPS updates
- Logs frame count and progress
- Updates BOTH location provider AND navigation provider
- Includes state reset logic
- Pauses/resumes animation on wrong turn

**Polyline updates** (Lines 513-645):
- Watches segmentProgress for smooth updates
- Shows interpolated position
- Shows remaining route

### driver_map_page.dart (CURRENT)
**State management** (Lines 35):
```dart
final simulationState = ref.watch(simulationNotifierProvider);
```
- DELEGATES to simulation provider
- Does NOT maintain local state
- Watches: isSimulating, simulatedPosition, routePolyline, isNavigationMode, bearing, smoothedBearing, currentSegmentIndex, segmentProgress

**Camera following** (Lines 210-242):
- Watches simulation state updates
- Does NOT update location provider
- Does NOT update navigation provider

**Polyline updates** (Lines 113-181):
- Watches simulationState.routePolyline
- Shows full route, not remaining route

### VERDICT: ARCHITECTURAL DIFFERENCE
**navigation_page: LOCAL simulation logic**
- Runs AnimationController locally
- Updates providers FROM animation
- Has fine-grained state control

**driver_map_page: DELEGATED simulation logic**
- Uses simulation_provider for logic
- Watches provider state
- Cleaner separation but less control

**For route simulation to work, driver_map_page needs:**
- To watch segmentProgress for smooth polyline updates
- To calculate interpolated position for polyline start
- Route change detection

---

## 6. BEARING & HEADING UPDATES

### navigation_page.dart (WORKING - Lines 91-103, 698-705)

**Bearing calculation:**
```dart
double calculateBearing(latlong.LatLng from, latlong.LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLon = (to.longitude - from.longitude) * math.pi / 180;
  
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  
  final bearing = math.atan2(y, x) * 180 / math.pi;
  return (bearing + 360) % 360;
}
```

**Bearing smoothing (LOCAL):**
```dart
if (smoothedBearing.value == null) {
  smoothedBearing.value = rawBearing;
} else {
  // Exponential moving average: 70% old + 30% new
  smoothedBearing.value = smoothedBearing.value! * 0.7 + rawBearing * 0.3;
}
```

**Source of bearing:**
- Navigation mode: gpsHeading if valid, else navigationState.currentBearing
- Map mode: 0.0 (north-up)

### driver_map_page.dart (CURRENT - Lines 229)
**Bearing smoothing:**
```dart
bearing: simulationState.smoothedBearing ?? simulationState.bearing,
```

**Bearing calculation:** IN PROVIDER
- Calculated in simulation_provider.startSimulation()
- Smoothing ALSO in provider (Lines 238-242)

### VERDICT: SUFFICIENT
**Both approaches work:**
- navigation_page: Local calculation + local smoothing
- driver_map_page: Provider calculation + provider smoothing

**BUT:** driver_map_page is MISSING bearing calculation during non-simulation!

---

## 7. SPEED UPDATES

### navigation_page.dart (WORKING)
**Speed handling:**
- Constant BinConstants.simulationSpeed used
- Updated in location provider (Line 480):
  ```dart
  ref.read(currentLocationProvider.notifier).setSimulatedLocation(
    latitude: currentPosition.latitude,
    longitude: currentPosition.longitude,
    speed: speed,  // BinConstants.simulationSpeed
    heading: bearing,
  );
  ```
- Also updates navigation provider (Line 488)

### driver_map_page.dart (CURRENT)
**Speed handling:**
- NOT directly handled
- Delegated to simulation_provider
- Does NOT display speed on map

### VERDICT: NEUTRAL
**Both sufficient for simulation.**

---

## 8. DISTANCE CALCULATIONS

### navigation_page.dart (WORKING - Lines 105-118, 128-141, 144-199)
**Three distance-related functions:**
1. **calculateDistance()** - Direct distance between two points
2. **calculateRouteDistances()** - Total route distance + cumulative array
3. **getPositionAtProgress()** - Position at specific progress along route
4. **_calculateDistanceToCurrentBin()** - Distance to next bin

### driver_map_page.dart (CURRENT)
**Distance handling:**
- Uses simulation_provider's calculations
- No local distance functions
- No distance display on map

### VERDICT: NEUTRAL
**navigation_page more thorough, but driver_map_page delegates properly.**

---

## 9. MARKER & LOCATION RENDERING

### navigation_page.dart (WORKING - Lines 581-630)
**Markers created:**
1. Destination bin markers (Lines 582-607)
2. Current location blue dot (Lines 609-628) - IN 2D MODE ONLY
3. Blue dot overlay (Line 851) - IN 3D NAVIGATION MODE

**Logic:**
- Use marker for 2D mode
- Use overlay for 3D mode
- Cache-based marker creation

### driver_map_page.dart (CURRENT - Lines 183-203)
**Marker for user location:**
```dart
final userPosition = simulationState.simulatedPosition ?? (location != null
  ? LatLng(location.latitude, location.longitude)
  : null);

if (userPosition != null) {
  final blueDotIcon = ref.read(binMarkerCacheNotifierProvider.notifier).getBlueDotMarker();
  
  newMarkers.add(
    Marker(
      markerId: const MarkerId('user_location'),
      position: userPosition,
      icon: blueDotIcon ?? BitmapDescriptor.defaultMarker,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      zIndex: 1000,
    ),
  );
}
```

### VERDICT: SUFFICIENT
**Both handle markers properly.**
**BUT:** driver_map_page is MISSING overlay for 3D mode!

---

## 10. WRONG TURN SIMULATION

### navigation_page.dart (WORKING - Lines 225-338)
**Features:**
- simulateWrongTurn() method (Lines 225-338)
- Calculates perpendicular direction (90° turn)
- Moves 75 meters off-route
- Updates location provider
- Pauses/resumes animation
- COMMENTED OUT: Automated wrong turn schedule
- Extensive logging

### driver_map_page.dart (CURRENT)
**Features:**
- NO wrong turn simulation
- Not needed for basic route simulation

### VERDICT: NICE-TO-HAVE
**Not critical for basic simulation, but available in navigation_page if needed.**

---

## 11. NAVIGATION MODE (2D/3D)

### navigation_page.dart (WORKING - Lines 56, 917-922)
**State management:**
```dart
final isNavigationMode = useState<bool>(false);
```

**Toggle functionality:**
```dart
onToggleNavigationMode: () {
  isNavigationMode.value = !isNavigationMode.value;
  AppLogger.navigation(
    '🧭 Navigation mode toggled: ${isNavigationMode.value ? "ON (3D)" : "OFF (2D)"}',
  );
},
```

**Effect on camera:**
- 3D mode: Close zoom (14), 45° tilt, rotates with bearing
- 2D mode: User zoom (16), 0° tilt, north-up

**Effect on blue dot:**
- 3D mode: Overlay at screen center
- 2D mode: Marker at position

### driver_map_page.dart (CURRENT)
**State management:**
```dart
final simulationState = ref.watch(simulationNotifierProvider);
// Uses: simulationState.isNavigationMode
```

**Toggle functionality:**
- In simulation_provider.toggleNavigationMode() (Line 295)
- Updates isNavigationMode in state

**Effect on camera:**
- 3D mode: Only when isNavigationMode (Lines 216-218)
- No 2D mode camera settings

**Effect on blue dot:**
- Always uses marker
- No overlay for 3D mode

### VERDICT: HIGH PRIORITY GAP
**Missing 3D mode features:**
- Blue dot overlay for 3D navigation
- No smooth camera transitions between modes
- Camera only updates in 3D mode (2D mode ignored in simulation)

---

## 12. ANIMATION CONTROLLER & 60 FPS

### navigation_page.dart (WORKING - Lines 44, 397-507)
**Animation setup:**
```dart
final animationController = useAnimationController(duration: const Duration(seconds: 60));
```

**In startSimulation():**
- Creates dynamic duration based on route length
- Attaches listener for 60 FPS updates
- Adds status listener for cleanup
- Logs frame count

### driver_map_page.dart (CURRENT)
**Animation setup:**
- DELEGATED to simulation_provider
- Timer.periodic(Duration(milliseconds: 16)) in provider (Line 206)

### VERDICT: EQUIVALENT
**Both achieve 60 FPS, different approaches:**
- navigation_page: AnimationController (Flutter-native)
- driver_map_page: Timer.periodic (more control)

---

## CRITICAL ISSUES SUMMARY

### CRITICAL (Must Fix Immediately)
1. **segmentProgress not in useEffect dependencies** (Line 207)
   - Polyline won't update smoothly during simulation
   - Impact: Stuttering polyline animation
   - Fix: Add segmentProgress.value to dependencies

2. **currentSegmentIndex not in useEffect dependencies** (Line 207)
   - Marker updates may lag
   - Impact: Markers show stale positions
   - Fix: Add simulationState.currentSegmentIndex to dependencies

3. **Missing route change detection** (Lines 49-207)
   - If route changes during simulation, no reset
   - Impact: Out-of-bounds array errors
   - Fix: Add useEffect to detect route changes and reset indices

4. **Polyline shows FULL route instead of REMAINING route** (Lines 118-124)
   - Doesn't show progress clearly
   - Impact: Poor UX during simulation
   - Fix: Implement interpolation logic from navigation_page

5. **Camera throttling missing** (Lines 210-242)
   - Updates every single frame (60+ FPS)
   - Impact: Animation jank, battery drain
   - Fix: Add throttling mechanism (100-200ms intervals)

6. **No 2D map mode camera support** (Lines 210-242)
   - Can't switch modes during simulation
   - Impact: Locked in 3D mode
   - Fix: Add isNavigationMode check and 2D camera settings

### HIGH PRIORITY (Fix Before Release)
7. **Missing blue dot overlay for 3D mode** (Lines 252-280)
   - 3D navigation experience incomplete
   - Fix: Add NavigationBlueDotOverlay widget (from navigation_page)

8. **No initial route bounds fitting** (Lines 266-279)
   - Map doesn't zoom to show full route
   - Fix: Add bounds calculation in onMapCreated (from navigation_page)

9. **Camera update not throttled** (Lines 221-222)
   - addPostFrameCallback every frame without throttling
   - Impact: Janky animations
   - Fix: Add DateTime-based throttling

### MEDIUM PRIORITY (Nice-to-Have)
10. **Missing wrong turn simulation** (Lines 225-338 in nav_page)
    - Automation testing feature not available
    - Fix: Copy simulateWrongTurn() method if needed

11. **No navigation state dependency in camera effect** (Line 242)
    - In 2D mode, current bearing not used
    - Impact: Inconsistent bearing source
    - Fix: Add navigationState to dependencies for fallback

12. **Missing bearing calculation for non-simulation**
    - Only bearing in navigation provider
    - Impact: Inconsistent bearing sources
    - Fix: Add bearing calculation in provider for non-simulation modes

---

## EXACT CODE TO COPY

### 1. Copy segmentProgress tracking (ADD to state)
```dart
// In build() method, after simulationState watch:
// GET from simulation_provider.state.segmentProgress
// Then watch it in useEffect:
// [simulationState.segmentProgress]  // ADD THIS
```

### 2. Copy route change detection (ADD new useEffect)
```dart
useEffect(() {
  if (simulationState.isSimulating && simulationState.routePolyline.isNotEmpty) {
    // Detect route changes and reset indices
    final routeId = '${simulationState.routePolyline.length}_'
        '${simulationState.routePolyline.first.latitude.toStringAsFixed(6)}_'
        '${simulationState.routePolyline.first.longitude.toStringAsFixed(6)}';
    
    // Reset if route changed (implementation from navigation_page lines 72-84)
  }
  return null;
}, [simulationState.routePolyline]);
```

### 3. Copy smooth polyline rendering (REPLACE lines 118-124)
```dart
if (simulationState.isSimulating && 
    simulationState.routePolyline.isNotEmpty &&
    simulationState.currentSegmentIndex < simulationState.routePolyline.length - 1) {
  // From navigation_page lines 522-551:
  // Calculate interpolated position
  // Create polyline from interpolated point
  // Add remaining route
}
```

### 4. Copy camera throttling (ADD to camera useEffect)
```dart
final lastCameraUpdate = useRef<DateTime>(DateTime.now());

// In camera useEffect, before animateCamera:
final now = DateTime.now();
if (now.difference(lastCameraUpdate.value).inMilliseconds < 100) {
  return null;
}
lastCameraUpdate.value = now;
```

### 5. Copy bearing smoothing (ADD to camera useEffect)
```dart
final smoothedBearing = useRef<double?>(null);

// In camera useEffect:
final rawBearing = simulationState.bearing ?? 0.0;
if (smoothedBearing.value == null) {
  smoothedBearing.value = rawBearing;
} else {
  smoothedBearing.value = smoothedBearing.value! * 0.7 + rawBearing * 0.3;
}
```

### 6. Copy blue dot overlay (ADD to Stack)
```dart
if (simulationState.isNavigationMode && locationState.value != null)
  const NavigationBlueDotOverlay(),
```

### 7. Copy route bounds fitting (ADD to onMapCreated)
```dart
// From navigation_page lines 804-844:
Future.delayed(const Duration(milliseconds: 300), () {
  try {
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  } catch (e) {
    AppLogger.map('Error fitting bounds: $e');
  }
});
```

### 8. Copy 2D mode camera settings (ADD to camera useEffect)
```dart
final zoom = simulationState.isNavigationMode 
    ? BinConstants.navigationZoom 
    : 16.0;
final tilt = simulationState.isNavigationMode 
    ? BinConstants.navigationTilt 
    : 0.0;
final bearing = simulationState.isNavigationMode 
    ? (smoothedBearing.value ?? 0.0)
    : 0.0;
```

---

## TESTING CHECKLIST

After implementing fixes:

1. **Polyline Rendering**
   - [ ] Polyline shows remaining route (not full route)
   - [ ] Polyline updates smoothly (no jank)
   - [ ] Polyline starts from interpolated position (not segment point)

2. **Camera Control**
   - [ ] Camera follows vehicle smoothly
   - [ ] Camera updates 1-2x per second (not every frame)
   - [ ] Bearing rotates smoothly (no jitter)
   - [ ] Can toggle 2D/3D mode and camera adapts
   - [ ] Zoom level persists in 2D mode

3. **Route Changes**
   - [ ] If route changes during simulation, indices reset
   - [ ] No array out-of-bounds errors
   - [ ] Polyline updates immediately

4. **3D Navigation Mode**
   - [ ] Blue dot overlay visible at screen center
   - [ ] Blue dot disappears in 2D mode
   - [ ] Marker shows in 2D mode

5. **Performance**
   - [ ] Frame rate stays 60 FPS
   - [ ] No animation conflicts
   - [ ] Battery drain acceptable

