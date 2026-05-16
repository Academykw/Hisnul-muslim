import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class WidgetService {
  static const String _groupId = 'group.com.deen.adkhar'; // iOS only
  static const String _androidWidgetName = 'PrayerWidgetProvider';

  /// Updates the Home Screen Widget with the latest prayer info
  static Future<void> updatePrayerWidget({
    required String prayerName,
    required String prayerTime,
    required String location,
  }) async {
    try {
      debugPrint('WidgetService: Updating widget with $prayerName at $prayerTime');
      
      await HomeWidget.saveWidgetData<String>('next_prayer_name', prayerName);
      await HomeWidget.saveWidgetData<String>('next_prayer_time', prayerTime);
      await HomeWidget.saveWidgetData<String>('location_name', location);

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('WidgetService: Failed to update widget: $e');
    }
  }
}
