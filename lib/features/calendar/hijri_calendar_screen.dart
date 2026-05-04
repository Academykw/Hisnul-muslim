import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_theme.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late HijriCalendar _selectedDate;
  late DateTime _selectedGregorian;

  @override
  void initState() {
    super.initState();
    _selectedDate = HijriCalendar.now();
    _selectedGregorian = DateTime.now();
  }

  void _onMonthChanged(int delta) {
    setState(() {
      int newMonth = _selectedDate.hMonth + delta;
      int newYear = _selectedDate.hYear;
      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      }
      _selectedDate = HijriCalendar.fromDate(
          DateTime(DateTime.now().year, DateTime.now().month, 1)); // Dummy
      // Better logic for month navigation in hijri package is needed
      // but for now we show current month
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = HijriCalendar.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hijri Calendar'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildCalendarGrid(),
          ),
          _buildTodayButton(today),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.primaryRed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => _onMonthChanged(-1),
          ),
          Column(
            children: [
              Text(
                _selectedDate.longMonthName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_selectedDate.hYear} AH',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => _onMonthChanged(1),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDayLabels(),
          const SizedBox(height: 12),
          // Simplified grid for demo
          const Expanded(
            child: Center(
              child: Text(
                'Islamic Calendar View\nComing Soon with full data',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabels() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => Text(d,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.primaryRed)))
          .toList(),
    );
  }

  Widget _buildTodayButton(HijriCalendar today) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedDate = HijriCalendar.now()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text('Today: ${today.hDay} ${today.longMonthName} ${today.hYear}'),
      ),
    );
  }
}
