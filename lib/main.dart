import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
// Mapbox removed - using Google Navigation SDK instead
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/router/app_router.dart';
import 'package:ropacalapp/services/fcm_service.dart';
import 'package:ropacalapp/core/services/session_manager.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/core/notifications/notification_service.dart';
import 'package:ropacalapp/core/notifications/notification_registry.dart';
import 'package:ropacalapp/core/notifications/notification_event.dart';
import 'package:ropacalapp/providers/notification_provider.dart';

void main() async {
  // Note: Navigation session is now initialized lazily when first needed
  // (when opening a page that uses GoogleMapsNavigationView)
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Set backend URL for diagnostic logging
  final backendUrl = dotenv.env['API_BASE_URL'] ?? '';
  if (backendUrl.isNotEmpty) {
    AppLogger.setBackendUrl(backendUrl);
  }

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM (Firebase Cloud Messaging)
  await FCMService.initialize();

  // Initialize awesome_notifications
  await NotificationService().initialize();

  // Pre-cache common marker icons for better performance
  await GoogleNavigationMarkerService.preCacheCommonMarkers();

  runApp(const ProviderScope(child: RopacalApp()));

  // Configure EasyLoading
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.circle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 60.0
    ..lineWidth = 5.0
    ..radius = 10.0
    ..progressColor = AppColors.primaryGreen
    ..backgroundColor = Colors.white
    ..indicatorColor = AppColors.primaryGreen
    ..textColor = Colors.black87
    ..maskColor = Colors.black.withValues(alpha: 0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

class RopacalApp extends ConsumerStatefulWidget {
  const RopacalApp({super.key});

  @override
  ConsumerState<RopacalApp> createState() => _RopacalAppState();
}

class _RopacalAppState extends ConsumerState<RopacalApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - restore shift state from backend (drivers only)
        _restoreShiftState();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App going to background - update timestamp
        SessionManager.updateLastActive();
        break;
    }
  }

  /// Restore shift state from backend when app resumes (ONLY for drivers)
  Future<void> _restoreShiftState() async {
    try {
      // Get current user to check role
      final user = ref.read(authNotifierProvider).valueOrNull;

      // Only fetch shift for drivers - managers don't have shifts
      if (user?.role == UserRole.driver) {
        AppLogger.general('[LIFECYCLE] 📱 Driver app resumed - fetching current shift...');
        await ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
        AppLogger.general('[LIFECYCLE] ✅ Shift state restored from backend');
      } else {
        AppLogger.general('[LIFECYCLE] 👔 Manager app resumed - skipping shift fetch (managers don\'t have shifts)');
      }
    } catch (e) {
      AppLogger.general('[LIFECYCLE] ⚠️  Error restoring shift: $e');
      // Continue anyway - user can refresh manually if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    // Initialize auth event listener (triggers shift fetch on driver login)
    ref.watch(authEventListenerProvider);

    // Set router reference for notification deep-linking
    NotificationService.router = router;

    return MaterialApp.router(
      title: 'Bin Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        useMaterial3: true,
        textTheme: GoogleFonts.montserratTextTheme(
          ThemeData.light().textTheme,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.brandGreen,
          iconTheme: IconThemeData(color: AppColors.brandGreen),
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.brandGreen,
            letterSpacing: -0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        useMaterial3: true,
        textTheme: GoogleFonts.montserratTextTheme(
          ThemeData.dark().textTheme,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF2D2D31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade800, width: 1),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.brandGreen,
          iconTheme: IconThemeData(color: AppColors.brandGreen),
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.brandGreen,
            letterSpacing: -0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.light, // Always use light theme
      routerConfig: router,
      builder: (context, child) {
        // Chain EasyLoading init with in-app notification overlay
        final easyLoadingBuilder = EasyLoading.init();
        final wrappedChild = easyLoadingBuilder(context, child);
        return _InAppNotificationOverlay(child: wrappedChild ?? child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Listens to the in-app notification stream and shows a Material Banner
/// for critical/high-priority events while the app is in the foreground.
class _InAppNotificationOverlay extends ConsumerWidget {
  final Widget child;
  const _InAppNotificationOverlay({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<NotificationEvent?>(
      inAppNotificationStreamProvider,
      (previous, next) {
        if (next == null) return;

        final config = NotificationRegistry.getConfig(next.eventType);
        if (config == null) return;

        final title = config.titleBuilder(next.payload);
        final body = config.bodyBuilder(next.payload);
        final isCritical =
            config.priority == NotificationPriority.critical;

        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;

        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isCritical
                      ? Icons.error_outline
                      : Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (body.isNotEmpty)
                        Text(
                          body,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: isCritical
                ? AppColors.alertRed
                : AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            duration: Duration(seconds: isCritical ? 6 : 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white70,
              onPressed: () {
                messenger.hideCurrentSnackBar();
              },
            ),
          ),
        );

        // Clear after showing so it doesn't re-trigger on rebuild
        ref.read(inAppNotificationStreamProvider.notifier).clear();
      },
    );

    return child;
  }
}
