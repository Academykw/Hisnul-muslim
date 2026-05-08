import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/services/settings_service.dart';
import 'core/services/prayer_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/ad_service.dart';
import 'features/splash/splash_screen.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service instances
  final settings = SettingsService();
  final prayerService = PrayerService();
  final audioService = AudioService();
  final firebaseService = FirebaseService();
  final adService = AdService();

  try {
    await settings.init();
  } catch (e) {
    debugPrint("Settings init failed: $e");
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

  // Perform async initializations in the background
  _initServices(prayerService, firebaseService, adService);
}

Future<void> _initServices(
  PrayerService prayer,
  FirebaseService firebase,
  AdService ads,
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

  // 3. App Services
  try {
    await prayer.init();
  } catch (e) {
    debugPrint("Prayer service init failed: $e");
  }
}

class DeenAzkarApp extends StatelessWidget {
  const DeenAzkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch settings so the app reacts when theme is loaded/changed
    final settings = context.watch<SettingsService>();

    return MaterialApp(
      title: 'Deen Azkar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeAnimationStyle: AnimationStyle.noAnimation,
      themeMode: settings.themeMode,
      home: const SplashScreen(),
    );
  }
}
