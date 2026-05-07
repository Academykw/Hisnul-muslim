import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/share_service.dart';
import '../../core/services/settings_service.dart';
import '../about/about_screen.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/banner_ad_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          // Banner Ad at Top
          const SafeTopBannerAd(),
          Expanded(
            child: ListView(
              children: [
                // Theme Section
                _SectionHeader(label: 'Display'),
          ListTile(
            leading: Icon(
              Icons.dark_mode_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(settings.theme)),
            onTap: () => _pickTheme(context, settings),
          ),
          SwitchListTile(
            secondary: Icon(
              Icons.notifications_active_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Daily reminders'),
            subtitle: const Text('Azkar and fasting reminders'),
            value: settings.dailyRemindersEnabled,
            onChanged: (value) async {
              await settings.setDailyRemindersEnabled(value);
              if (context.mounted) {
                await context.read<PrayerService>().refreshDuaReminders();
              }
            },
          ),

          const Divider(),
          _SectionHeader(label: 'Font Settings'),

          ListTile(
            leading: Icon(
              Icons.font_download_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Arabic Typeface'),
            subtitle: Text(settings.arabicFont),
            onTap: () => _pickArabicFont(context, settings),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(child: Text('Arabic Font Size')),
                  Text('${settings.arabicFontSize.toInt()}pt'),
                ]),
                Slider(
                  value: settings.arabicFontSize,
                  min: 16,
                  max: 48,
                  divisions: 16,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (v) => settings.setArabicFontSize(v),
                ),
                // Preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                      style: AppTheme.getArabicStyle(
                        fontFamily: settings.arabicFont,
                        fontSize: settings.arabicFontSize,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  const Expanded(child: Text('Translation Font')),
                  Text('${settings.otherFontSize.toInt()}pt'),
                ]),
                Slider(
                  value: settings.otherFontSize,
                  min: 10,
                  max: 22,
                  divisions: 6,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (v) => settings.setOtherFontSize(v),
                ),
                Text(
                  'In the name of Allah, the Most Gracious, the Most Merciful.',
                  style: TextStyle(fontSize: settings.otherFontSize),
                ),
                const SizedBox(height: 24),
                const Divider(),
                _SectionHeader(label: 'Support'),
                ListTile(
                  leading: Icon(
                    Icons.share_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Share App'),
                  subtitle: const Text('Recommend this app to others'),
                  onTap: () => ShareService.shareApp(context),
                ),
                ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('About'),
                  subtitle: const Text('App information and features'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
                const SizedBox(height: 32),
                ],
              ),
            ),]
          ),
         ),
        ],
      ),
    );
  }

  String _themeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System default';
    }
  }

  Future<void> _pickTheme(
    BuildContext context,
    SettingsService settings,
  ) async {
    final selectedTheme = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          _ThemeOption(
            label: 'System default',
            value: 'system',
            current: settings.theme,
          ),
          _ThemeOption(
            label: 'Light',
            value: 'light',
            current: settings.theme,
          ),
          _ThemeOption(
            label: 'Dark',
            value: 'dark',
            current: settings.theme,
          ),
        ],
      ),
    );

    if (selectedTheme != null) {
      await settings.setTheme(selectedTheme);
    }
  }

  Future<void> _pickArabicFont(
    BuildContext context,
    SettingsService settings,
  ) async {
    final selectedFont = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose Arabic Font'),
        children: [
          _FontOption(
            label: 'Uthmanic (Classic)',
            value: 'Uthmanic',
            current: settings.arabicFont,
          ),
          _FontOption(
            label: 'Amiri (Traditional)',
            value: 'Amiri',
            current: settings.arabicFont,
          ),
          _FontOption(
            label: 'Lateef (Sharp)',
            value: 'Lateef',
            current: settings.arabicFont,
          ),
          _FontOption(
            label: 'Droid Naskh (Simple)',
            value: 'DroidNaskh',
            current: settings.arabicFont,
          ),
        ],
      ),
    );

    if (selectedFont != null) {
      await settings.setArabicFont(selectedFont);
    }
  }
}

class _FontOption extends StatelessWidget {
  final String label;
  final String value;
  final String current;

  const _FontOption({
    required this.label,
    required this.value,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Row(
        children: [
          Icon(
            current == value
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final String value;
  final String current;

  const _ThemeOption({
    required this.label,
    required this.value,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Row(
        children: [
          Icon(
            current == value
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
