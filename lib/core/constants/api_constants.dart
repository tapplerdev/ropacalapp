class ApiConstants {
  // Golang backend (LOCAL TESTING - change back to Railway for production)
  // Production: 'https://ropacal-backend-production.up.railway.app'
  // Local iOS simulator: 'http://localhost:8080'
  // Local Android emulator: 'http://10.0.2.2:8080'
  // Local physical device: 'http://YOUR_MAC_IP:8080' (same WiFi)
  static const String baseUrl = 'http://10.0.2.2:8080';

  // WebSocket URL (auto-derived from baseUrl)
  // Converts http/https to ws/wss automatically
  static String get wsUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/ws';
  }

  // Auth endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String authStatusEndpoint = '/api/auth/status';

  // Bin endpoints
  static const String binsEndpoint = '/api/bins';
  static String binDetailEndpoint(String id) => '/api/bins/$id';
  static String binMovesEndpoint(String id) => '/api/bins/$id/moves';
  static String binChecksEndpoint(String id) => '/api/bins/$id/checks';

  // History endpoints (same as moves/checks endpoints)
  static String moveHistoryEndpoint(String id) => '/api/bins/$id/moves';
  static String checkHistoryEndpoint(String id) => '/api/bins/$id/checks';

  // Potential locations endpoints
  static const String potentialLocationsEndpoint = '/api/potential-locations';

  // Route optimization
  static const String routeEndpoint = '/api/route';

  // Centrifugo real-time messaging
  static const String centrifugoTokenEndpoint = '/api/centrifugo/token';
}
