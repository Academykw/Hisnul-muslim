import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  static Future<void> checkForUpdate() async {
    // Only works on Android
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('UpdateService: Skipping update check (Not Android)');
      return;
    }

    try {
      debugPrint('UpdateService: Checking for updates...');
      final info = await InAppUpdate.checkForUpdate().timeout(const Duration(seconds: 15));
      
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('UpdateService: Update available! info: $info');
        // Only show updates if we are on the main screen (user is not busy)
        // We add a small delay here too
        await Future.delayed(const Duration(seconds: 3));

        if (info.immediateUpdateAllowed) {
          debugPrint('UpdateService: Starting immediate update');
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          debugPrint('UpdateService: Starting flexible update');
          await InAppUpdate.startFlexibleUpdate();
          debugPrint('UpdateService: Flexible update downloaded, completing...');
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else {
        debugPrint('UpdateService: No update available or not allowed');
      }
    } catch (e) {
      debugPrint('UpdateService: In-app update check failed: $e');
    }
  }
}
