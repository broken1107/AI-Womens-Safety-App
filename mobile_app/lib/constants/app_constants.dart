abstract final class AppConstants {
  // Map Configurations
  static const double defaultZoom = 15.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 19.0;
  static const double defaultLatitude = 11.3410; // Erode / Tamil Nadu reference point
  static const double defaultLongitude = 77.7172;

  // Overpass Search Radii (in meters)
  static const int overpassRadius = 5000;

  // Debounce Durations
  static const Duration searchDebounce = Duration(milliseconds: 600);

  // SOS Live Tracking Interval
  static const Duration trackingInterval = Duration(seconds: 10);

  // Cache Expirations
  static const Duration cacheExpiry = Duration(minutes: 15);
}
