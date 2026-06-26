# RopacalApp - Flutter Mobile App

Flutter/Dart mobile app for the Ropacal/Binly bin management and logistics platform. Used by drivers (turn-by-turn navigation, bin check-ins, shift management) and managers (shift building, fleet tracking).

## Tech Stack

- **Flutter/Dart 3.9.2**
- **State Management:** Riverpod (with annotations + code generation)
- **Routing:** GoRouter
- **Navigation/Maps:** Google Navigation Flutter SDK (native turn-by-turn)
- **HTTP Client:** Dio
- **Real-time:** Centrifugo WebSocket client
- **Location:** fused_location + geolocator
- **Code Gen:** Freezed, Riverpod, json_serializable, build_runner
- **Backend:** `https://ropacal-backend-production.up.railway.app` (Go/Railway)
- **Centrifugo WS:** `wss://binly-centrifugo-service-production.up.railway.app/connection/websocket`

## Project Structure

```
lib/
  core/
    constants/              — API URLs, config
    services/
      api_service.dart      — Dio HTTP client with JWT auth
      centrifugo_service.dart — Real-time WebSocket
      google_navigation_service.dart — Turn-by-turn nav SDK init
      google_routes_service.dart — Google Routes API v2
      location_tracking_service.dart — GPS streaming
    widgets/                — Reusable UI (route_map_preview, etc.)
    utils/                  — Helpers (google_navigation_helpers, etc.)
    platform/               — Platform-specific bridges
    notifications/          — Push notification handling
  features/
    auth/                   — Splash, login
    driver/
      google_navigation_page.dart  — Active turn-by-turn navigation
      driver_map_page.dart         — Map view
      shifts_page.dart             — Shift list
      shift_acceptance_page.dart   — Slide-to-accept assigned shift
      route_detail_page.dart       — Route timeline & stops
      bin_detail_page.dart         — Individual bin
      widgets/                     — Turn-by-turn card, etc.
    manager/
      shift_builder_page.dart      — Create shifts
      active_drivers_list_page.dart — Live fleet tracking
      potential_locations_page.dart
      move_requests_page.dart
    shared/
      location_picker_page.dart    — Map-based location picker
  providers/                — Riverpod providers
    auth_provider.dart
    shift_provider.dart
    navigation_page_provider.dart
    location_provider.dart
    centrifugo_provider.dart
    route_polyline_provider.dart   — OSRM polyline refresh (every 10s)
    route_task_provider.dart
  services/                 — Domain service layer
    route_task_service.dart
    shift_service.dart
    manager_service.dart
  models/                   — Freezed data models
    route.dart, route_task.dart, shift_state.dart, bin.dart, etc.
  router/app_router.dart    — GoRouter config
```

## Route Optimization & Navigation Flow

**Route optimization is BACKEND-DRIVEN — the app does NOT call Mapbox or OSRM directly.**

1. Manager creates shift on backend (`POST /api/manager/shifts/create-with-tasks`)
2. Driver starts shift (`POST /api/driver/shift/start`) → backend runs Mapbox Optimization v2
3. Backend returns optimized task order with sequence numbers
4. App fetches tasks (`GET /shifts/{shiftId}/tasks/detailed`) — pre-ordered by backend
5. App uses **Google Navigation SDK** for native turn-by-turn to each stop
6. OSRM polylines fetched from backend (`GET /api/directions`) every 10s for map preview

## Real-time Location Flow

1. **GPS source:** fused_location (Android FusedLocationClient, iOS CoreLocation) — 1s intervals
2. **Publishing:** HTTP POST to backend, which saves to Redis + publishes to Centrifugo
3. **Channels:** `driver:location:{driverId}`, `shift:updates:{shiftId}`, `manager:notifications:{id}`
4. **Token:** `GET /api/centrifugo/token` → JWT for WebSocket auth, auto-refreshed

## Shift Lifecycle (Driver)

1. Shift assigned → push notification → ShiftAcceptancePage (slide to accept)
2. PreflightCheck → validates readiness
3. StartShift → backend optimizes route → tasks returned in order
4. Navigate to each stop via Google Navigation SDK
5. Complete task → backend updates, advances to next
6. End shift → archived to shift_history

## Key Conventions
- Write concise, technical Dart code with accurate examples.
- Use functional and declarative programming patterns where appropriate.
- Prefer composition over inheritance.
- Use descriptive variable names with auxiliary verbs (e.g., isLoading, hasError).
- Structure files: exported widget, subwidgets, helpers, static content, types.

## Dart/Flutter
- Use const constructors for immutable widgets.
- Leverage Freezed for immutable state classes and unions.
- Use arrow syntax for simple functions and methods.
- Prefer expression bodies for one-line getters and setters.
- Use trailing commas for better formatting and diffs.

## Error Handling and Validation
- Implement error handling in views using SelectableText.rich instead of SnackBars.
- Display errors in SelectableText.rich with red color for visibility.
- Handle empty states within the displaying screen.
- Use AsyncValue for proper error handling and loading states.

## Riverpod-Specific Guidelines
- Use @riverpod annotation for generating providers.
- Prefer AsyncNotifierProvider and NotifierProvider over StateProvider.
- Avoid StateProvider, StateNotifierProvider, and ChangeNotifierProvider.
- Use ref.invalidate() for manually triggering provider updates.
- Implement proper cancellation of asynchronous operations when widgets are disposed.

## Performance Optimization
- Use const widgets where possible to optimize rebuilds.
- Implement list view optimizations (e.g., ListView.builder).
- Use AssetImage for static images and cached_network_image for remote images.
- Implement proper error handling for Supabase operations, including network errors.

## Key Conventions
1. Use GoRouter or auto_route for navigation and deep linking.
2. Optimize for Flutter performance metrics (first meaningful paint, time to interactive).
3. Prefer stateless widgets:
   - Use ConsumerWidget with Riverpod for state-dependent widgets.
   - Use HookConsumerWidget when combining Riverpod and Flutter Hooks.

## UI and Styling
- Use Flutter's built-in widgets and create custom widgets.
- Implement responsive design using LayoutBuilder or MediaQuery.
- Use themes for consistent styling across the app.
- Use Theme.of(context).textTheme.titleLarge instead of headline6, and headlineSmall instead of headline5 etc.

## Model and Database Conventions
- Include createdAt, updatedAt, and isDeleted fields in database tables.
- Use @JsonSerializable(fieldRename: FieldRename.snake) for models.
- Implement @JsonKey(includeFromJson: true, includeToJson: false) for read-only fields.

## Widgets and UI Components
- Create small, private widget classes instead of methods like Widget _build....
- Implement RefreshIndicator for pull-to-refresh functionality.
- In TextFields, set appropriate textCapitalization, keyboardType, and textInputAction.
- Always include an errorBuilder when using Image.network.

## Miscellaneous
- Use log instead of print for debugging.
- Use Flutter Hooks / Riverpod Hooks where appropriate.
- Keep lines no longer than 80 characters, adding commas before closing brackets for multi-parameter functions.
- Use @JsonValue(int) for enums that go to the database.

## Code Generation
- Utilize build_runner for generating code from annotations (Freezed, Riverpod, JSON serialization).
- Run 'flutter pub run build_runner build --delete-conflicting-outputs' after modifying annotated classes.

## Documentation
- Document complex logic and non-obvious code decisions.
- Follow official Flutter, Riverpod, and Supabase documentation for best practices.
