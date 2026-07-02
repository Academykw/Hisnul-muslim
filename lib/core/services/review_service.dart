import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ReviewService {
  static const String _keyInstallDate = 'pref_install_date';
  static const String _keyReviewShown = 'pref_review_shown';
  static const String _keyLastAttemptDate = 'pref_last_review_attempt_date';
  
  final InAppReview _inAppReview = InAppReview.instance;

  /// Call this on app start to initialize the installation date if it doesn't exist
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_keyInstallDate) == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_keyInstallDate, now);
      debugPrint('ReviewService: Set install date to $now');
    }
  }

  /// Checks if the app should show the review prompt and shows it if necessary
  Future<void> checkAndRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // If the user has already successfully submitted a review (or we recorded success), don't show again
      if (prefs.getBool(_keyReviewShown) ?? false) return;

      final now = DateTime.now();
      final installDateMs = prefs.getInt(_keyInstallDate);
      final lastAttemptMs = prefs.getInt(_keyLastAttemptDate);

      if (installDateMs == null) return;
      final installDate = DateTime.fromMillisecondsSinceEpoch(installDateMs);

      // Rule 1: First check must be after 7 days
      // In debug mode, we allow it after 0 days for testing
      final daysRequired = kDebugMode ? 0 : 7;
      if (now.difference(installDate).inDays < daysRequired) {
        debugPrint('ReviewService: Too early for first review (Needs $daysRequired days)');
        return;
      }

      // Rule 2: If we previously attempted (user clicked Not Now), wait 5 more days
      // In debug mode, we allow it after 0 days for testing
      final retryDaysRequired = kDebugMode ? 0 : 5;
      if (lastAttemptMs != null) {
        final lastAttempt = DateTime.fromMillisecondsSinceEpoch(lastAttemptMs);
        if (now.difference(lastAttempt).inDays < retryDaysRequired) {
          debugPrint('ReviewService: Waiting $retryDaysRequired days since last "Not Now" action');
          return;
        }
      }

      // If we reach here, we are ready to show the review
      if (await _inAppReview.isAvailable()) {
        debugPrint('ReviewService: Requesting review dialog...');
        
        // Update last attempt date BEFORE showing, to handle "Not Now" cases
        await prefs.setInt(_keyLastAttemptDate, now.millisecondsSinceEpoch);
        
        await _inAppReview.requestReview();
        
        // Note: requestReview() doesn't return whether the user actually reviewed.
        // It just shows the system UI. We track the attempt to avoid being spammy.
      }
    } catch (e) {
      debugPrint('ReviewService: Failed to request review: $e');
    }
  }

  /// Manually open the store for review
  Future<void> openStoreListing() async {
    await _inAppReview.openStoreListing(
      appStoreId: 'YOUR_APP_STORE_ID', // TODO: Update for iOS
    );
  }
}
