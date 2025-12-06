# Backend Route Optimization Implementation Guide

## Problem

Current route duration calculation is naive:
```dart
Duration(hours: (totalBins * 0.25).ceil())
// 1 bin = 15 minutes (very rough estimate)
```

This doesn't account for:
- ❌ Actual driving distance between bins
- ❌ Real-time traffic conditions
- ❌ Road types (highway vs residential)
- ❌ Optimal waypoint ordering
- ❌ Parking/access difficulty per location

**Result:** Drivers see "1h route" but it actually takes 2h → frustration & mistrust

---

## Solution: Google Directions API Integration

When a route is **assigned to a driver**, backend should:

### 1. Calculate Optimized Route with Google Directions API

**API Endpoint:** [Google Directions API](https://developers.google.com/maps/documentation/directions/overview)

**Request Example:**
```http
POST https://maps.googleapis.com/maps/api/directions/json
{
  "origin": "4.678245,-74.052367",  // Driver's current location or depot
  "destination": "4.678245,-74.052367",  // Return to origin (circular route)
  "waypoints": "optimize:true|4.680123,-74.055789|4.682456,-74.058123|...",
  "mode": "driving",
  "departure_time": "now",  // For real-time traffic
  "traffic_model": "best_guess",
  "key": "YOUR_API_KEY"
}
```

**Key Parameters:**
- `waypoints: "optimize:true|..."` - Google reorders stops for efficiency
- `departure_time: "now"` - Includes current traffic conditions
- `traffic_model: "best_guess"` - Most accurate estimate

**Response:**
```json
{
  "routes": [{
    "legs": [
      {
        "duration": { "value": 1800 },  // 30 minutes in seconds
        "duration_in_traffic": { "value": 2100 },  // 35 min with traffic
        "distance": { "value": 12500 }  // 12.5 km in meters
      },
      // ... one leg per waypoint
    ],
    "waypoint_order": [2, 0, 1]  // Optimized order
  }]
}
```

### 2. Calculate Total Route Duration

```python
# Python example (adapt to your backend language)

def calculate_route_duration(bin_locations, driver_location):
    """
    Calculate accurate route duration using Google Directions API

    Args:
        bin_locations: List of bin coordinates [(lat, lng), ...]
        driver_location: Driver's current location (lat, lng)

    Returns:
        duration_hours: Accurate total route time in hours
    """

    # 1. Build waypoints string for Google API
    waypoints = "optimize:true|" + "|".join(
        f"{lat},{lng}" for lat, lng in bin_locations
    )

    # 2. Call Google Directions API
    response = requests.get(
        "https://maps.googleapis.com/maps/api/directions/json",
        params={
            "origin": f"{driver_location[0]},{driver_location[1]}",
            "destination": f"{driver_location[0]},{driver_location[1]}",
            "waypoints": waypoints,
            "mode": "driving",
            "departure_time": "now",
            "traffic_model": "best_guess",
            "key": GOOGLE_API_KEY
        }
    )

    route_data = response.json()

    # 3. Sum up driving time from all legs
    total_driving_seconds = sum(
        leg["duration_in_traffic"]["value"]  # Use traffic-aware duration
        for leg in route_data["routes"][0]["legs"]
    )

    # 4. Add collection time per bin (e.g., 5 minutes each)
    COLLECTION_TIME_PER_BIN = 5 * 60  # 5 minutes in seconds
    total_collection_seconds = len(bin_locations) * COLLECTION_TIME_PER_BIN

    # 5. Add buffer for parking, access, etc. (e.g., 10%)
    BUFFER_PERCENTAGE = 0.10
    total_seconds = total_driving_seconds + total_collection_seconds
    total_with_buffer = total_seconds * (1 + BUFFER_PERCENTAGE)

    # 6. Convert to hours (decimal)
    duration_hours = total_with_buffer / 3600

    return round(duration_hours, 2)
```

### 3. Store in Database

**Update ShiftOverview model:**
```sql
UPDATE shifts
SET
  estimated_duration_hours = 1.75,  -- From Google API calculation
  total_distance_km = 15.2,         -- From Google API response
  optimized_waypoint_order = '[2, 0, 1]',  -- For navigation
  calculated_at = NOW()
WHERE shift_id = 'abc123';
```

**Important:** Store both:
- `estimated_duration_hours` - What frontend displays
- `optimized_waypoint_order` - To show bins in correct order in timeline

### 4. Frontend Already Handles It

The frontend reads from `ShiftOverview.estimatedDurationHours`:
```dart
// This already works - no frontend changes needed!
shiftOverview.durationFormatted  // "1h 45m"
```

Flutter formats it automatically via the model's `durationFormatted` getter.

---

## When to Calculate

**Option A: When Route is Created**
```
Admin creates route → Calculate duration → Store in DB
```
✅ Faster for driver (no wait time)
❌ May be outdated if traffic changes
❌ Doesn't account for driver's current location

**Option B: When Route is Assigned (RECOMMENDED)**
```
Route assigned to driver → Get driver location → Calculate with traffic → Store & send
```
✅ Most accurate (real-time traffic)
✅ Uses driver's actual current location
✅ Up-to-date at decision time
❌ Small delay (~500ms API call)

**Option C: Hybrid**
```
Pre-calculate on creation → Recalculate when assigned
```
✅ Fallback if API fails
✅ Most accurate
❌ More complex

**Recommendation:** Option B - Calculate when assigned to driver

---

## API Cost Estimation

**Google Directions API Pricing:**
- $5 per 1,000 requests
- $10 per 1,000 requests with traffic data

**Example Costs:**
- 100 route assignments/day = $1/day = $30/month
- 500 route assignments/day = $5/day = $150/month
- 1,000 route assignments/day = $10/day = $300/month

**Cost Optimization:**
1. Cache results for 5-10 minutes (if same route reassigned)
2. Only recalculate if >15 min since last calculation
3. Use Distance Matrix API for simple cases (cheaper)

---

## Error Handling

**What if Google API fails?**

```python
def get_route_duration_with_fallback(bin_locations, driver_location):
    try:
        # Try Google API
        return calculate_route_duration(bin_locations, driver_location)
    except Exception as e:
        log_error(f"Google API failed: {e}")

        # Fallback to simple calculation
        num_bins = len(bin_locations)
        return num_bins * 0.25  # 15 min per bin (old method)
```

**Always have a fallback** so the app doesn't break if Google is down.

---

## Implementation Checklist

### Backend Tasks:
- [ ] Add Google Directions API credentials to environment
- [ ] Create route optimization service/module
- [ ] Add `optimized_waypoint_order` column to shifts table
- [ ] Update route assignment endpoint to call Google API
- [ ] Add fallback calculation for API failures
- [ ] Store traffic-aware duration in `estimated_duration_hours`
- [ ] Add logging for API calls and costs
- [ ] Implement caching (optional)

### Database Schema:
```sql
ALTER TABLE shifts ADD COLUMN optimized_waypoint_order JSONB;
ALTER TABLE shifts ADD COLUMN calculated_at TIMESTAMP;
ALTER TABLE shifts ADD COLUMN calculation_method VARCHAR(20);  -- 'google_api' or 'fallback'
```

### API Endpoint Update:
```
POST /api/v1/routes/assign
{
  "route_id": "abc123",
  "driver_id": "driver456"
}

Response:
{
  "shift_id": "shift789",
  "estimated_duration_hours": 1.75,  // From Google API
  "total_distance_km": 15.2,
  "optimized_waypoints": [2, 0, 1],
  "calculated_at": "2025-12-06T21:30:00Z"
}
```

---

## Testing

### Unit Tests:
```python
def test_route_calculation():
    bins = [
        (4.680123, -74.055789),
        (4.682456, -74.058123),
        (4.679012, -74.053456)
    ]
    driver_loc = (4.678245, -74.052367)

    duration = calculate_route_duration(bins, driver_loc)

    assert duration > 0
    assert duration < 24  # Sanity check: less than 24 hours
```

### Integration Tests:
1. Test with real Google API (use test key)
2. Test fallback when API is unavailable
3. Test with 1 bin, 5 bins, 20 bins
4. Test with bins close together vs spread out
5. Test during rush hour vs off-peak

---

## Monitoring

**Track these metrics:**
- Google API success rate
- Average calculation time
- Fallback usage percentage
- Cost per day/month
- Accuracy: Estimated time vs actual completion time

**Alerts:**
- Google API failure rate >10%
- Daily API cost >$20
- Calculation time >2 seconds

---

## Future Enhancements

1. **Historical Data Learning**
   - Track actual completion times
   - Adjust buffer percentage based on historical accuracy
   - Machine learning model for better estimates

2. **Multi-Vehicle Optimization**
   - Assign routes across multiple drivers
   - Balance workload distribution
   - Minimize total fleet time

3. **Real-Time Re-Routing**
   - Update duration if driver is delayed
   - Suggest skip/reorder if running late
   - Dynamic priority adjustment

4. **Zone-Based Estimates**
   - Pre-calculate average time per neighborhood
   - Use for instant estimates without API call
   - Fall back to zone average if API fails

---

## Questions?

Contact the frontend team if you need:
- Specific field names from ShiftOverview model
- Additional data to display in the modal
- Help testing the integration

**Frontend is ready** - just need backend to populate accurate duration data!
