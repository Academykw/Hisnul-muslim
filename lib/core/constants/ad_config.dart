import 'package:flutter/foundation.dart';

class AdConfig {
  /// Toggle this to false to force real ads even in debug mode (NOT RECOMMENDED)
  static const bool _forceRealAds = false;

  /// Returns true if test ads should be used
  static bool get useTestAds => kDebugMode && !_forceRealAds;

  // Banner Ad IDs
  static const String bannerAdUnitId = useTestAds 
    ? 'ca-app-pub-3940256099942544/6300978111' // Test ID
    : 'YOUR_REAL_BANNER_ID_HERE'; // <--- Put your real banner ID here

  // Interstitial Ad IDs
  static const String interstitialAdUnitId = useTestAds
    ? 'ca-app-pub-3940256099942544/1033173712' // Test ID
    : 'YOUR_REAL_INTERSTITIAL_ID_HERE'; // <--- Put your real interstitial ID here
}
