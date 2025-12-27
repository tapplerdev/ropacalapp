import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Service for uploading images to Cloudinary
/// Uses unsigned uploads with direct HTTP requests
class CloudinaryService {
  String? _cloudName;
  String? _uploadPreset;
  bool _isInitialized = false;

  /// Initialize Cloudinary
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        AppLogger.general('ℹ️  Cloudinary already initialized');
        return;
      }

      AppLogger.general('🌥️ Initializing Cloudinary...');

      _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

      if (_cloudName == null || _uploadPreset == null) {
        throw Exception(
          'Cloudinary credentials not found in .env file. '
          'Please ensure CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET are set.',
        );
      }

      _isInitialized = true;

      AppLogger.general('✅ Cloudinary initialized successfully');
      AppLogger.general('   Cloud name: $_cloudName');
      AppLogger.general('   Upload preset: $_uploadPreset');
    } catch (e) {
      AppLogger.general(
        '❌ Error initializing Cloudinary: $e',
        level: AppLogger.error,
      );
      rethrow;
    }
  }

  /// Upload an image file to Cloudinary using direct HTTP request
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(File imageFile) async {
    try {
      if (_cloudName == null || _uploadPreset == null) {
        throw Exception(
          'Cloudinary not initialized. Call initialize() first.',
        );
      }

      AppLogger.general('📤 Uploading image to Cloudinary...');
      AppLogger.general('   File path: ${imageFile.path}');

      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }

      final fileSize = await imageFile.length();
      AppLogger.general('   File size: $fileSize bytes');

      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }

      AppLogger.general('   Starting upload...');
      AppLogger.general('   Cloud name: $_cloudName');
      AppLogger.general('   Upload preset: $_uploadPreset');

      // Prepare upload parameters
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/upload';
      AppLogger.general('   Upload URL: $uploadUrl');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'upload_preset': _uploadPreset!,
      });

      // Make the POST request
      final dio = Dio();
      final response = await dio.post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {'X-Requested-With': 'XMLHttpRequest'},
        ),
      );

      AppLogger.general('   Upload completed, checking response...');
      AppLogger.general('   Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final secureUrl = response.data['secure_url'] as String?;
        final publicId = response.data['public_id'] as String?;

        if (secureUrl == null || secureUrl.isEmpty) {
          throw Exception('Upload failed - no secure URL in response');
        }

        AppLogger.general('✅ Image uploaded successfully');
        AppLogger.general('   Public ID: $publicId');
        AppLogger.general('   Secure URL: $secureUrl');

        return secureUrl;
      } else {
        final errorMessage = response.data['error']?['message'] ?? 'Unknown error';
        throw Exception('Upload failed: $errorMessage');
      }
    } catch (e, stackTrace) {
      AppLogger.general(
        '❌ Error uploading image to Cloudinary: $e',
        level: AppLogger.error,
      );
      AppLogger.general('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Check if Cloudinary is initialized
  bool get isInitialized => _isInitialized;
}
