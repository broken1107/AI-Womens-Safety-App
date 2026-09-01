abstract final class ApiEndpoints {
  // Authentication & Session
  static const String register = 'register';
  static const String login = 'login';
  static const String verifyOtp = 'verify-otp';
  static const String logout = 'logout';

  // User Profile
  static const String profile = 'profile';

  // Emergency Contacts CRUD
  static const String contacts = 'contacts';
  static String contactDetail(Object id) => 'contacts/$id';

  // SOS Alerts & Emergency Tracking
  static const String sosTrigger = 'sos/trigger';
  static String sosTrack(Object sosId) => 'sos/$sosId/track';
  static String sosResolve(Object sosId) => 'sos/$sosId/resolve';

  // Incident Reporting
  static const String incidents = 'incidents';

  // Crime Risk Prediction & Safe Routes
  static const String predictRisk = 'predict-risk';
  static const String safeRouteRecommendation = 'routes/safe-recommendation';

  // Push Notifications
  static const String notifications = 'notifications';
  static String notificationRead(Object id) => 'notifications/$id/read';
}
