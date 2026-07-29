/// In-memory mirror of the backend JWT for code paths that cannot go
/// through [ApiService]'s Dio interceptor — the fire-and-forget diagnostic
/// posts in app_logger.dart, app_error_logging_service.dart and
/// fcm_service.dart, which use package:http directly.
///
/// Single writer: [ApiService] (loadAuthToken / setAuthToken /
/// clearAuthToken). Everyone else only reads.
///
/// NOTE: statics are per-isolate. The FCM background isolate
/// (_firebaseBackgroundHandler) never runs ApiService, so [token] is null
/// there and its diagnostic posts stay unauthenticated.
class AuthTokenStore {
  AuthTokenStore._();

  static String? token;

  /// `Authorization: Bearer …` header when a token is present, else empty.
  static Map<String, String> get authHeaders => {
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
