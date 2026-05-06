import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

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
      MethodChannel('com.deen.adkhar/adhan_alarm');
  static const String _lastLocationLatKey = 'last_lat';
  static const String _lastLocationLonKey = 'last_lon';
  static const String _lastLocationAddressKey = 'last_address';
  static const String _lastLocationRefreshKey = 'last_location_refresh_time';

  Position? _currentPosition;
  String _currentAddress = "Loading location...";
  PrayerTimes? _prayerTimes;
  bool _isLoading = false;
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

  Future<void> init() async {
    tz.initializeTimeZones();
    await _refreshLocalTimezone();

    await _initNotifications();
    await AndroidAlarmManager.initialize();
    await _loadLastShownAdhanKey();
    await _loadSavedLocation();
    _startAdhanWatcher();
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
    final timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> requestPermissions() async {
    await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Also request exact alarm permission for Android 12+
    await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await _requestBatteryOptimizationExemption();
  }

  bool _shouldAutoRefreshLocation() {
    // Check if location should be auto-refreshed (once per 24 hours)
    // Return false if it was refreshed less than 24 hours ago
    return true; // Will be checked in init method
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
          'dua_reminders_channel',
          'Dua Reminders',
          description: 'Reminders for morning and evening azkar',
          importance: Importance.high,
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

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_lastLocationLatKey);
    final lon = prefs.getDouble(_lastLocationLonKey);
    final address = prefs.getString(_lastLocationAddressKey);

    if (lat != null && lon != null) {
      _currentPosition = Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      // Restore saved address
      if (address != null) {
        _currentAddress = address;
      }

      _calculatePrayers();
    }
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

      // Save location and address
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_lastLocationLatKey, _currentPosition!.latitude);
      await prefs.setDouble(_lastLocationLonKey, _currentPosition!.longitude);

      await _getAddressFromLatLng();

      // Save address for persistence
      await prefs.setString(_lastLocationAddressKey, _currentAddress);

      // Save refresh timestamp for auto-refresh control
      await _saveLocationRefreshTime();

      _calculatePrayers();
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
      _currentAddress = "${place.locality}, ${place.country}";
    } catch (e) {
      _currentAddress = "Unknown Location";
    }
  }

  void _calculatePrayers() {
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

    _schedulePrayerNotifications();
  }

  @pragma('vm:entry-point')
  static void alarmCallback() async {
    final service = PrayerService();
    await service.init();
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
    if (_prayerTimes == null) return;

    // Clear existing notifications
    await _notifications.cancelAll();

    final prayers = _prayersForCurrentDay();

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

    // Schedule Dua Reminders (Morning/Evening)
    await _scheduleDuaReminders();

    // Schedule a background task to refresh prayers for tomorrow
    // This alarm will fire at 1 AM tomorrow
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 1, 0);

    await AndroidAlarmManager.oneShotAt(
      tomorrow,
      1,
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

  Future<void> _scheduleDuaReminders() async {
    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final prayers = _prayersFor(date);
      if (prayers.length < 5) continue;

      // Fajr ID: 0, Asr ID: 2
      final fajr = prayers.firstWhere((p) => p.id == 0).time;
      final asr = prayers.firstWhere((p) => p.id == 2).time;

      final morningDuaTime = fajr.add(const Duration(minutes: 20));
      final eveningDuaTime = asr.add(const Duration(hours: 1, minutes: 30));

      final details = _reminderNotificationDetails();

      if (morningDuaTime.isAfter(now)) {
        await _notifications.zonedSchedule(
          100 + dayOffset,
          'Morning Azkar',
          'It is time for your morning dhikr.',
          tz.TZDateTime.from(morningDuaTime, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      if (eveningDuaTime.isAfter(now)) {
        await _notifications.zonedSchedule(
          200 + dayOffset,
          'Evening Azkar',
          'It is time for your evening dhikr.',
          tz.TZDateTime.from(eveningDuaTime, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  NotificationDetails _reminderNotificationDetails() {
    const android = AndroidNotificationDetails(
      'dua_reminders_channel',
      'Dua Reminders',
      channelDescription: 'Reminders for morning and evening azkar',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
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
