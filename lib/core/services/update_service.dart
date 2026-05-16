import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  static Future<void> checkForUpdate() async {
    // Only works on Android and in release mode (mostly)
    if (kIsWeb || !defaultTargetPlatform.toString().contains('android')) return;

    try {
      final info = await InAppUpdate.checkForUpdate().timeout(const Duration(seconds: 15));
      
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // Only show updates if we are on the main screen (user is not busy)
        // We add a small delay here too
        await Future.delayed(const Duration(seconds: 5));

        if (info.immediateUpdateAllowed) {
          // Perform immediate update
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          // Perform flexible update
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('In-app update check failed: $e');
    }
  }
}
