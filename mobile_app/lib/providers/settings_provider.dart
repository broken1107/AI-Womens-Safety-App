import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/api_client.dart';

class ConnectionTestResult {
  const ConnectionTestResult({
    required this.success,
    required this.message,
    this.latencyMs = 0,
    this.statusCode,
  });

  final bool success;
  final String message;
  final int latencyMs;
  final int? statusCode;
}

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({this.apiClient}) {
    _loadPreferences();
  }

  final ApiClient? apiClient;

  static const String _keyTheme = 'setting_theme_mode';
  static const String _keyCountdown = 'setting_sos_countdown';
  static const String _keyGps = 'setting_auto_share_gps';
  static const String _keySound = 'setting_sound_alerts';
  static const String _keyVibration = 'setting_vibration';
  static const String _keyServerUrl = 'setting_server_base_url';

  ThemeMode _themeMode = ThemeMode.system;
  int _sosCountdownDuration = 3;
  bool _autoShareGps = true;
  bool _soundAlerts = true;
  bool _vibrationFeedback = true;
  String _serverBaseUrl = AppConfig.apiBaseUrl;
  bool _isTestingConnection = false;
  ConnectionTestResult? _lastConnectionTest;

  ThemeMode get themeMode => _themeMode;
  int get sosCountdownDuration => _sosCountdownDuration;
  bool get autoShareGps => _autoShareGps;
  bool get soundAlerts => _soundAlerts;
  bool get vibrationFeedback => _vibrationFeedback;
  String get serverBaseUrl => _serverBaseUrl;
  bool get isTestingConnection => _isTestingConnection;
  ConnectionTestResult? get lastConnectionTest => _lastConnectionTest;

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

      final savedUrl = prefs.getString(_keyServerUrl);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _serverBaseUrl = savedUrl.trim();
        AppConfig.setRuntimeApiBaseUrl(_serverBaseUrl);
        apiClient?.setBaseUrl(_serverBaseUrl);
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> setServerBaseUrl(String url) async {
    var formatted = url.trim();
    if (formatted.isNotEmpty && !formatted.endsWith('/')) {
      formatted = '$formatted/';
    }
    _serverBaseUrl = formatted;
    AppConfig.setRuntimeApiBaseUrl(formatted);
    apiClient?.setBaseUrl(formatted);
    _lastConnectionTest = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyServerUrl, formatted);
    } catch (_) {}
  }

  Future<ConnectionTestResult> testServerConnection() async {
    _isTestingConnection = true;
    _lastConnectionTest = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    try {
      if (apiClient == null) {
        throw Exception('API Client is not initialized');
      }

      // Ping prediction endpoint or login check
      final response = await apiClient!.post(
        'predict-risk',
        data: {
          'latitude': 13.0827,
          'longitude': 80.2707,
        },
      );
      stopwatch.stop();

      final result = ConnectionTestResult(
        success: response.statusCode == 200 || response.statusCode == 201,
        message: 'Backend API reachable! Connected in ${stopwatch.elapsedMilliseconds}ms.',
        latencyMs: stopwatch.elapsedMilliseconds,
        statusCode: response.statusCode,
      );
      _lastConnectionTest = result;
      return result;
    } catch (e) {
      stopwatch.stop();
      final result = ConnectionTestResult(
        success: false,
        message: 'Connection failed (${stopwatch.elapsedMilliseconds}ms): $e',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      _lastConnectionTest = result;
      return result;
    } finally {
      _isTestingConnection = false;
      notifyListeners();
    }
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
