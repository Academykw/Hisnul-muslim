import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../core/services/firebase_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  /// SET THIS TO FALSE FOR PRODUCTION
  static const bool _useTestAds = true;

  /// Official Google Test Banner Unit ID for Android
  static const String _androidTestUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() {
    final firebaseService = context.read<FirebaseService>();
    
    // Determine which ID to use
    String adUnitId;
    if (_useTestAds || kDebugMode) {
      adUnitId = _androidTestUnitId;
    } else {
      adUnitId = firebaseService.getBannerAdUnitId();
    }

    if (adUnitId.isEmpty) {
      debugPrint('Banner Ad Unit ID is empty');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && _isLoaded) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        color: Colors.transparent,
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Wrapper widget for safe top banner ad placement with visual separation
class SafeTopBannerAd extends StatelessWidget {
  const SafeTopBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top padding to prevent accidental clicks
        const SizedBox(height: 8),
        // Banner Ad
        const BannerAdWidget(),
        // Bottom padding and visual separator
        Container(
          height: 1,
          color: Colors.grey.withValues(alpha: 0.1),
        ),
      ],
    );
  }
}

