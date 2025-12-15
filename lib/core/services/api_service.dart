import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ropacalapp/core/constants/api_constants.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/models/bin_check.dart';
import 'package:ropacalapp/models/bin_move.dart';
import 'package:ropacalapp/models/user.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  String? _authToken;

  static const String _tokenKey = 'auth_token';

  ApiService({Dio? dio, FlutterSecureStorage? secureStorage})
    : _dio = dio ?? Dio(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Log request details
          AppLogger.api('🚀 API REQUEST');
          AppLogger.api('   URL: ${options.baseUrl}${options.path}');
          AppLogger.api('   Method: ${options.method}');
          AppLogger.api(
            '   Auth Token Set: ${_authToken != null ? "YES" : "NO"}',
          );
          AppLogger.api('   Headers: ${options.headers}');
          AppLogger.api('   Data: ${options.data}');

          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
            AppLogger.api('   ✅ Added Authorization header');
          } else {
            AppLogger.api('   ⚠️  No auth token available!');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response details
          AppLogger.api('✅ API RESPONSE');
          AppLogger.api(
            '   URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}',
          );
          AppLogger.api('   Status Code: ${response.statusCode}');
          AppLogger.api('   Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          // Log error details
          AppLogger.api('❌ API ERROR');
          AppLogger.api(
            '   URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}',
          );
          AppLogger.api('   Type: ${error.type}');
          AppLogger.api('   Message: ${error.message}');
          AppLogger.api('   Status Code: ${error.response?.statusCode}');
          AppLogger.api('   Response Data: ${error.response?.data}');

          // Extra detailed error info for debugging connection issues
          if (error.type == DioExceptionType.connectionTimeout) {
            AppLogger.api(
              '   ⏱️  CONNECTION TIMEOUT - Could not connect to server',
            );
            AppLogger.api(
              '   ⏱️  Connect timeout: ${_dio.options.connectTimeout}',
            );
          } else if (error.type == DioExceptionType.receiveTimeout) {
            AppLogger.api('   ⏱️  RECEIVE TIMEOUT - Server not responding');
            AppLogger.api(
              '   ⏱️  Receive timeout: ${_dio.options.receiveTimeout}',
            );
          } else if (error.type == DioExceptionType.sendTimeout) {
            AppLogger.api('   ⏱️  SEND TIMEOUT - Could not send data');
            AppLogger.api('   ⏱️  Send timeout: ${_dio.options.sendTimeout}');
          } else if (error.type == DioExceptionType.badCertificate) {
            AppLogger.api('   🔒 BAD CERTIFICATE - SSL/TLS error');
          } else if (error.type == DioExceptionType.connectionError) {
            AppLogger.api('   🌐 CONNECTION ERROR - Network issue');
          } else if (error.type == DioExceptionType.unknown) {
            AppLogger.api('   ❓ UNKNOWN ERROR');
          }

          AppLogger.api('   📚 Error object: ${error.toString()}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Load auth token from secure storage (call on app startup)
  Future<void> loadAuthToken() async {
    AppLogger.api('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.api('🔑 LOADING TOKEN FROM SECURE STORAGE');
    try {
      AppLogger.api('   📂 Reading from key: $_tokenKey');
      final token = await _secureStorage.read(key: _tokenKey);

      if (token != null) {
        _authToken = token;
        AppLogger.api('   ✅ Auth token loaded from secure storage');
        AppLogger.api('   📏 Token length: ${token.length}');
        AppLogger.api('   🔍 Token preview: ${token.substring(0, 20)}...');
        AppLogger.api(
          '   💾 Token stored in memory: $_authToken != null = ${_authToken != null}',
        );
      } else {
        AppLogger.api('   ℹ️  No saved auth token found in secure storage');
        AppLogger.api('   💾 Memory token: $_authToken');
      }
    } catch (e) {
      AppLogger.api('   ❌ Error loading auth token: $e');
      AppLogger.api('   📚 Stack trace: ${StackTrace.current}');
    }
    AppLogger.api('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Save auth token to secure storage and memory
  Future<void> setAuthToken(String token) async {
    AppLogger.api('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.api('💾 SAVING TOKEN TO SECURE STORAGE');
    AppLogger.api('   📏 Token length: ${token.length}');
    AppLogger.api('   🔍 Token preview: ${token.substring(0, 20)}...');

    _authToken = token;
    AppLogger.api('   ✅ Token stored in memory');

    try {
      AppLogger.api('   📂 Writing to key: $_tokenKey');
      await _secureStorage.write(key: _tokenKey, value: token);
      AppLogger.api('   ✅ Token successfully written to secure storage');

      // Verify it was saved
      final verify = await _secureStorage.read(key: _tokenKey);
      AppLogger.api(
        '   🔍 Verification: Token exists in storage = ${verify != null}',
      );
    } catch (e) {
      AppLogger.api('   ❌ Error saving token to secure storage: $e');
      AppLogger.api('   📚 Stack trace: ${StackTrace.current}');
    }
    AppLogger.api('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Clear auth token from secure storage and memory
  Future<void> clearAuthToken() async {
    AppLogger.api('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.api('🗑️  CLEARING TOKEN FROM SECURE STORAGE');

    _authToken = null;
    AppLogger.api('   ✅ Token cleared from memory');

    try {
      AppLogger.api('   📂 Deleting key: $_tokenKey');
      await _secureStorage.delete(key: _tokenKey);
      AppLogger.api('   ✅ Token successfully deleted from secure storage');

      // Verify it was deleted
      final verify = await _secureStorage.read(key: _tokenKey);
      AppLogger.api(
        '   🔍 Verification: Token exists in storage = ${verify != null}',
      );
    } catch (e) {
      AppLogger.api('   ❌ Error clearing token from secure storage: $e');
      AppLogger.api('   📚 Stack trace: ${StackTrace.current}');
    }
    AppLogger.api('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Check if user has a valid token (in memory)
  bool get hasToken => _authToken != null;

  /// Get the current auth token (for WebSocket connection)
  String? get authToken => _authToken;

  // Auth endpoints
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.api('🔐 LOGIN: Starting login request...');
      AppLogger.api('   📍 Endpoint: ${ApiConstants.loginEndpoint}');
      AppLogger.api('   ⏰ Current time: ${DateTime.now()}');

      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      AppLogger.api('🔐 LOGIN: Response received at ${DateTime.now()}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.api('🔐 LOGIN: Exception caught at ${DateTime.now()}');
      AppLogger.api('   Exception type: ${e.runtimeType}');
      AppLogger.api('   Exception details: $e');
      throw _handleError(e);
    }
  }

  Future<User?> getAuthStatus() async {
    try {
      final response = await _dio.get(ApiConstants.authStatusEndpoint);
      if (response.data != null && response.data['user'] != null) {
        return User.fromJson(response.data['user'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Bin endpoints
  Future<List<Bin>> getBins() async {
    try {
      AppLogger.api(
        '🔍 getBins: Making request to ${ApiConstants.binsEndpoint}',
      );
      final response = await _dio.get(ApiConstants.binsEndpoint);
      AppLogger.api('🔍 getBins: Response status ${response.statusCode}');
      AppLogger.api(
        '🔍 getBins: Response data type: ${response.data.runtimeType}',
      );
      AppLogger.api(
        '🔍 getBins: Response data length: ${(response.data as List).length}',
      );

      if ((response.data as List).isNotEmpty) {
        AppLogger.api(
          '🔍 getBins: First item raw JSON: ${(response.data as List).first}',
        );
      }

      final bins = (response.data as List).map((bin) {
        try {
          return Bin.fromJson(bin as Map<String, dynamic>);
        } catch (e) {
          AppLogger.api('🔍 getBins: Error parsing bin: $e');
          AppLogger.api('🔍 getBins: Problematic bin data: $bin');
          rethrow;
        }
      }).toList();
      AppLogger.api('🔍 getBins: Successfully parsed ${bins.length} bins');
      return bins;
    } catch (e) {
      AppLogger.api('🔍 getBins: Exception caught: $e');
      throw _handleError(e);
    }
  }

  Future<Bin> getBinById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.binDetailEndpoint(id));
      return Bin.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Bin> updateBin(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch(
        ApiConstants.binDetailEndpoint(id),
        data: updates,
      );
      return Bin.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Move endpoints
  Future<Map<String, dynamic>> createMove({
    required String binId,
    required String toStreet,
    required String toCity,
    required String toZip,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.binMovesEndpoint(binId),
        data: {'toStreet': toStreet, 'toCity': toCity, 'toZip': toZip},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<BinMove>> getMoveHistory(String binId) async {
    try {
      final response = await _dio.get(ApiConstants.moveHistoryEndpoint(binId));
      final moves = (response.data as List)
          .map((move) => BinMove.fromJson(move as Map<String, dynamic>))
          .toList();
      return moves;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Check endpoints
  Future<BinCheck> createCheck({
    required String binId,
    required String checkedFrom,
    required int fillPercentage,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.binChecksEndpoint(binId),
        data: {'checked_from': checkedFrom, 'fill_percentage': fillPercentage},
      );
      return BinCheck.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<BinCheck>> getCheckHistory(String binId) async {
    try {
      final response = await _dio.get(ApiConstants.checkHistoryEndpoint(binId));
      final checks = (response.data as List)
          .map((check) => BinCheck.fromJson(check as Map<String, dynamic>))
          .toList();
      return checks;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Route optimization endpoint
  Future<List<Bin>> getOptimizedRoute({
    required double latitude,
    required double longitude,
    int limit = 5,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.routeEndpoint,
        data: {'latitude': latitude, 'longitude': longitude, 'limit': limit},
      );
      final bins = (response.data as List)
          .map((bin) => Bin.fromJson(bin as Map<String, dynamic>))
          .toList();
      return bins;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Generic HTTP methods for other services
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, Map<String, dynamic> data) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(String path, Map<String, dynamic> data) async {
    try {
      return await _dio.patch(path, data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'];
          if (statusCode == 401) {
            return 'Unauthorized. Please log in again.';
          } else if (statusCode == 404) {
            return 'Resource not found.';
          } else if (message != null) {
            return message as String;
          }
          return 'Server error: $statusCode';
        case DioExceptionType.cancel:
          return 'Request cancelled.';
        default:
          return 'Network error. Please try again.';
      }
    }
    return error.toString();
  }
}
