import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:deen_azkar/l10n/app_localizations.dart';
import 'core/services/settings_service.dart';
import 'core/services/prayer_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/update_service.dart';
import 'core/services/review_service.dart';
import 'features/splash/splash_screen.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Use a global error handler to catch initialization crashes
  FlutterError.onError = (details) {
    debugPrint("Flutter Error: ${details.exception}");
    debugPrint("Stack Trace: ${details.stack}");
  };

  // Initialize service instances
  final settings = SettingsService();
  final prayerService = PrayerService();
  final audioService = AudioService();
  final firebaseService = FirebaseService();
  final adService = AdService();
  final reviewService = ReviewService();

  try {
    await settings.init();
    await reviewService.init();
  } catch (e) {
    debugPrint("Settings or Review init failed: $e");
  }

  try {
    await prayerService.restoreCachedLocation();
  } catch (e) {
    debugPrint("Cached prayer location restore failed: $e");
  }

  // Run app immediately to avoid black screen
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: prayerService),
        ChangeNotifierProvider.value(value: audioService),
        ChangeNotifierProvider.value(value: firebaseService),
        Provider.value(value: adService),
      ],
      child: const DeenAzkarApp(),
    ),
  );

  // Perform async initializations in the background after a short delay
  // to ensure the UI starts up smoothly first
  Future.delayed(const Duration(seconds: 2), () {
    _initServices(prayerService, firebaseService, adService, reviewService);
  });
}

Future<void> _initServices(
  PrayerService prayer,
  FirebaseService firebase,
  AdService ads,
  ReviewService review,
) async {
  // 1. Orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2. Firebase & Ads (with timeout/error handling to prevent hanging)
  try {
    await firebase.init();
    await firebase.fetchDailyInspiration();
    await ads.init();
  } catch (e) {
    debugPrint("Firebase/Ads init failed or timed out: $e");
  }

  // 3. App Services (Run independently to avoid blocking each other)
  prayer.init().catchError((e) => debugPrint("Prayer service init failed: $e"));
  
  // Update check often fails in debug/emulator, so we run it separately
  UpdateService.checkForUpdate();
  
  // Review check has its own internal logic and timing
  review.checkAndRequestReview();
}

class DeenAzkarApp extends StatelessWidget {
  const DeenAzkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch settings so the app reacts when theme is loaded/changed
    final settings = context.watch<SettingsService>();

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeAnimationStyle: AnimationStyle.noAnimation,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashScreen(),
    );
  }
}
