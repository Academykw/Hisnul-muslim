import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyTheme = 'pref_key_theme';
  static const String _keyArabicFontSize = 'pref_font_arabic_size';
  static const String _keyOtherFontSize = 'pref_font_other_size';
  static const String _keyArabicFont = 'pref_font_arabic_typeface';
  static const String _keyOnboardingDone = 'pref_onboarding_done';

  SharedPreferences? _prefs;

  String _theme = 'system';
  double _arabicFontSize = 22.0;
  double _otherFontSize = 14.0;
  String _arabicFont = 'Uthmanic';
  bool _onboardingDone = false;

  String get theme => _theme;
  double get arabicFontSize => _arabicFontSize;
  double get otherFontSize => _otherFontSize;
  String get arabicFont => _arabicFont;
  bool get onboardingDone => _onboardingDone;

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
    _arabicFontSize = (prefs.getInt(_keyArabicFontSize) ?? 22).toDouble();
    _otherFontSize = (prefs.getInt(_keyOtherFontSize) ?? 14).toDouble();
    _arabicFont = prefs.getString(_keyArabicFont) ?? 'Uthmanic';
    _onboardingDone = prefs.getBool(_keyOnboardingDone) ?? false;
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
}
