import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../core/services/prayer_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/banner_ad_widget.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with WidgetsBindingObserver {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = DateTime.now().toLocal();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _syncClock();
    });

    // Refresh location on load if not available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<PrayerService>();
      unawaited(_refreshDeviceClockSettings(service));
      if (service.currentPosition == null) {
        unawaited(service.updateLocation());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _syncClock();
    unawaited(_refreshDeviceClockSettings(context.read<PrayerService>()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  void _syncClock() {
    if (!mounted) return;
    setState(() {
      _now = DateTime.now().toLocal();
    });
  }

  Future<void> _refreshDeviceClockSettings(PrayerService service) async {
    await service.refreshDeviceTimeSettings();
    _syncClock();
  }

  @override
  Widget build(BuildContext context) {
    final prayerService = context.watch<PrayerService>();
    final prayers = prayerService.prayerTimes;
    final nextPrayerName = prayerService.getNextPrayerName();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryRed,
              Color(0xFF9E1B1B), // Darker red
              Color(0xFF1A1A1A), // Near black
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              // Banner Ad at Top
              const SafeTopBannerAd(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildHeaderCard(prayerService),
                      const SizedBox(height: 24),
                      if (prayers != null)
                        _buildPrayerList(prayers, nextPrayerName)
                      else
                        _buildNoLocationCard(prayerService),
                      const SizedBox(height: 24),
                      _buildUpdateLocationButton(prayerService),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon:
                const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Prayer Times',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(PrayerService service) {
    final nextPrayerName = service.getNextPrayerName();
    final timeToNext = service.getTimeToNextPrayer();
    final hijriDate = HijriCalendar.now();
    final timeFormat =
        MediaQuery.alwaysUse24HourFormatOf(context) ? 'HH:mm:ss' : 'h:mm:ss a';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                service.currentAddress,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat(timeFormat).format(_now),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Text(
            '${hijriDate.toVisualDate()} • ${DateFormat('EEE, d MMM').format(_now)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              timeToNext != null
                  ? '$nextPrayerName IN ${_formatDuration(timeToNext)}'
                  : 'CALCULATING...',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerList(PrayerTimes prayers, String nextPrayerName) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.28 : 0.1,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _PrayerRow(
            name: 'Fajr',
            time: prayers.fajr,
            isNext: nextPrayerName == 'FAJR',
          ),
          _PrayerRow(
            name: 'Sunrise',
            time: prayers.sunrise,
            isNext: false,
            isSunrise: true,
          ),
          _PrayerRow(
            name: 'Dhuhr',
            time: prayers.dhuhr,
            isNext: nextPrayerName == 'DHUHR',
          ),
          _PrayerRow(
            name: 'Asr',
            time: prayers.asr,
            isNext: nextPrayerName == 'ASR',
          ),
          _PrayerRow(
            name: 'Maghrib',
            time: prayers.maghrib,
            isNext: nextPrayerName == 'MAGHRIB',
          ),
          _PrayerRow(
            name: 'Isha',
            time: prayers.isha,
            isNext: nextPrayerName == 'ISHA',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateLocationButton(PrayerService service) {
    return ElevatedButton.icon(
      onPressed: service.isLoading ? null : () => service.updateLocation(),
      icon: service.isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.my_location_rounded),
      label: Text(service.isLoading ? 'Updating...' : 'Update Location'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
    );
  }

  Widget _buildNoLocationCard(PrayerService service) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Location Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please update your location to see prayer times for your city.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => service.updateLocation(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Fetch Location'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    } else if (d.inMinutes > 0) {
      return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
    } else {
      return "${d.inSeconds}s";
    }
  }
}

class _PrayerRow extends StatelessWidget {
  final String name;
  final DateTime time;
  final bool isNext;
  final bool isLast;
  final bool isSunrise;

  const _PrayerRow({
    required this.name,
    required this.time,
    required this.isNext,
    this.isLast = false,
    this.isSunrise = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat =
        MediaQuery.alwaysUse24HourFormatOf(context) ? 'HH:mm' : 'h:mm a';
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: isNext ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.45)),
          left: isNext
              ? BorderSide(color: activeColor, width: 4)
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(),
                color: isNext ? activeColor : mutedColor,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                  color: isNext ? activeColor : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Text(
            DateFormat(timeFormat).format(time.toLocal()),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
              color: isNext ? activeColor : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (name) {
      case 'Fajr': return Icons.wb_twilight_rounded;
      case 'Sunrise': return Icons.wb_sunny_outlined;
      case 'Dhuhr': return Icons.wb_sunny_rounded;
      case 'Asr': return Icons.wb_cloudy_rounded;
      case 'Maghrib': return Icons.wb_twilight_rounded;
      case 'Isha': return Icons.nightlight_round;
      default: return Icons.access_time_rounded;
    }
  }
}

extension on HijriCalendar {
  String toVisualDate() {
    return '$hDay $longMonthName $hYear';
  }
}
