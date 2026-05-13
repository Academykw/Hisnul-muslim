import 'dart:io';
import 'package:flutter/foundation.dart';


/// 
/// This class separates Ad logic from hardcoded values.
/// It uses [String.fromEnvironment] to allow injecting Real IDs during build time
/// which is a secure and professional practice for handling API keys.
class AdConfig {
  AdConfig._(); // Private constructor to prevent instantiation

  /// Set to true only if you want to test Real Ads in Debug mode.
  static const bool _forceRealAds = false;

  /// Global toggle for Test vs Real Ads
  static bool get useTestAds => kDebugMode && !_forceRealAds;

  /// Returns Banner Ad Unit ID based on Platform and Mode
  static String get bannerAdUnitId {
    if (useTestAds) return _TestAdIds.banner;

    return Platform.isAndroid
        ? const String.fromEnvironment('AD_BANNER_ANDROID', defaultValue: 'YOUR_ANDROID_BANNER_ID')
        : const String.fromEnvironment('AD_BANNER_IOS', defaultValue: 'YOUR_IOS_BANNER_ID');
  }

  /// Returns Interstitial Ad Unit ID based on Platform and Mode
  static String get interstitialAdUnitId {
    if (useTestAds) return _TestAdIds.interstitial;

    return Platform.isAndroid
        ? const String.fromEnvironment('AD_INTERSTITIAL_ANDROID', defaultValue: 'YOUR_ANDROID_INTERSTITIAL_ID')
        : const String.fromEnvironment('AD_INTERSTITIAL_IOS', defaultValue: 'YOUR_IOS_INTERSTITIAL_ID');
  }
}

/// Official Google Test Ad Unit IDs
/// It is safe and professional to keep these hardcoded as they are for testing only.
abstract class _TestAdIds {
  static String get banner => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  static String get interstitial => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';
}
