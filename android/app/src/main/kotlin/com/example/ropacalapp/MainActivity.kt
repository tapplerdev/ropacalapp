package com.example.ropacalapp

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.ropacal.app/navigation"
    private val TAG = "NavigationBridge"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up method channel for native navigation calls
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "forceDayMode" -> {
                    try {
                        Log.d(TAG, "forceDayMode called from Flutter")

                        // The Google Navigation SDK is obfuscated, so we can't reliably use reflection
                        // Instead, we'll return a message indicating this feature is not available
                        // in the current Flutter SDK version

                        Log.d(TAG, "ForceNightMode API is not exposed in Flutter SDK v0.7.0")
                        Log.d(TAG, "The native API exists but is obfuscated and not accessible")
                        Log.d(TAG, "Workaround: Using custom map styles in Flutter layer")

                        // Return false to indicate native method is not available
                        // Flutter layer will fall back to map style approach
                        result.success(false)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to set forceDayMode", e)
                        result.error("FORCE_DAY_MODE_ERROR", e.message, e.toString())
                    }
                }
                "isAvailable" -> {
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
