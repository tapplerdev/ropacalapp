# Google Maps Implementation Backup

**Created:** 2025-11-19
**Purpose:** Backup of working Google Maps + HERE Routing implementation before Mapbox migration

## What's Backed Up

### 📁 Features
- `driver/` - Complete driver features directory
  - `driver_map_page.dart` - Main map page with Google Maps
  - `driver_map_wrapper.dart` - Map wrapper
  - `navigation_page.dart` - Navigation page
  - All navigation widgets

### 📁 Providers
- `location_provider.dart` - GPS location state
- `simulation_provider.dart` - Route simulation
- `here_route_provider.dart` - HERE Maps route data

### 📁 Services
- `here_maps_service.dart` - HERE routing service
- `location_service.dart` - GPS service

## Current Implementation

**Maps:** Google Maps (`google_maps_flutter`)
**Routing:** HERE Maps API v8
**Navigation:** Custom implementation
**Camera:** First-person view (67.5° tilt, 19 zoom)
**Markers:** Google Maps Marker API
**Polylines:** Google Maps Polyline API

## How to Revert

If you need to revert back to Google Maps:

1. **Copy files back:**
   ```bash
   cp -r lib_backup_google_maps/driver/* lib/features/driver/
   cp lib_backup_google_maps/location_provider.dart lib/providers/
   cp lib_backup_google_maps/simulation_provider.dart lib/providers/
   cp lib_backup_google_maps/here_route_provider.dart lib/providers/
   cp lib_backup_google_maps/here_maps_service.dart lib/core/services/
   cp lib_backup_google_maps/location_service.dart lib/core/services/
   ```

2. **Restore pubspec.yaml dependencies:**
   ```yaml
   dependencies:
     google_maps_flutter: ^2.5.0
   ```

3. **Run:**
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   flutter clean
   flutter build apk
   ```

## What Was Working

✅ Google Maps display
✅ HERE routing with traffic
✅ Custom markers (bins, route numbers)
✅ Route polylines
✅ First-person camera (auto-follow)
✅ Compass rotation when stationary
✅ GPS bearing when moving
✅ Pan to disable auto-follow
✅ Recenter button to re-enable

## Known Issues (Before Migration)

⚠️ Camera bearing sometimes not responsive
⚠️ Not true "street-level" like native Google Maps
⚠️ Turn-by-turn UI not implemented yet

## Migration To

**Target:** Mapbox Maps Flutter + HERE Routing + Custom Turn-by-Turn UI
**Reason:** Better map customization, Uber-style appearance
