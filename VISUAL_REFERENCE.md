# VISUAL REFERENCE CARD

## QUICK DIAGNOSIS

Do you have these problems in driver_map_page.dart during route simulation?

- [ ] Polyline doesn't update smoothly (stutters)
  → FIX #2: Implement smooth polyline with interpolation
  
- [ ] Camera movements are jerky/janky
  → FIX #3: Add camera throttling (100ms)
  
- [ ] Polyline shows entire route, not remaining route
  → FIX #2: Switch to remaining route rendering
  
- [ ] Blue dot missing in 3D navigation mode
  → FIX #5: Add NavigationBlueDotOverlay widget
  
- [ ] Map doesn't zoom to show full route on startup
  → FIX #4: Add route bounds fitting in onMapCreated
  
- [ ] App crashes if route changes during simulation
  → FIX #6: Add route change detection useEffect

All 6 problems? Check them all in CODE_SNIPPETS_REFERENCE.md

---

## PRIORITY MATRIX

```
        IMPACT
        High    Medium   Low
EFFORT  
Easy    [5]     [6]      []
        Blue    Route    Wrong
        Dot     Change   Turn
        Overlay Detection

Medium  [1]     [4]      []
        Deps    Bounds
        
Hard    [2]     [3]      []
        Polyline Camera
        Rendering Throttling
```

Read from top-left (highest priority) to bottom-right

---

## DEPENDENCY FLOW

```
simulationState
├── isSimulating ─────────────────┐
├── simulatedPosition ────────────┼─── useEffect #1 (Polylines)
├── routePolyline ───────────────┼─── Triggers every N changes
├── currentSegmentIndex ─────────┼─── [CRITICAL: Must watch]
└── segmentProgress ─────────────┼─── [CRITICAL: Must watch]
                                └─── Updates polylines & markers
                                
                                └─── useEffect #2 (Camera)
                                     [MISSING: Throttling]
                                     Updates camera position
                                     
                                └─── useEffect #3 (Detection)
                                     [MISSING: Route change detection]
                                     Prevents crashes
```

---

## CODE PATTERNS TO KNOW

### Pattern 1: Throttling Camera Updates
```dart
final lastCameraUpdate = useRef<DateTime>(DateTime.now());

// In effect, before updating:
final now = DateTime.now();
if (now.difference(lastCameraUpdate.value).inMilliseconds < 100) {
  return; // Skip
}
lastCameraUpdate.value = now;
```

### Pattern 2: Bearing Smoothing
```dart
final smoothedBearing = useRef<double?>(null);

if (smoothedBearing.value == null) {
  smoothedBearing.value = rawBearing;
} else {
  smoothedBearing.value = smoothedBearing.value! * 0.7 + rawBearing * 0.3;
}
```

### Pattern 3: Smooth Interpolation
```dart
final lat = fromPoint.latitude + 
    (toPoint.latitude - fromPoint.latitude) * progress;
final lng = fromPoint.longitude + 
    (toPoint.longitude - fromPoint.longitude) * progress;
```

### Pattern 4: Route Change Detection
```dart
final lastRouteId = useState<String?>(null);
final routeId = '${length}_${firstLat.toStringAsFixed(6)}_${firstLng.toStringAsFixed(6)}';

if (lastRouteId.value != null && lastRouteId.value != routeId) {
  ref.read(simulationNotifierProvider.notifier).stopSimulation();
}
lastRouteId.value = routeId;
```

---

## FILE MODIFICATION CHECKLIST

```
driver_map_page.dart

┌─ Line ~31: Add imports
│  └─ Add: import 'package:ropacalapp/features/driver/widgets/navigation_blue_dot_overlay.dart';
│
├─ Line ~37: Add state variables
│  ├─ final lastCameraUpdate = useRef<DateTime>(DateTime.now());
│  └─ final smoothedBearing = useRef<double?>(null);
│
├─ Line ~49-207: UPDATE useEffect dependencies
│  └─ Add: simulationState.segmentProgress
│  └─ Add: simulationState.currentSegmentIndex
│
├─ Line ~113-181: REPLACE polyline rendering
│  └─ Add smooth interpolation logic
│
├─ Line ~209-242: REPLACE camera following useEffect
│  └─ Add throttling & smoothing
│
├─ Line ~266-279: REPLACE onMapCreated
│  └─ Add route bounds fitting
│
├─ Line ~280: ADD blue dot overlay
│  └─ Add: if (simulationState.isNavigationMode...) const NavigationBlueDotOverlay()
│
└─ After Line ~207: ADD new useEffect for route detection
   └─ Add route change detection logic
```

---

## BEFORE & AFTER BEHAVIOR

### BEFORE (Current Broken State)

Route Simulation View:
```
┌─────────────────────────────┐
│ Full route shown (all 200pt)│
│ ░░░░░░░░░░░░░░░░░░░░░░░░░ │ ← Polyline doesn't shrink
│                             │
│  Camera jittery (60+ updates/sec) │
│  No interpolation, choppy movement │
│                             │
│ No blue dot in center      │
└─────────────────────────────┘
```

### AFTER (Fixed State)

Route Simulation View:
```
┌─────────────────────────────┐
│ Remaining route shown (120pt)│
│ ░░░░░░░░░░░░░░░░░░░░░░░░░ │ ← Polyline shrinks smoothly
│                             │
│  Camera smooth (1-2 updates/sec) │
│  Smooth interpolation, no chop │
│                             │
│ Blue dot in center ⭐      │
└─────────────────────────────┘
```

---

## LINE NUMBER QUICK REFERENCE

| Issue | File | Start | End | Fix |
|-------|------|-------|-----|-----|
| Missing deps | driver_map | 207 | 207 | Add 2 items |
| Polyline | driver_map | 113 | 181 | Replace |
| Camera | driver_map | 209 | 242 | Replace |
| Bounds | driver_map | 266 | 279 | Replace |
| Overlay | driver_map | ~280 | - | Add 1 line |
| Detection | driver_map | ~207 | - | Add useEffect |

---

## SUCCESS INDICATORS

After Fix #1 (Dependencies):
✓ No compilation errors
✓ App still runs

After Fix #2 (Polyline):
✓ Polyline renders
✓ Doesn't show full route (shows remaining)

After Fix #3 (Camera):
✓ Camera follows vehicle
✓ No jerky movement

After Fix #4 (Bounds):
✓ Map zooms to show route

After Fix #5 (Overlay):
✓ Blue dot visible in 3D mode
✓ Disappears in 2D mode

After Fix #6 (Detection):
✓ No crashes on route change
✓ Simulation stops gracefully

---

## PERFORMANCE EXPECTATIONS

| Metric | Before Fix | After Fix | Target |
|--------|-----------|-----------|--------|
| Polyline updates | 1/frame | 10+/sec | Smooth |
| Camera updates | 60+/sec | 10/sec | Smooth |
| Frame rate | 50-55 FPS | 59-60 FPS | 60 FPS |
| Battery drain | High | Low | Acceptable |

---

## COMMON MISTAKES TO AVOID

❌ DON'T: Add segmentProgress to camera effect
✓ DO: Only watch in polyline effect

❌ DON'T: Replace simulation provider
✓ DO: Just fix the wiring in driver_map_page

❌ DON'T: Remove existing camera following
✓ DO: Add throttling to existing code

❌ DON'T: Copy entire navigation_page
✓ DO: Copy only the missing pieces

❌ DON'T: Change simulation_provider
✓ DO: Work with what it provides

---

## TESTING SCRIPT (Manual)

```bash
1. Build app
   flutter run

2. Navigate to map screen

3. Check polyline visibility
   └─ Should show a blue line

4. Start simulation (if button exists)
   └─ Watch for smooth movement

5. Verify behavior
   ├─ Polyline shrinks (remaining route)
   ├─ Camera follows smoothly
   ├─ No rotation jitter
   ├─ Blue dot visible (3D mode)
   └─ No crashes

6. Toggle 2D/3D mode (if available)
   ├─ Camera adapts zoom/tilt
   ├─ Bearing resets to 0 in 2D
   └─ Blue dot appears/disappears

7. Change route (if possible)
   └─ Should detect and handle gracefully

8. Check DevTools Performance
   └─ Frame rate should be 58-60 FPS
```

---

## QUICK COMMIT MESSAGE

```
feat: implement smooth route simulation in driver_map_page

- Add segmentProgress to useEffect dependencies for smooth updates
- Implement smooth polyline rendering with interpolation
- Add camera throttling (100ms) and bearing smoothing
- Add route bounds fitting on map creation
- Add NavigationBlueDotOverlay for 3D navigation mode
- Add route change detection to prevent crashes

This brings driver_map_page to feature parity with navigation_page
for route simulation and polyline rendering.

Fixes:
- Stuttering polyline during simulation
- Janky camera movement
- Missing blue dot in navigation mode
- Potential crashes on route changes

Performance:
- Reduced camera updates from 60+/sec to 10/sec
- Improved frame rate stability
- Reduced battery drain
```

---

## REFERENCE MATERIALS

In project repo:
- QUICK_FIX_SUMMARY.md ← Start here (2 min)
- COMPARISON_REPORT.md ← Full details (15 min)
- CODE_SNIPPETS_REFERENCE.md ← Implementation (40 min)
- ARCHITECTURE_DIFFERENCES.md ← Design (10 min)

In source code:
- navigation_page.dart ← Working reference
- simulation_provider.dart ← Provider logic
- simulation_state.dart ← State model

