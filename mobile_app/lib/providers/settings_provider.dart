import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _loadPreferences();
  }

  static const String _keyTheme = 'setting_theme_mode';
  static const String _keyCountdown = 'setting_sos_countdown';
  static const String _keyGps = 'setting_auto_share_gps';
  static const String _keySound = 'setting_sound_alerts';
  static const String _keyVibration = 'setting_vibration';

  ThemeMode _themeMode = ThemeMode.system;
  int _sosCountdownDuration = 3;
  bool _autoShareGps = true;
  bool _soundAlerts = true;
  bool _vibrationFeedback = true;

  ThemeMode get themeMode => _themeMode;
  int get sosCountdownDuration => _sosCountdownDuration;
  bool get autoShareGps => _autoShareGps;
  bool get soundAlerts => _soundAlerts;
  bool get vibrationFeedback => _vibrationFeedback;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_keyTheme);
      if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      }
      _sosCountdownDuration = prefs.getInt(_keyCountdown) ?? 3;
      _autoShareGps = prefs.getBool(_keyGps) ?? true;
      _soundAlerts = prefs.getBool(_keySound) ?? true;
      _vibrationFeedback = prefs.getBool(_keyVibration) ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTheme, mode.index);
    } catch (_) {}
  }

  Future<void> setCountdownDuration(int seconds) async {
    _sosCountdownDuration = seconds;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCountdown, seconds);
    } catch (_) {}
  }

  Future<void> setAutoShareGps(bool enabled) async {
    _autoShareGps = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyGps, enabled);
    } catch (_) {}
  }

  Future<void> setSoundAlerts(bool enabled) async {
    _soundAlerts = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySound, enabled);
    } catch (_) {}
  }

  Future<void> setVibrationFeedback(bool enabled) async {
    _vibrationFeedback = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyVibration, enabled);
    } catch (_) {}
  }
}
