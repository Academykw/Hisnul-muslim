import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyTheme = 'pref_key_theme';
  static const String _keyArabicFontSize = 'pref_font_arabic_size';
  static const String _keyOtherFontSize = 'pref_font_other_size';
  static const String _keyArabicFont = 'pref_font_arabic_typeface';
  static const String _keyOnboardingDone = 'pref_onboarding_done';
  static const String _keyDailyRemindersEnabled = 'pref_daily_reminders_enabled';
  static const String _keyLocale = 'pref_key_locale';

  SharedPreferences? _prefs;

  String _theme = 'system';
  String _locale = 'en';
  double _arabicFontSize = 26.0;
  double _otherFontSize = 16.0;
  String _arabicFont = 'Uthmanic';
  bool _onboardingDone = false;
  bool _dailyRemindersEnabled = true;

  String get theme => _theme;
  String get localeCode => _locale;
  Locale? get locale => _locale == 'system' ? null : Locale(_locale);
  double get arabicFontSize => _arabicFontSize;
  double get otherFontSize => _otherFontSize;
  String get arabicFont => _arabicFont;
  bool get onboardingDone => _onboardingDone;
  bool get dailyRemindersEnabled => _dailyRemindersEnabled;

  ThemeMode get themeMode {
    switch (_theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> init() async {
    final prefs = await _ensurePrefs();
    _theme = prefs.getString(_keyTheme) ?? 'system';
    _arabicFontSize = (prefs.getInt(_keyArabicFontSize) ?? 26).toDouble();
    _otherFontSize = (prefs.getInt(_keyOtherFontSize) ?? 16).toDouble();
    _arabicFont = prefs.getString(_keyArabicFont) ?? 'Uthmanic';
    _onboardingDone = prefs.getBool(_keyOnboardingDone) ?? false;
    _dailyRemindersEnabled = prefs.getBool(_keyDailyRemindersEnabled) ?? true;
    _locale = prefs.getString(_keyLocale) ?? 'system';
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setTheme(String value) async {
    final prefs = await _ensurePrefs();
    _theme = value;
    await prefs.setString(_keyTheme, value);
    notifyListeners();
  }

  Future<void> setArabicFontSize(double size) async {
    final prefs = await _ensurePrefs();
    _arabicFontSize = size;
    await prefs.setInt(_keyArabicFontSize, size.toInt());
    notifyListeners();
  }

  Future<void> setArabicFont(String font) async {
    final prefs = await _ensurePrefs();
    _arabicFont = font;
    await prefs.setString(_keyArabicFont, font);
    notifyListeners();
  }

  Future<void> setOtherFontSize(double size) async {
    final prefs = await _ensurePrefs();
    _otherFontSize = size;
    await prefs.setInt(_keyOtherFontSize, size.toInt());
    notifyListeners();
  }

  Future<void> setOnboardingDone(bool value) async {
    final prefs = await _ensurePrefs();
    _onboardingDone = value;
    await prefs.setBool(_keyOnboardingDone, value);
    notifyListeners();
  }

  Future<void> setDailyRemindersEnabled(bool value) async {
    final prefs = await _ensurePrefs();
    _dailyRemindersEnabled = value;
    await prefs.setBool(_keyDailyRemindersEnabled, value);
    notifyListeners();
  }

  Future<void> setLocale(String value) async {
    final prefs = await _ensurePrefs();
    _locale = value;
    await prefs.setString(_keyLocale, value);
    notifyListeners();
  }
}
