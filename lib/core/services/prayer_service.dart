import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../constants/app_constants.dart';

@pragma('vm:entry-point')
void prayerNotificationTapBackground(NotificationResponse response) {
  if (response.actionId == PrayerService.stopAdhanActionId ||
      response.payload == PrayerService.stopAdhanPayload) {
    unawaited(PrayerService().stopAdhan());
  }
}

class PrayerService extends ChangeNotifier {
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal();

  static const String _prayerNotificationChannelId = 'prayer_times_adhan_v4';
  static const String _activeAdhanChannelId = 'active_adhan_control_v1';
  static const String _lastAdhanNotificationKey = 'last_adhan_notification_key';
  static const String stopAdhanActionId = 'stop_adhan';
  static const String stopAdhanPayload = 'stop_adhan';
  static const MethodChannel _adhanAlarmChannel =
      MethodChannel(AppConstants.adhanAlarmChannel);
  static const String _lastLocationLatKey = 'last_lat';
  static const String _lastLocationLonKey = 'last_lon';
  static const String _lastLocationAddressKey = 'last_address';
  static const String _lastLocationRefreshKey = 'last_location_refresh_time';
  static const String _lastLocationAccuracyKey = 'last_location_accuracy';
  static const String _lastLocationAltitudeKey = 'last_location_altitude';
  static const String _lastLocationHeadingKey = 'last_location_heading';
  static const String _lastLocationSpeedKey = 'last_location_speed';
  static const String _lastLocationSpeedAccuracyKey =
      'last_location_speed_accuracy';
  static const String _lastLocationAltitudeAccuracyKey =
      'last_location_altitude_accuracy';
  static const String _lastLocationHeadingAccuracyKey =
      'last_location_heading_accuracy';
  static const String _lastLocationTimestampKey = 'last_location_timestamp';
  static const String _lastLocationFloorKey = 'last_location_floor';
  static const String _lastLocationIsMockedKey = 'last_location_is_mocked';
  static const int _androidDuaReminderScheduleDays = 7;
  static const int _defaultDuaReminderScheduleDays = 7;
  static const int _fastingReminderBaseId = 3000;

  Position? _currentPosition;
  String _currentAddress = "Loading location...";
  PrayerTimes? _prayerTimes;
  bool _isLoading = false;
  bool _notificationsReady = false;
  Timer? _adhanWatcher;
  String? _lastShownAdhanKey;
  final AudioPlayer _adhanPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _adhanPlayerStateSubscription;

  PrayerTimes? get prayerTimes => _prayerTimes;
  String get currentAddress => _currentAddress;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init({bool requestPermissions = true}) async {
    tz.initializeTimeZones();
    await _refreshLocalTimezone();

    await _initNotifications();
    await AndroidAlarmManager.initialize();
    _notificationsReady = true;
    await _loadLastShownAdhanKey();
    await restoreCachedLocation(scheduleNotifications: false);
    await _scheduleDuaReminders(requestNotificationPermission: requestPermissions);
    _startAdhanWatcher();
  }

  Future<void> restoreCachedLocation({
    bool scheduleNotifications = false,
  }) async {
    final restored = await _loadSavedLocation(
      scheduleNotifications: scheduleNotifications,
    );
    if (restored) notifyListeners();
  }

  Future<void> completeInitialPrayerSetup() async {
    await requestPermissions();
    
    // Only auto-refresh location if it's the first time or 24+ hours have passed
    final canAutoRefresh = await _canAutoRefreshLocation();
    if (canAutoRefresh) {
      await updateLocation();
    }
    
    await refreshDeviceTimeSettings();
  }

  Future<void> refreshDeviceTimeSettings() async {
    await _refreshLocalTimezone();
    if (_currentPosition != null) {
      _calculatePrayers();
    }
    notifyListeners();
  }

  Future<void> _refreshLocalTimezone() async {
    try {
      final res = await FlutterTimezone.getLocalTimezone();
      // In flutter_timezone 5.0.2, getLocalTimezone() returns a TimezoneInfo object
      final String timeZoneName = res.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Local timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('Failed to set local timezone: $e. Falling back to UTC.');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
  }

  Future<void> requestPermissions() async {
    await requestNotificationPermission();

    // Also request exact alarm permission for Android 12+
    await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await _requestBatteryOptimizationExemption();
  }

  Future<bool> requestNotificationPermission() async {
    if (!_isAndroid) return true;

    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted =
        await androidImplementation?.requestNotificationsPermission();
    final enabled = await androidImplementation?.areNotificationsEnabled();
    return enabled ?? granted ?? false;
  }

  Future<bool> _notificationsAllowed({
    required bool requestIfNeeded,
  }) async {
    if (!_isAndroid) return true;

    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    var enabled = await androidImplementation?.areNotificationsEnabled();

    if (enabled != true && requestIfNeeded) {
      await androidImplementation?.requestNotificationsPermission();
      await Future.delayed(const Duration(milliseconds: 500));
      enabled = await androidImplementation?.areNotificationsEnabled();
    }

    if (enabled != true) {
      debugPrint('Notifications are disabled; azkar reminders cannot show.');
    }

    return enabled ?? false;
  }

  Future<bool> _canAutoRefreshLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRefreshMs = prefs.getInt(_lastLocationRefreshKey);

    if (lastRefreshMs == null) {
      return true; // First time, allow refresh
    }

    final lastRefresh = DateTime.fromMillisecondsSinceEpoch(lastRefreshMs);
    final now = DateTime.now();

    // Only auto-refresh if more than 24 hours have passed
    return now.difference(lastRefresh).inHours >= 24;
  }

  Future<void> _saveLocationRefreshTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastLocationRefreshKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> scheduleTestNotification() async {
    if (!_notificationsReady) return;
    
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 10));
    
    debugPrint('Scheduling TEST notification for $testTime');
    
    // We use a simple schedule for testing
    await _notifications.zonedSchedule(
      9999,
      'Test Notification',
      'This is a test notification from Deen Azkar.',
      tz.TZDateTime.from(testTime, tz.local),
      _reminderNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    if (!_isAndroid) return;

    try {
      await _adhanAlarmChannel.invokeMethod<bool>(
        'requestBatteryOptimizationExemption',
      );
    } on PlatformException catch (e) {
      debugPrint('Unable to request battery optimization exemption: $e');
    }
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: prayerNotificationTapBackground,
    );

    // Create Notification Channels for Android
    if (_isAndroid) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          _prayerNotificationChannelId,
          'Prayer Times Adhan',
          description: 'Notifications for prayer times with Adhan sound',
          importance: Importance.max,
          playSound: true,
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'dua_reminders_channel_v4',
          'Dua Reminders',
          description: 'Reminders for morning and evening azkar',
          importance: Importance.max,
        ),
      );
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == stopAdhanActionId ||
        response.payload == stopAdhanPayload) {
      unawaited(stopAdhan());
    }
  }

  Future<void> _loadLastShownAdhanKey() async {
    final prefs = await SharedPreferences.getInstance();
    _lastShownAdhanKey = prefs.getString(_lastAdhanNotificationKey);
  }

  Future<bool> _loadSavedLocation({
    required bool scheduleNotifications,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_lastLocationLatKey);
    final lon = prefs.getDouble(_lastLocationLonKey);
    final address = prefs.getString(_lastLocationAddressKey);

    if (lat == null || lon == null) return false;

    final timestampMs = prefs.getInt(_lastLocationTimestampKey);
    _currentPosition = Position(
      latitude: lat,
      longitude: lon,
      timestamp: timestampMs == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(timestampMs),
      accuracy: prefs.getDouble(_lastLocationAccuracyKey) ?? 0,
      altitude: prefs.getDouble(_lastLocationAltitudeKey) ?? 0,
      heading: prefs.getDouble(_lastLocationHeadingKey) ?? 0,
      speed: prefs.getDouble(_lastLocationSpeedKey) ?? 0,
      speedAccuracy: prefs.getDouble(_lastLocationSpeedAccuracyKey) ?? 0,
      altitudeAccuracy:
          prefs.getDouble(_lastLocationAltitudeAccuracyKey) ?? 0,
      headingAccuracy:
          prefs.getDouble(_lastLocationHeadingAccuracyKey) ?? 0,
      floor: prefs.getInt(_lastLocationFloorKey),
      isMocked: prefs.getBool(_lastLocationIsMockedKey) ?? false,
    );

    _currentAddress = (address == null || address.trim().isEmpty)
        ? _formatCoordinates(lat, lon)
        : address;

    _calculatePrayers(scheduleNotifications: scheduleNotifications);
    return true;
  }

  Future<void> updateLocation() async {
    _isLoading = true;
    notifyListeners();

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition();

      _currentAddress = _formatCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      await _saveCachedLocation();
      _calculatePrayers();
      notifyListeners();

      await _getAddressFromLatLng();
      await _saveCachedLocation();
    } catch (e) {
      debugPrint("Error updating location: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      Placemark place = placemarks[0];
      final parts = [
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((part) => part != null && part.trim().isNotEmpty);
      final resolvedAddress = parts.join(', ');
      if (resolvedAddress.isNotEmpty) {
        _currentAddress = resolvedAddress;
      }
    } catch (e) {
      debugPrint("Error resolving location address: $e");
    }
  }

  Future<void> _saveCachedLocation() async {
    final position = _currentPosition;
    if (position == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lastLocationLatKey, position.latitude);
    await prefs.setDouble(_lastLocationLonKey, position.longitude);
    await prefs.setDouble(_lastLocationAccuracyKey, position.accuracy);
    await prefs.setDouble(_lastLocationAltitudeKey, position.altitude);
    await prefs.setDouble(_lastLocationHeadingKey, position.heading);
    await prefs.setDouble(_lastLocationSpeedKey, position.speed);
    await prefs.setDouble(
      _lastLocationSpeedAccuracyKey,
      position.speedAccuracy,
    );
    await prefs.setDouble(
      _lastLocationAltitudeAccuracyKey,
      position.altitudeAccuracy,
    );
    await prefs.setDouble(
      _lastLocationHeadingAccuracyKey,
      position.headingAccuracy,
    );
    await prefs.setInt(
      _lastLocationTimestampKey,
      position.timestamp.millisecondsSinceEpoch,
    );
    final floor = position.floor;
    if (floor == null) {
      await prefs.remove(_lastLocationFloorKey);
    } else {
      await prefs.setInt(_lastLocationFloorKey, floor);
    }
    await prefs.setBool(_lastLocationIsMockedKey, position.isMocked);
    await prefs.setString(_lastLocationAddressKey, _currentAddress);
    await _saveLocationRefreshTime();
  }

  String _formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  void _calculatePrayers({bool scheduleNotifications = true}) {
    if (_currentPosition == null) return;

    final myCoordinates =
        Coordinates(_currentPosition!.latitude, _currentPosition!.longitude);
    final params = CalculationMethodParameters.muslimWorldLeague();
    params.madhab = Madhab.shafi;

    _prayerTimes = PrayerTimes(
      coordinates: myCoordinates,
      date: DateTime.now(),
      calculationParameters: params,
      precision: true,
    );

    if (scheduleNotifications) {
      _schedulePrayerNotifications();
    }
  }

  @pragma('vm:entry-point')
  static void alarmCallback() async {
    final service = PrayerService();
    await service.init(requestPermissions: false);
  }

  void _startAdhanWatcher() {
    _adhanWatcher?.cancel();
    _adhanWatcher = Timer.periodic(const Duration(seconds: 1), (_) {
      _showDuePrayerNotification();
    });
    _showDuePrayerNotification();
  }

  Future<void> _showDuePrayerNotification() async {
    if (_prayerTimes == null) return;

    final now = DateTime.now();
    final duePrayer = _latestDuePrayer(now);
    if (duePrayer == null) return;

    final key = _notificationKeyFor(duePrayer);
    if (_lastShownAdhanKey == key) return;

    final secondsSincePrayer = now.difference(duePrayer.time).inSeconds;
    if (secondsSincePrayer < 0 || secondsSincePrayer > 300) return;

    _lastShownAdhanKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAdhanNotificationKey, key);

    if (_isAndroid) return;

    await _notifications.cancel(duePrayer.id);

    await _notifications.show(
      duePrayer.id,
      'Prayer Time',
      'It is time for ${duePrayer.name}',
      _prayerNotificationDetails(playNotificationSound: false, ongoing: true),
      payload: stopAdhanPayload,
    );
    await _playAdhan(duePrayer.id);
  }

  Future<void> _playAdhan(int notificationId) async {
    await _adhanPlayerStateSubscription?.cancel();
    await _adhanPlayer.stop();
    await _adhanPlayer.setAsset('assets/azan/azan1.mp3');

    _adhanPlayerStateSubscription =
        _adhanPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        unawaited(stopAdhan(notificationId: notificationId));
      }
    });

    await _adhanPlayer.play();
  }

  Future<void> stopAdhan({int? notificationId}) async {
    if (_isAndroid) {
      await _adhanAlarmChannel.invokeMethod<void>('stopAdhan');
      return;
    }

    await _adhanPlayer.stop();
    await _adhanPlayerStateSubscription?.cancel();
    _adhanPlayerStateSubscription = null;
    if (notificationId != null) {
      await _notifications.cancel(notificationId);
    } else {
      await _notifications.cancelAll();
      await _schedulePrayerNotifications();
    }
  }

  _DuePrayer? _latestDuePrayer(DateTime now) {
    final prayers = _prayersForCurrentDay();
    _DuePrayer? latest;

    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) continue;
      if (latest == null || prayer.time.isAfter(latest.time)) {
        latest = prayer;
      }
    }

    return latest;
  }

  List<_DuePrayer> _prayersForCurrentDay() {
    return [
      _DuePrayer(id: 0, name: 'Fajr', time: _prayerTimes!.fajr.toLocal()),
      _DuePrayer(id: 1, name: 'Dhuhr', time: _prayerTimes!.dhuhr.toLocal()),
      _DuePrayer(id: 2, name: 'Asr', time: _prayerTimes!.asr.toLocal()),
      _DuePrayer(id: 3, name: 'Maghrib', time: _prayerTimes!.maghrib.toLocal()),
      _DuePrayer(id: 4, name: 'Isha', time: _prayerTimes!.isha.toLocal()),
    ];
  }

  List<_DuePrayer> _prayersFor(DateTime date) {
    final position = _currentPosition;
    if (position == null) return const [];

    final prayerTimes = _calculatePrayerTimesFor(date);
    return [
      _DuePrayer(id: 0, name: 'Fajr', time: prayerTimes.fajr.toLocal()),
      _DuePrayer(id: 1, name: 'Dhuhr', time: prayerTimes.dhuhr.toLocal()),
      _DuePrayer(id: 2, name: 'Asr', time: prayerTimes.asr.toLocal()),
      _DuePrayer(id: 3, name: 'Maghrib', time: prayerTimes.maghrib.toLocal()),
      _DuePrayer(id: 4, name: 'Isha', time: prayerTimes.isha.toLocal()),
    ];
  }

  PrayerTimes _calculatePrayerTimesFor(DateTime date) {
    final myCoordinates =
        Coordinates(_currentPosition!.latitude, _currentPosition!.longitude);
    final params = CalculationMethodParameters.muslimWorldLeague();
    params.madhab = Madhab.shafi;

    return PrayerTimes(
      coordinates: myCoordinates,
      date: date,
      calculationParameters: params,
      precision: true,
    );
  }

  _DuePrayer? _nextDuePrayer() {
    final now = DateTime.now();
    final prayers = [
      ..._prayersFor(now),
      ..._prayersFor(now.add(const Duration(days: 1))),
    ];

    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) return prayer;
    }

    return null;
  }

  String _notificationKeyFor(_DuePrayer prayer) {
    final local = prayer.time.toLocal();
    return '${prayer.name}-${local.year}-${local.month}-${local.day}-${local.hour}-${local.minute}';
  }

  NotificationDetails _prayerNotificationDetails({
    required bool playNotificationSound,
    bool ongoing = false,
  }) {
    final android = AndroidNotificationDetails(
      playNotificationSound ? _prayerNotificationChannelId : _activeAdhanChannelId,
      playNotificationSound ? 'Prayer Times Adhan' : 'Active Adhan',
      channelDescription: 'Notifications for prayer times with Adhan sound',
      importance: Importance.max,
      priority: Priority.high,
      sound: playNotificationSound
          ? const RawResourceAndroidNotificationSound('azan1')
          : null,
      playSound: playNotificationSound,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ongoing: ongoing,
      autoCancel: !ongoing,
      actions: const [
        AndroidNotificationAction(
          stopAdhanActionId,
          'Stop',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final ios = DarwinNotificationDetails(
      sound: playNotificationSound ? 'azan1.mp3' : null,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  Future<void> _schedulePrayerNotifications() async {
    if (_prayerTimes == null || !_notificationsReady) return;

    // Clear existing notifications
    await _notifications.cancelAll();

    final prayers = _prayersForCurrentDay();

    try {
      if (_isAndroid) {
        await _scheduleNativeAdhanAlarms();
      } else {
        for (final prayer in prayers) {
          if (!prayer.time.isAfter(DateTime.now())) continue;

          await _notifications.zonedSchedule(
            prayer.id,
            'Prayer Time',
            'It is time for ${prayer.name}',
            tz.TZDateTime.from(prayer.time, tz.local),
            _prayerNotificationDetails(playNotificationSound: true),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: stopAdhanPayload,
          );
        }
      }
    } catch (e) {
      debugPrint('Prayer notification scheduling failed: $e');
    }

    // Schedule Dua Reminders (Morning/Evening)
    await _scheduleDuaReminders(requestNotificationPermission: false);

    // Schedule a background task to refresh prayers for tomorrow
    // This alarm will fire at 1 AM tomorrow
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 1, 0);

    await AndroidAlarmManager.oneShotAt(
      tomorrow,
      999,
      alarmCallback,
      exact: true,
      wakeup: true,
    );
  }

  Future<void> _scheduleNativeAdhanAlarms() async {
    final now = DateTime.now();
    final alarms = <Map<String, Object>>[];

    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      for (final prayer in _prayersFor(date)) {
        if (!prayer.time.isAfter(now)) continue;

        alarms.add({
          'id': prayer.id + (dayOffset * 10),
          'name': prayer.name,
          'timeMillis': prayer.time.millisecondsSinceEpoch,
        });
      }
    }

    await _adhanAlarmChannel.invokeMethod<void>('scheduleAdhanAlarms', alarms);
  }

  Future<void> refreshDuaReminders({
    bool requestNotificationPermission = false,
  }) async {
    if (!_notificationsReady) return;
    await _scheduleDuaReminders(
      requestNotificationPermission: requestNotificationPermission,
    );
  }

  Future<void> _scheduleDuaReminders({
    bool requestNotificationPermission = true,
  }) async {
    if (!_notificationsReady) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('pref_daily_reminders_enabled') ?? true;

    // Clear existing reminders first (up to 30 to clean up old ones)
    for (var dayOffset = 0; dayOffset < 30; dayOffset++) {
      await _notifications.cancel(100 + dayOffset);
      await _notifications.cancel(200 + dayOffset);
      await _notifications.cancel(_fastingReminderBaseId + dayOffset);
    }

    if (!enabled) return;

    final notificationsAllowed = await _notificationsAllowed(
      requestIfNeeded: requestNotificationPermission,
    );
    if (!notificationsAllowed) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDays = _isAndroid
        ? _androidDuaReminderScheduleDays
        : _defaultDuaReminderScheduleDays;

    for (var dayOffset = 0; dayOffset < scheduleDays; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final dayPrayers = _prayersFor(date);

      DateTime morningTime;
      DateTime eveningTime;

      if (dayPrayers.isNotEmpty) {
        // Morning Azkar: 20 minutes after Fajr
        final fajr = dayPrayers.firstWhere((p) => p.id == 0).time;
        morningTime = fajr.add(const Duration(minutes: 20));

        // Evening Azkar: 1 hour 30 minutes after Asr
        final asr = dayPrayers.firstWhere((p) => p.id == 2).time;
        eveningTime = asr.add(const Duration(hours: 1, minutes: 30));
      } else {
        // Fallback to fixed times if location is not available
        morningTime = DateTime(date.year, date.month, date.day, 7, 0);
        eveningTime = DateTime(date.year, date.month, date.day, 18, 0);
      }

      await _scheduleReminderIfFuture(
        id: 100 + dayOffset,
        title: 'Morning Azkar',
        body: 'Start your day with morning adhkar.',
        scheduledTime: morningTime,
      );

      await _scheduleReminderIfFuture(
        id: 200 + dayOffset,
        title: 'Evening Azkar',
        body: 'Remember your evening adhkar.',
        scheduledTime: eveningTime,
      );

      final fastingReason = _fastingReminderReason(date);
      if (fastingReason == null) continue;

      final reminderDate = date.subtract(const Duration(days: 1));
      await _scheduleReminderIfFuture(
        id: _fastingReminderBaseId + dayOffset,
        title: 'Fasting Reminder',
        body: 'Prepare for $fastingReason tomorrow.',
        scheduledTime: DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          20,
        ),
      );
    }

    await _logPendingReminderCount();
  }

  Future<void> _logPendingReminderCount() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      final reminderCount = pending.where((notification) {
        final id = notification.id;
        return (id >= 100 && id < 100 + _androidDuaReminderScheduleDays) ||
            (id >= 200 && id < 200 + _androidDuaReminderScheduleDays) ||
            (id >= _fastingReminderBaseId &&
                id < _fastingReminderBaseId + _androidDuaReminderScheduleDays);
      }).length;
      debugPrint('Scheduled azkar/fasting reminders: $reminderCount');
    } catch (e) {
      debugPrint('Unable to inspect scheduled reminders: $e');
    }
  }

  Future<void> _scheduleReminderIfFuture({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final now = DateTime.now();
    if (!scheduledTime.isAfter(now)) return;

    try {
      final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);
      debugPrint('Scheduling reminder "$title" (id: $id) for $scheduledTz (Local: $scheduledTime)');

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        _reminderNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Unable to schedule reminder "$title" at $scheduledTime: $e');
    }
  }

  String? _fastingReminderReason(DateTime date) {
    final reasons = <String>[];
    final hijriDate = HijriCalendar.fromDate(date);
    final blocksVoluntaryFast =
        (hijriDate.hMonth == 10 && hijriDate.hDay == 1) ||
        (hijriDate.hMonth == 12 &&
            hijriDate.hDay >= 10 &&
            hijriDate.hDay <= 13);

    if (!blocksVoluntaryFast &&
        (date.weekday == DateTime.monday ||
            date.weekday == DateTime.thursday)) {
      reasons.add('the Sunnah Monday/Thursday fast');
    }

    if (!blocksVoluntaryFast &&
        hijriDate.hDay >= 13 &&
        hijriDate.hDay <= 15) {
      reasons.add('the white days fast');
    }

    if (hijriDate.hMonth == 1 && hijriDate.hDay == 9) {
      reasons.add('Tasu\'a');
    }

    if (hijriDate.hMonth == 1 && hijriDate.hDay == 10) {
      reasons.add('Ashura');
    }

    if (hijriDate.hMonth == 12 && hijriDate.hDay == 9) {
      reasons.add('the Day of Arafah fast');
    }

    if (reasons.isEmpty) return null;
    return reasons.join(' and ');
  }

  NotificationDetails _reminderNotificationDetails() {
    const android = AndroidNotificationDetails(
      'dua_reminders_channel_v4',
      'Dua Reminders',
      channelDescription: 'Reminders for morning and evening azkar',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  String getNextPrayerName() {
    if (_prayerTimes == null) return "---";
    return _nextDuePrayer()?.name.toUpperCase() ?? "---";
  }

  DateTime? getNextPrayerTime() {
    if (_prayerTimes == null) return null;
    return _nextDuePrayer()?.time;
  }

  Duration? getTimeToNextPrayer() {
    final nextTime = getNextPrayerTime();
    if (nextTime == null) return null;
    return nextTime.difference(DateTime.now());
  }

  @override
  void dispose() {
    _adhanWatcher?.cancel();
    _adhanPlayerStateSubscription?.cancel();
    _adhanPlayer.dispose();
    super.dispose();
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

class _DuePrayer {
  const _DuePrayer({
    required this.id,
    required this.name,
    required this.time,
  });

  final int id;
  final String name;
  final DateTime time;
}
