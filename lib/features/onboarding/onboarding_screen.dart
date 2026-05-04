import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/settings_service.dart';
import '../../shared/theme/app_theme.dart';
import '../home/home_screen.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.access_time_rounded,
      title: 'Prayer Times',
      body:
          'Get accurate prayer times based on your location. Never miss a prayer with smart notifications and Adhan reminders.',
    ),
    _OnboardingPage(
      icon: Icons.calendar_today_rounded,
      title: 'Hijri Calendar',
      body:
          'View the Islamic Hijri calendar alongside the Gregorian calendar. Keep track of important Islamic dates and events.',
    ),
    _OnboardingPage(
      icon: Icons.mosque_rounded,
      title: 'Daily Duas & Adhkar',
      body:
          'Access hundreds of authentic duas from Deen Azkar with Arabic text, transliteration, and translation. Bookmark your favorites.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final settings = context.read<SettingsService>();
    final prayerService = context.read<PrayerService>();

    await prayerService.completeInitialPrayerSetup();
    await settings.setOnboardingDone(true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, index) =>
                    _OnboardingPageWidget(page: _pages[index]),
              ),
            ),
            _buildIndicators(),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          width: i == _currentPage ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == _currentPage
                ? AppTheme.primaryRed
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildButtons() {
    final isLast = _currentPage == _pages.length - 1;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isLast)
            TextButton(
              onPressed: _isFinishing ? null : _finish,
              child: const Text('Skip',
                  style: TextStyle(color: AppTheme.subTextColor)),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: _isFinishing ? null : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: _isFinishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 60, color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.subTextColor,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
