import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Mapbox removed - using Google Navigation SDK instead
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/router/app_router.dart';
import 'package:ropacalapp/services/fcm_service.dart';
import 'package:ropacalapp/core/services/session_manager.dart';

void main() async {
  // Note: Navigation session is now initialized lazily when first needed
  // (when opening a page that uses GoogleMapsNavigationView)
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM (Firebase Cloud Messaging)
  await FCMService.initialize();

  runApp(const ProviderScope(child: RopacalApp()));

  // Configure EasyLoading
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = AppColors.primaryBlue
    ..backgroundColor = Colors.white
    ..indicatorColor = AppColors.primaryBlue
    ..textColor = Colors.black87
    ..maskColor = Colors.black.withOpacity(0.5)
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
        // App came to foreground - session will be checked on splash
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

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Bin Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF2D2D31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade800, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.darkBackground,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.light, // Always use light theme
      routerConfig: router,
      builder: EasyLoading.init(),
    );
  }
}
