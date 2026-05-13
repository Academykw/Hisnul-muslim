import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/ad_config.dart';
import 'firebase_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob Initialized');
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('AdMob Initialization Error: $e');
    }
  }

  void _loadInterstitialAd() {
    String adUnitId;
    if (AdConfig.useTestAds) {
      adUnitId = AdConfig.interstitialAdUnitId;
    } else {
      // Try Firebase Remote Config first, fallback to AdConfig local ID
      adUnitId = FirebaseService().getInterstitialAdUnitId();
      if (adUnitId.isEmpty) {
        adUnitId = AdConfig.interstitialAdUnitId;
      }
    }

    if (adUnitId.isEmpty) {
      debugPrint('Interstitial Ad Unit ID is empty');
      return;
    }

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('InterstitialAd loaded');
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          _interstitialAd?.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            _loadInterstitialAd();
          }
        },
      ),
    );
  }

  int _navigationCount = 0;
  static const int adInterval = 5; // Show ad every 4th navigation

  void showInterstitialAd({VoidCallback? onAdDismissed, bool ignoreInterval = false}) {
    if (!ignoreInterval) {
      _navigationCount++;
      if (_navigationCount % adInterval != 0) {
        onAdDismissed?.call();
        return;
      }
    }

    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded');
      onAdDismissed?.call();
      _loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('InterstitialAd dismissed');
        ad.dispose();
        _loadInterstitialAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('InterstitialAd failed to show: $error');
        ad.dispose();
        _loadInterstitialAd();
        onAdDismissed?.call();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  bool get isInitialized => _isInitialized;
}
