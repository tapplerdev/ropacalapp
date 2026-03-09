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

/// Listens to the in-app notification stream and shows a custom animated
/// banner from the top of the screen for in-app notification events.
class _InAppNotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const _InAppNotificationOverlay({required this.child});

  @override
  ConsumerState<_InAppNotificationOverlay> createState() =>
      _InAppNotificationOverlayState();
}

class _InAppNotificationOverlayState
    extends ConsumerState<_InAppNotificationOverlay> {
  OverlayEntry? _currentEntry;

  @override
  void dispose() {
    _currentEntry?.remove();
    _currentEntry = null;
    super.dispose();
  }

  void _showBanner(NotificationEvent event) {
    _currentEntry?.remove();
    _currentEntry = null;

    final config = NotificationRegistry.getConfig(event.eventType);
    if (config == null) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _NotificationBanner(
        event: event,
        config: config,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NotificationEvent?>(
      inAppNotificationStreamProvider,
      (previous, next) {
        if (next == null) return;
        _showBanner(next);
        ref.read(inAppNotificationStreamProvider.notifier).clear();
      },
    );
    return widget.child;
  }
}

/// Animated notification banner card — slides down from the top with a fade,
/// styled to match the app's card design language.
class _NotificationBanner extends StatefulWidget {
  final NotificationEvent event;
  final NotificationTypeConfig config;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    required this.event,
    required this.config,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    final isCritical =
        widget.config.priority == NotificationPriority.critical;
    Future.delayed(Duration(seconds: isCritical ? 6 : 4), _dismiss);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  Color _accentColor() {
    switch (widget.config.priority) {
      case NotificationPriority.critical:
        return AppColors.alertRed;
      case NotificationPriority.high:
        return AppColors.warningOrange;
      case NotificationPriority.normal:
      case NotificationPriority.low:
        return AppColors.primaryGreen;
    }
  }

  IconData _icon() {
    final type = widget.event.eventType;
    if (type.startsWith('shift_') || type.startsWith('task_')) {
      return Icons.event_note_rounded;
    }
    if (type.startsWith('route_')) return Icons.route_rounded;
    if (type.startsWith('move_request_')) return Icons.swap_horiz_rounded;
    if (type.startsWith('bin_')) return Icons.delete_rounded;
    if (type.startsWith('driver_')) return Icons.person_rounded;
    return Icons.notifications_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.config.titleBuilder(widget.event.payload);
    final body = widget.config.bodyBuilder(widget.event.payload);
    final accent = _accentColor();
    final isCritical =
        widget.config.priority == NotificationPriority.critical;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            bottom: false,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy < -100) {
                  _dismiss();
                }
              },
              onTap: _dismiss,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // Left accent strip
                          Container(width: 5, color: accent),
                          const SizedBox(width: 14),
                          // Icon container
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isCritical
                                    ? Icons.warning_amber_rounded
                                    : _icon(),
                                color: accent,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Text content
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (body.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      body,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // Close button
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: _dismiss,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
