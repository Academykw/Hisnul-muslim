import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/banner_ad_widget.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late HijriCalendar _viewDate;

  @override
  void initState() {
    super.initState();
    _viewDate = HijriCalendar.now();
    _viewDate.hDay = 1;
  }

  void _onMonthChanged(int delta) {
    setState(() {
      int newMonth = _viewDate.hMonth + delta;
      int newYear = _viewDate.hYear;

      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      }

      final nextView = HijriCalendar();
      nextView.hYear = newYear;
      nextView.hMonth = newMonth;
      nextView.hDay = 1;
      _viewDate = nextView;
    });
  }

  String get _viewMonthName => _viewDate.getLongMonthName();

  List<_IslamicCalendarEvent> _eventsForDay({
    required int hijriMonth,
    required int hijriDay,
    required DateTime? gregDate,
  }) {
    final events = <_IslamicCalendarEvent>[];

    for (final event in _fixedIslamicEvents) {
      if (event.hijriMonth == hijriMonth && event.hijriDay == hijriDay) {
        events.add(event);
      }
    }

    if (hijriDay >= 13 && hijriDay <= 15) {
      events.add(
        const _IslamicCalendarEvent(
          title: 'White Days',
          note: 'Recommended fast',
          type: _IslamicEventType.fast,
        ),
      );
    }

    if (gregDate != null &&
        (gregDate.weekday == DateTime.monday ||
            gregDate.weekday == DateTime.thursday)) {
      events.add(
        const _IslamicCalendarEvent(
          title: 'Sunnah Fast',
          note: 'Monday/Thursday',
          type: _IslamicEventType.fast,
        ),
      );
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = HijriCalendar.now();

    // Calculate Gregorian range for the current Hijri month
    String gregRange = '';
    try {
      final daysInMonth = _viewDate.getDaysInMonth(_viewDate.hYear, _viewDate.hMonth);
      final firstDayG = _viewDate.hijriToGregorian(_viewDate.hYear, _viewDate.hMonth, 1);
      final lastDayG = _viewDate.hijriToGregorian(_viewDate.hYear, _viewDate.hMonth, daysInMonth);

      if (firstDayG.month == lastDayG.month) {
        gregRange = '${DateFormat('MMMM').format(firstDayG)} ${firstDayG.year}';
      } else if (firstDayG.year == lastDayG.year) {
        gregRange = '${DateFormat('MMM').format(firstDayG)} - ${DateFormat('MMM').format(lastDayG)} ${firstDayG.year}';
      } else {
        gregRange = '${DateFormat('MMM yyyy').format(firstDayG)} - ${DateFormat('MMM yyyy').format(lastDayG)}';
      }
    } catch (e) {
      debugPrint('Error converting Hijri to Gregorian: $e');
      gregRange = '${_viewDate.hMonth}/${_viewDate.hYear} AH';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hijri Calendar'),
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SafeTopBannerAd(),
          _buildHeader(isDark, theme, gregRange),
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: _buildCalendarGrid(isDark, theme, today),
            ),
          ),
          _buildInfoPanel(isDark, theme, today),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, ThemeData theme, String gregRange) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? theme.appBarTheme.backgroundColor : AppTheme.primaryRed,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
            onPressed: () => _onMonthChanged(-1),
          ),
          Column(
            children: [
              Text(
                _viewMonthName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${_viewDate.hYear} AH',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                gregRange,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
            onPressed: () => _onMonthChanged(1),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark, ThemeData theme, HijriCalendar today) {
    int daysInMonth = 0;
    int leadingEmptyDays = 0;

    try {
      daysInMonth = _viewDate.getDaysInMonth(_viewDate.hYear, _viewDate.hMonth);

      // Find Gregorian weekday for the 1st of this Hijri month
      final firstDayOfMonthGreg = _viewDate.hijriToGregorian(_viewDate.hYear, _viewDate.hMonth, 1);
      final startWeekday = firstDayOfMonthGreg.weekday;

      // Sunday is index 0 in our grid. ISO weekday: 1 (Mon) to 7 (Sun)
      leadingEmptyDays = startWeekday == 7 ? 0 : startWeekday;
    } catch (e) {
      debugPrint('Error building calendar grid: $e');
      // Fallback: assume 30 days and 0 leading empty days
      daysInMonth = 30;
      leadingEmptyDays = 0;
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildDayLabels(theme),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.85,
              ),
              itemCount: leadingEmptyDays + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingEmptyDays) return const SizedBox.shrink();

                final dayNum = index - leadingEmptyDays + 1;
                final isToday = today.hYear == _viewDate.hYear &&
                                today.hMonth == _viewDate.hMonth &&
                                today.hDay == dayNum;

                int gregDay = dayNum;
                bool isWeekend = false;
                DateTime? gregDate;

                try {
                  gregDate = _viewDate.hijriToGregorian(_viewDate.hYear, _viewDate.hMonth, dayNum);
                  gregDay = gregDate.day;
                  isWeekend = gregDate.weekday == DateTime.friday || gregDate.weekday == DateTime.saturday;
                } catch (e) {
                  debugPrint('Error converting day $dayNum: $e');
                  // Use fallback values (already set above)
                }

                return _CalendarDayTile(
                  hijriDay: dayNum,
                  gregDay: gregDay,
                  isToday: isToday,
                  isWeekend: isWeekend,
                  events: _eventsForDay(
                    hijriMonth: _viewDate.hMonth,
                    hijriDay: dayNum,
                    gregDate: gregDate,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabels(ThemeData theme) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: d == 'Fri' ? AppTheme.primaryRed : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildInfoPanel(bool isDark, ThemeData theme, HijriCalendar today) {
    final gregToday = DateTime.now();
    final formattedGreg = DateFormat('EEEE, d MMMM yyyy').format(gregToday);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? theme.colorScheme.surface : Colors.white),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.today_rounded, color: AppTheme.primaryRed, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${today.hDay} ${today.longMonthName} ${today.hYear} AH',
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    formattedGreg,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _viewDate = HijriCalendar.now();
                _viewDate.hDay = 1;
              }),
              child: const Text('RESET', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  final int hijriDay;
  final int gregDay;
  final bool isToday;
  final bool isWeekend;
  final List<_IslamicCalendarEvent> events;

  const _CalendarDayTile({
    required this.hijriDay,
    required this.gregDay,
    required this.isToday,
    required this.isWeekend,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isToday
        ? AppTheme.primaryRed
        : (events.any((event) => event.type == _IslamicEventType.eid)
            ? AppTheme.primaryRed.withValues(alpha: isDark ? 0.25 : 0.1)
            : events.isNotEmpty
                ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.08)
                : (isWeekend
            ? AppTheme.primaryRed.withValues(alpha: isDark ? 0.15 : 0.05)
                    : (theme.cardTheme.color ?? (isDark ? Colors.white10 : Colors.white))));

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: isToday ? null : Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: isToday ? [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$hijriDay',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$gregDay',
            style: TextStyle(
              fontSize: 10,
              color: isToday
                  ? Colors.white.withValues(alpha: 0.8)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 3),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: events
                  .take(3)
                  .map(
                    (event) => Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isToday ? Colors.white : event.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

enum _IslamicEventType { event, eid, fast }

class _IslamicCalendarEvent {
  const _IslamicCalendarEvent({
    required this.title,
    required this.note,
    required this.type,
    this.hijriMonth,
    this.hijriDay,
  });

  final String title;
  final String note;
  final _IslamicEventType type;
  final int? hijriMonth;
  final int? hijriDay;

  Color get color {
    switch (type) {
      case _IslamicEventType.eid:
        return AppTheme.primaryRed;
      case _IslamicEventType.fast:
        return const Color(0xFF2E7D32);
      case _IslamicEventType.event:
        return const Color(0xFF1565C0);
    }
  }
}

const List<_IslamicCalendarEvent> _fixedIslamicEvents = [
  _IslamicCalendarEvent(
    hijriMonth: 1,
    hijriDay: 1,
    title: 'Islamic New Year',
    note: '1 Muharram',
    type: _IslamicEventType.event,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 1,
    hijriDay: 9,
    title: 'Tasu'a',
    note: 'Recommended fast',
    type: _IslamicEventType.fast,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 1,
    hijriDay: 10,
    title: 'Ashura',
    note: 'Recommended fast',
    type: _IslamicEventType.fast,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 3,
    hijriDay: 12,
    title: 'Mawlid',
    note: '12 Rabi al-awwal',
    type: _IslamicEventType.event,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 7,
    hijriDay: 27,
    title: 'Isra and Mi\'raj',
    note: 'Common observance',
    type: _IslamicEventType.event,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 8,
    hijriDay: 15,
    title: 'Mid-Sha\'ban',
    note: 'Common observance',
    type: _IslamicEventType.event,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 9,
    hijriDay: 1,
    title: 'Ramadan begins',
    note: 'Obligatory fasting month',
    type: _IslamicEventType.event,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 9,
    hijriDay: 27,
    title: 'Laylat al-Qadr',
    note: 'Likely night among last ten odd nights',
    type: _IslamicEventType.event,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 10,
    hijriDay: 1,
    title: 'Eid al-Fitr',
    note: '1 Shawwal',
    type: _IslamicEventType.eid,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 12,
    hijriDay: 8,
    title: 'Hajj begins',
    note: '8 Dhu al-Hijjah',
    type: _IslamicEventType.event,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 12,
    hijriDay: 9,
    title: 'Day of Arafah',
    note: 'Recommended fast for non-pilgrims',
    type: _IslamicEventType.fast,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 12,
    hijriDay: 10,
    title: 'Eid al-Adha',
    note: '10 Dhu al-Hijjah',
    type: _IslamicEventType.eid,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 12,
    hijriDay: 11,
    title: 'Days of Tashreeq',
    note: '11-13 Dhu al-Hijjah',
    type: _IslamicEventType.event,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 12,
    hijriDay: 12,
    title: 'Days of Tashreeq',
    note: '11-13 Dhu al-Hijjah',
    type: _IslamicEventType.event,
  ),
  _IslamicCalendarEvent(
    hijriMonth: 12,
    hijriDay: 13,
    title: 'Days of Tashreeq',
    note: '11-13 Dhu al-Hijjah',
    type: _IslamicEventType.event,
  ),
];
