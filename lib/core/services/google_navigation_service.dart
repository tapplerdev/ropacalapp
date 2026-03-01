import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/location_provider.dart';

/// Service for managing Google Maps Navigation lifecycle and operations
class GoogleNavigationService {
  GoogleNavigationService._(); // Private constructor - utility class

  /// Initialize Google Maps Navigator (Terms & Conditions, session, audio)
  static Future<void> initializeNavigation(BuildContext context, WidgetRef ref) async {
    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.general('🚀 [GoogleNavigationService] Starting initialization');
    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // DIAGNOSTIC: Check if session already exists
      AppLogger.general('🔍 [DIAGNOSTIC] Checking for existing navigation session...');
      bool isGuidanceRunning = false;
      try {
        isGuidanceRunning = await GoogleMapsNavigator.isGuidanceRunning();
        AppLogger.general('   Existing guidance running: $isGuidanceRunning');
      } catch (e) {
        AppLogger.general('   Could not check guidance status: $e');
      }

      // If guidance is running, cleanup first
      if (isGuidanceRunning) {
        AppLogger.general('⚠️  [DIAGNOSTIC] Found existing navigation session - cleaning up first');
        try {
          await GoogleMapsNavigator.cleanup();
          AppLogger.general('✅ [DIAGNOSTIC] Cleaned up existing session');
          // Wait a moment for cleanup to complete
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          AppLogger.general('⚠️  [DIAGNOSTIC] Cleanup failed (may be okay): $e');
        }
      }

      // Check if T&C dialog needs to be shown
      // T&C state is preserved across sessions - only shows once ever
      AppLogger.general('📋 [STEP 1/3] Checking Terms & Conditions acceptance...');
      final termsAccepted = await GoogleMapsNavigator.areTermsAccepted();
      AppLogger.general('   Terms accepted: $termsAccepted');

      if (!termsAccepted) {
        AppLogger.general('📋 Showing terms and conditions dialog (first time only)...');
        await GoogleMapsNavigator.showTermsAndConditionsDialog(
          'Navigation Terms',
          'Ropacal Navigation',
        );
        AppLogger.general('✅ Terms accepted (will be remembered)');
      } else {
        AppLogger.general('✅ Terms previously accepted, skipping dialog');
      }

      // Initialize navigation session with task removed behavior
      // TaskRemovedBehavior.continueService keeps navigation running when app is swiped away (Android)
      AppLogger.general('🗺️  [STEP 2/3] Calling GoogleMapsNavigator.initializeNavigationSession()...');
      AppLogger.general('   TaskRemovedBehavior: continueService');

      try {
        await GoogleMapsNavigator.initializeNavigationSession(
          taskRemovedBehavior: TaskRemovedBehavior.continueService,
        );
        AppLogger.general('✅ Navigation session initialized successfully');
      } catch (e, stackTrace) {
        AppLogger.general('❌ [CRITICAL] initializeNavigationSession() FAILED');
        AppLogger.general('   Error type: ${e.runtimeType}');
        AppLogger.general('   Error message: $e');
        AppLogger.general('   Stack trace: ${stackTrace.toString().split('\n').take(5).join('\n')}');
        rethrow;
      }

      // Set audio guidance to enabled by default
      AppLogger.general('🔊 [STEP 3/3] Configuring audio guidance...');
      await GoogleMapsNavigator.setAudioGuidance(
        NavigationAudioGuidanceSettings(
          guidanceType: NavigationAudioGuidanceType.alertsAndGuidance,
        ),
      );
      AppLogger.general('✅ Audio guidance enabled (alertsAndGuidance)');

      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('🎉 [GoogleNavigationService] Initialization complete!');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stackTrace) {
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('❌ [GoogleNavigationService] INITIALIZATION FAILED');
      AppLogger.general('   Error: $e');
      AppLogger.general('   Type: ${e.runtimeType}');
      AppLogger.general('   Stack: ${stackTrace.toString().split('\n').take(10).join('\n   ')}');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Wait for location to be ready before proceeding
  static Future<void> waitForLocationReady(WidgetRef ref) async {
    AppLogger.general('📍 Waiting for location to be ready...');

    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      final location = ref.read(currentLocationProvider).valueOrNull;
      if (location != null) {
        AppLogger.general('✅ Location ready after $attempts attempts');
        return;
      }

      attempts++;
      AppLogger.general('⏳ Location not ready, attempt $attempts/$maxAttempts');
      await Future.delayed(const Duration(seconds: 1));
    }

    AppLogger.general('⚠️  Location timeout after $maxAttempts attempts, proceeding anyway');
  }

  /// Toggle audio guidance on/off
  static void toggleAudio(bool currentMutedState, Function(bool) setMuted) {
    final newMutedState = !currentMutedState;
    setMuted(newMutedState);

    if (newMutedState) {
      GoogleMapsNavigator.setAudioGuidance(
        NavigationAudioGuidanceSettings(
          guidanceType: NavigationAudioGuidanceType.silent,
        ),
      );
      AppLogger.general('🔇 Audio muted');
    } else {
      GoogleMapsNavigator.setAudioGuidance(
        NavigationAudioGuidanceSettings(
          guidanceType: NavigationAudioGuidanceType.alertsAndGuidance,
        ),
      );
      AppLogger.general('🔊 Audio unmuted');
    }
  }
}
