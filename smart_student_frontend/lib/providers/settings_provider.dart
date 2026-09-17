import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // ── Private state ──────────────────────────────────────────────────────────
  Locale _currentLocale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;

  // ── Public getters ─────────────────────────────────────────────────────────
  Locale get currentLocale => _currentLocale;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isArabic => _currentLocale.languageCode == 'ar';

  // ── Constructor: kicks off async preference loading ────────────────────────
  SettingsProvider() {
    _loadFromPreferences();
  }

  // ── Load saved settings on startup ────────────────────────────────────────
  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedLang = prefs.getString('language') ?? 'عربي';
    _currentLocale = (savedLang == 'English' || savedLang == 'en')
        ? const Locale('en')
        : const Locale('ar');

    final savedDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = savedDark ? ThemeMode.dark : ThemeMode.light;

    notifyListeners();
  }

  // ── Update locale ─────────────────────────────────────────────────────────
  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'language',
      locale.languageCode == 'en' ? 'English' : 'عربي',
    );
  }

  // ── Toggle dark / light mode ──────────────────────────────────────────────
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }
}
