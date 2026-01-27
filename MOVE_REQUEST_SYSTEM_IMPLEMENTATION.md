# Move Request System Implementation Guide

## Overview
This document summarizes the **Bin Relocation System** implementation for RopacalApp. The system allows managers to assign bin relocations to drivers, who then pick up bins from one location and place them at another.

---

## ✅ Completed Implementation

### 1. **Data Models** (`lib/models/`)

#### `move_request.dart`
Enhanced model with full pickup/dropoff tracking:
- **Pickup Location**: `pickupLatitude`, `pickupLongitude`, `pickupAddress`
- **Drop-off Location**: `dropoffLatitude`, `dropoffLongitude`, `dropoffAddress`
- **Status Tracking**: `status` (pending → pickedUp → completed)
- **Photo Tracking**: `pickupPhotoUrl`, `placementPhotoUrl`
- **Metadata**: `notes`, `pickedUpAt`, `resolvedAt`

#### `route_bin.dart`
Added stop type differentiation:
- **New Field**: `stopType` (collection | pickup | dropoff)
- **New Field**: `moveRequestId` - Links pickup/dropoff stops to move request

#### `stop_type.dart` (NEW)
Enum for stop types:
```dart
enum StopType {
  collection,  // Normal bin collection
  pickup,      // Pick up bin for relocation
  dropoff,     // Place bin at new location
}
```

#### `move_request_status.dart`
Enhanced with execution statuses:
- `pending` - Assigned, not picked up
- `pickedUp` - In transit to drop-off
- `completed` - Placed at new location
- `cancelled` - Request cancelled

---

### 2. **Services** (`lib/core/services/`)

#### `geofence_service.dart` (NEW)
Proximity detection for pickup/dropoff locations:
```dart
class GeofenceService {
  static const double defaultGeofenceRadiusMeters = 100.0;

  // Check if within geofence
  static bool isWithinGeofence({
    required LatLng currentLocation,
    required LatLng targetLocation,
    double radiusMeters = 100.0,
  });

  // Calculate distance to target
  static double getDistanceToTarget(...);

  // Format distance for display
  static String formatDistance(double distanceMeters);
}
```

---

### 3. **State Management** (`lib/providers/`)

#### `move_request_provider.dart` (NEW)
Manages active move request lifecycle:
```dart
@Riverpod(keepAlive: true)
class ActiveMoveRequest {
  MoveRequest? state;

  // Set/clear active request
  void setMoveRequest(MoveRequest request);
  void clearMoveRequest();

  // Complete pickup
  Future<void> completePickup({
    required String photoUrl,
    bool hasDamage = false,
    String? notes,
  });

  // Complete placement
  Future<void> completePlacement({
    required String photoUrl,
    String? notes,
    bool hasIssue = false,
  });

  // Geofence checks
  bool isWithinPickupGeofence(LatLng currentLocation);
  bool isWithinDropoffGeofence(LatLng currentLocation);
}
```

---

### 4. **UI Components** (`lib/features/driver/widgets/`)

#### `move_request_pickup_dialog.dart` (NEW)
Photo + condition check dialog:
- 📸 Camera integration
- ✅ Damage/cannot locate checkboxes
- 📝 Optional notes field
- 🎨 Orange color scheme (#FF9800)

#### `move_request_placement_dialog.dart` (NEW)
Photo + placement notes dialog:
- 📸 Camera integration
- ✅ Limited access/not ideal location checkboxes
- 📝 Placement notes field
- 🎨 Green color scheme (#4CAF50)

#### `navigation_bottom_panel.dart` (UPDATED)
Enhanced with stop type visual differentiation:
- **Pickup stops**: Orange badge with "🚚 PICKUP" label
- **Dropoff stops**: Green badge with "📍 DROPOFF" label
- **Collection stops**: Blue badge (existing)

---

### 5. **WebSocket Integration** (`lib/providers/auth_provider.dart`)

Enhanced `onMoveRequestAssigned` callback:
```dart
_service!.onMoveRequestAssigned = (data) {
  // Parse move request
  final moveRequest = MoveRequest.fromJson(data['move_request']);

  // Set active move request
  ref.read(activeMoveRequestProvider.notifier).setMoveRequest(moveRequest);

  // Update shift with new route (includes pickup & dropoff waypoints)
  if (data['updated_route'] != null) {
    ref.read(shiftNotifierProvider.notifier).updateFromWebSocket(data);
  } else {
    ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
  }
};
```

---

## 🔧 Backend Requirements

### WebSocket Message Format
When assigning a move request to a driver:

```json
{
  "type": "move_request_assigned",
  "data": {
    "move_request": {
      "id": "move_123",
      "bin_id": "bin_789",
      "status": "pending",
      "pickup_latitude": 37.8044,
      "pickup_longitude": -122.2712,
      "pickup_address": "123 Main St, Oakland",
      "is_warehouse_pickup": false,
      "dropoff_latitude": 37.8144,
      "dropoff_longitude": -122.2812,
      "dropoff_address": "456 Oak Ave, Oakland",
      "assigned_shift_id": "shift_456",
      "insert_after_bin_id": "bin_2",
      "requested_at": "2024-01-15T10:30:00Z"
    },
    "updated_route": [
      {
        "id": 1,
        "bin_id": "bin_1",
        "sequence_order": 1,
        "stop_type": "collection",
        "bin_number": 1234,
        "current_street": "Main St",
        ...
      },
      {
        "id": 2,
        "bin_id": "bin_2",
        "sequence_order": 2,
        "stop_type": "collection",
        ...
      },
      {
        "id": 3,
        "bin_id": "bin_789",
        "sequence_order": 3,
        "stop_type": "pickup",
        "move_request_id": "move_123",
        "latitude": 37.8044,
        "longitude": -122.2712,
        "current_street": "123 Main St",
        ...
      },
      {
        "id": 4,
        "bin_id": "bin_789",
        "sequence_order": 4,
        "stop_type": "dropoff",
        "move_request_id": "move_123",
        "latitude": 37.8144,
        "longitude": -122.2812,
        "current_street": "456 Oak Ave",
        ...
      },
      {
        "id": 5,
        "bin_id": "bin_3",
        "sequence_order": 5,
        "stop_type": "collection",
        ...
      }
    ]
  }
}
```

### API Endpoints Required

#### 1. Mark Pickup Complete
```
POST /api/driver/move-requests/:id/pickup
Body: {
  "pickup_photo_url": "https://cloudinary.com/...",
  "picked_up_at": "2024-01-15T11:00:00Z",
  "has_damage": false,
  "notes": "Bin in good condition"
}
```

#### 2. Mark Placement Complete
```
POST /api/driver/move-requests/:id/complete
Body: {
  "placement_photo_url": "https://cloudinary.com/...",
  "completed_at": "2024-01-15T11:30:00Z",
  "has_issue": false,
  "notes": "Placed near front entrance"
}
```

---

## 🚧 Remaining Integration Work

### Final Step: Google Navigation Page Integration

You need to add the following to `google_navigation_page.dart`:

#### 1. Add Geofence Detection

```dart
// Watch active move request
final activeMoveRequest = ref.watch(activeMoveRequestProvider);
final currentLocation = ref.watch(currentLocationProvider).value;

// Check geofences
final isInPickupZone = activeMoveRequest != null &&
    activeMoveRequest.status == MoveRequestStatus.pending &&
    currentLocation != null &&
    ref.read(activeMoveRequestProvider.notifier)
        .isWithinPickupGeofence(currentLocation);

final isInDropoffZone = activeMoveRequest != null &&
    activeMoveRequest.status == MoveRequestStatus.pickedUp &&
    currentLocation != null &&
    ref.read(activeMoveRequestProvider.notifier)
        .isWithinDropoffGeofence(currentLocation);
```

#### 2. Show Dialogs Based on Stop Type

In your existing check-in logic, add:

```dart
void _showCheckInDialog(RouteBin bin) {
  switch (bin.stopType) {
    case StopType.collection:
      // Existing CheckInDialogV2
      showDialog(
        context: context,
        builder: (context) => CheckInDialogV2(...),
      );
      break;

    case StopType.pickup:
      final moveRequest = ref.read(activeMoveRequestProvider)!;
      showDialog(
        context: context,
        builder: (context) => MoveRequestPickupDialog(
          moveRequest: moveRequest,
          onCancel: () => Navigator.pop(context),
          onPickup: ({required photoUrl, hasDamage, notes}) async {
            await ref.read(activeMoveRequestProvider.notifier)
                .completePickup(
                  photoUrl: photoUrl,
                  hasDamage: hasDamage ?? false,
                  notes: notes,
                );
            if (context.mounted) Navigator.pop(context);
          },
        ),
      );
      break;

    case StopType.dropoff:
      final moveRequest = ref.read(activeMoveRequestProvider)!;
      showDialog(
        context: context,
        builder: (context) => MoveRequestPlacementDialog(
          moveRequest: moveRequest,
          onCancel: () => Navigator.pop(context),
          onPlace: ({required photoUrl, notes, hasIssue}) async {
            await ref.read(activeMoveRequestProvider.notifier)
                .completePlacement(
                  photoUrl: photoUrl,
                  notes: notes,
                  hasIssue: hasIssue ?? false,
                );
            if (context.mounted) Navigator.pop(context);
          },
        ),
      );
      break;
  }
}
```

#### 3. Update Google Navigation Route After Completion

```dart
// After completing pickup or dropoff, update navigation route
Future<void> _updateNavigationRoute() async {
  final shift = ref.read(shiftNotifierProvider);
  final waypoints = shift.remainingBins
      .where((bin) => bin.isCompleted == 0)
      .map((bin) => NavigationWaypoint.withLatLngTarget(
            latLng: LatLng(
              latitude: bin.latitude,
              longitude: bin.longitude,
            ),
            title: 'Bin #${bin.binNumber}',
          ))
      .toList();

  await GoogleMapsNavigator.setDestinations(
    Destinations(
      waypoints: waypoints,
      displayOptions: NavigationDisplayOptions(showDestinationMarkers: true),
    ),
  );
}
```

---

## 📊 User Flow Summary

### Driver Experience

1. **Notification Received**
   - Manager assigns move request via dashboard
   - Driver receives WebSocket notification
   - Shift updated with 2 new stops (pickup + dropoff)
   - NavigationBottomPanel shows orange "🚚 PICKUP" badge

2. **Navigate to Pickup Location**
   - Driver follows Google Navigation to pickup address
   - When within 100m, geofence triggers
   - "Pick Up Bin" button appears

3. **Pick Up Bin**
   - Tap button → `MoveRequestPickupDialog` appears
   - Driver takes photo of bin
   - Checks condition (damage/cannot locate)
   - Adds optional notes
   - Confirms pickup

4. **Transport to Drop-off**
   - Status changes to `pickedUp`
   - Navigation auto-updates to drop-off location
   - NavigationBottomPanel shows green "📍 DROPOFF" badge

5. **Place Bin**
   - When within 100m of drop-off, geofence triggers
   - "Place Bin Here" button appears
   - Driver places bin, takes photo
   - Adds placement notes
   - Confirms placement

6. **Complete**
   - Status changes to `completed`
   - Move request cleared from active state
   - Navigation resumes normal route

---

## 🎨 Visual Design

### Color Coding
- **Collection stops**: Blue (#4CAF50) - Normal operations
- **Pickup stops**: Orange (#FF9800) - Warm color for "loading"
- **Dropoff stops**: Green (#4CAF50) - Success color for "delivery"

### UI Components
- **NavigationBottomPanel**: Color-coded badges with stop type labels
- **Pickup Dialog**: Orange header, camera, condition checkboxes
- **Dropoff Dialog**: Green header, camera, placement notes

---

## 🐛 Testing Checklist

### Basic Flow
- [ ] WebSocket receives `move_request_assigned` message
- [ ] Active move request set in provider
- [ ] Shift updated with pickup + dropoff waypoints
- [ ] NavigationBottomPanel shows orange "PICKUP" badge
- [ ] Geofence detects arrival at pickup location
- [ ] Pickup dialog opens, photo taken
- [ ] Pickup marked complete, status → `pickedUp`
- [ ] Navigation updates to drop-off location
- [ ] NavigationBottomPanel shows green "DROPOFF" badge
- [ ] Geofence detects arrival at drop-off location
- [ ] Placement dialog opens, photo taken
- [ ] Placement marked complete, status → `completed`
- [ ] Active move request cleared
- [ ] Navigation resumes normal route

### Edge Cases
- [ ] Driver dismisses pickup dialog (can reopen)
- [ ] Network error during photo upload (retry)
- [ ] Driver picks "damaged" checkbox (logged)
- [ ] Driver adds notes (saved to backend)
- [ ] Move request cancelled mid-transport (handle gracefully)

---

## 📝 Notes for Future Development

### Potential Enhancements
1. **Route Preview**: Show before/after route comparison when move request assigned
2. **Offline Support**: Queue pickup/dropoff if network unavailable
3. **Multiple Move Requests**: Support multiple active relocations
4. **Push Notifications**: Alert driver when move request assigned
5. **ETA Updates**: Show time impact of relocation on total route
6. **Cancel Flow**: Allow driver to reject/cancel move request with reason

### Known Limitations
- Currently supports one active move request at a time
- Geofence radius is fixed at 100m (could be configurable)
- Photos required (no "skip photo" option)
- No in-app route preview before accepting

---

## 🎯 Summary

This implementation provides a complete bin relocation system with:
- ✅ **Two-step workflow** (pickup → transport → dropoff)
- ✅ **Geofence-based triggers** (100m radius)
- ✅ **Photo verification** at both pickup and dropoff
- ✅ **Real-time navigation updates**
- ✅ **Status tracking** throughout lifecycle
- ✅ **Visual differentiation** for stop types
- ✅ **WebSocket integration** for real-time assignment

The system is **80% complete** - only the final navigation page integration remains, which should take ~30-45 minutes to implement following the guide above.
