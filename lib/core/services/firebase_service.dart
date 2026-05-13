import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../models/daily_inspiration.dart';
import '../constants/app_constants.dart';

class FirebaseService extends ChangeNotifier {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseFirestore? _db;
  FirebaseDatabase? _rtdb;
  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  DailyInspiration? _dailyInspiration;
  DailyInspiration? get dailyInspiration => _dailyInspiration;

  Map<String, double> _nisabValues = {};
  Map<String, double> get nisabValues => _nisabValues;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Default placeholder to show when network is unavailable or fetch fails
  DailyInspiration get _placeholder => DailyInspiration(
        id: 'placeholder',
        content: AppConstants.fallbackInspirationContent,
        source: AppConstants.fallbackInspirationSource,
        type: "Aya",
        date: DateTime.now(),
      );

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      debugPrint("FirebaseService: Starting initialization...");
      await Firebase.initializeApp().timeout(const Duration(seconds: 15));
      debugPrint("FirebaseService: App initialized");

      _db = FirebaseFirestore.instance;
      _rtdb = FirebaseDatabase.instance;
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig?.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      debugPrint("FirebaseService: Fetching Remote Config...");
      await _remoteConfig?.fetchAndActivate().timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint("FirebaseService: Remote Config fetch timed out");
        return false;
      });

      _isInitialized = true;
      debugPrint("FirebaseService: Initialization complete");
      
      // Pre-fetch nisab values (don't let this block the main init success)
      fetchNisabValues();
    } catch (e) {
      debugPrint("FirebaseService: Initialization failed: $e");
    }
  }

  String getBannerAdUnitId() {
    return _remoteConfig?.getString('ad_banner_unit_id') ?? '';
  }

  String getInterstitialAdUnitId() {
    return _remoteConfig?.getString('ad_interstitial_unit_id') ?? '';
  }

  Future<void> fetchNisabValues() async {
    if (!_isInitialized || _rtdb == null) return;
    try {
      debugPrint("FirebaseService: Fetching nisab values...");
      final snapshot = await _rtdb!.ref('nisab').get().timeout(const Duration(seconds: 10));
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          _nisabValues = data.map((key, value) {
            return MapEntry(key.toString(), (value as num).toDouble());
          });
          debugPrint("FirebaseService: Nisab values fetched successfully");
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("FirebaseService: Error fetching nisab values: $e");
    }
  }

  double getNisabForCurrency(String currency) {
    return _nisabValues[currency] ?? 595.0; // Default fallback
  }

  Future<void> fetchDailyInspiration() async {
    try {
      final db = _db;
      if (!_isInitialized || db == null) {
        debugPrint(
          "Firebase is not initialized, using placeholder inspiration.",
        );
        _dailyInspiration ??= _placeholder;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 1. Check connectivity first
      final List<ConnectivityResult> connectivityResult =
          await Connectivity().checkConnectivity();
      final hasNetwork = connectivityResult.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (!hasNetwork) {
        debugPrint("No network available, using placeholder inspiration.");
        _dailyInspiration ??= _placeholder;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _isLoading = true;
      notifyListeners();

      final today = DateTime.now();
      final dateKey =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // Attempt to fetch today's specific inspiration
      final doc = await db
          .collection('daily_inspiration')
          .doc(dateKey)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists) {
        _dailyInspiration = DailyInspiration.fromFirestore(doc.data()!, doc.id);
      } else {
        // Fallback to the latest available inspiration in Firestore
        final query = await db
            .collection('daily_inspiration')
            .orderBy('date', descending: true)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));

        if (query.docs.isNotEmpty) {
          _dailyInspiration = DailyInspiration.fromFirestore(
            query.docs.first.data(),
            query.docs.first.id,
          );
        } else {
          _dailyInspiration = _placeholder;
        }
      }
    } catch (e) {
      debugPrint("Error fetching daily inspiration: $e");
      // Use placeholder if fetch fails and we don't have existing data
      _dailyInspiration ??= _placeholder;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
