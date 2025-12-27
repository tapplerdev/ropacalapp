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
    AppLogger.general('🚀 Initializing Google Maps Navigator...');

    try {
      // Check if T&C dialog needs to be shown
      // T&C state is preserved across sessions - only shows once ever
      final termsAccepted = await GoogleMapsNavigator.areTermsAccepted();
      AppLogger.general('📋 Terms accepted: $termsAccepted');

      if (!termsAccepted) {
        AppLogger.general('📋 Showing terms and conditions dialog (first time only)...');
        await GoogleMapsNavigator.showTermsAndConditionsDialog(
          'Navigation Terms',
          'Ropacal Navigation',
        );
        AppLogger.general('✅ Terms accepted (will be remembered)');
      } else {
        AppLogger.general('✅ Terms previously accepted, reusing session');
      }

      // Initialize navigation session with task removed behavior
      // TaskRemovedBehavior.continueService keeps navigation running when app is swiped away (Android)
      // This can be called multiple times safely - reuses session if exists
      await GoogleMapsNavigator.initializeNavigationSession(
        taskRemovedBehavior: TaskRemovedBehavior.continueService,
      );
      AppLogger.general('✅ Navigation session initialized (continueService on task remove)');

      // Set audio guidance to enabled by default
      await GoogleMapsNavigator.setAudioGuidance(
        NavigationAudioGuidanceSettings(
          guidanceType: NavigationAudioGuidanceType.alertsAndGuidance,
        ),
      );
      AppLogger.general('🔊 Audio guidance enabled');
    } catch (e) {
      AppLogger.general('❌ Navigation initialization error: $e');
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
