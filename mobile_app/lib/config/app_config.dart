import 'dart:io';
import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const String _envApiBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static String _runtimeApiBaseUrl = '';

  /// Set a runtime custom API Base URL (e.g. from Settings or SharedPreferences)
  static void setRuntimeApiBaseUrl(String url) {
    _runtimeApiBaseUrl = url.trim();
  }

  /// Base URL for the Laravel REST API backend.
  ///
  /// Physical Android device connected through USB:
  ///   adb reverse tcp:8000 tcp:8000
  ///   http://127.0.0.1:8000/api/
  ///
  /// Android Emulator:
  ///   http://10.0.2.2:8000/api/
  ///
  /// Wi-Fi Local Network (LAN):
  ///   `http://127.0.0.1:8000/api/`
  static String get apiBaseUrl {
    if (_runtimeApiBaseUrl.isNotEmpty) {
      return _runtimeApiBaseUrl.endsWith('/')
          ? _runtimeApiBaseUrl
          : '$_runtimeApiBaseUrl/';
    }

    if (_envApiBaseUrl.isNotEmpty) {
      return _envApiBaseUrl.endsWith('/')
          ? _envApiBaseUrl
          : '$_envApiBaseUrl/';
    }

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://127.0.0.1:8000/api/';
    }

    return 'http://127.0.0.1:8000/api/';
  }

  /// Google Maps Android API Key
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDummyKeyReplaceWithYourGoogleMapsApiKey',
  );

  // OpenStreetMap Tile URL Template
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Nominatim Reverse Geocoding & Search Base URL
  static const String nominatimBaseUrl =
      'https://nominatim.openstreetmap.org';

  // Overpass API Base URL
  static const String overpassBaseUrl =
      'https://overpass-api.de/api/interpreter';

  // OSRM Driving & Walking Routing Base URL
  static const String osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  // Application User Agent
  static const String userAgent =
      'SafetyGuardian-FlutterApp/1.0 (safety_guardian@app.local)';

  // Network Timeouts (Extended to 25s for reliable mobile network responses)
  static const Duration connectTimeout =
      Duration(seconds: 25);

  static const Duration receiveTimeout =
      Duration(seconds: 25);

  static const Duration sendTimeout =
      Duration(seconds: 25);
}