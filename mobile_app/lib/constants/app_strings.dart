abstract final class AppStrings {
  static const String appName = 'Safety Guardian';
  static const String appTagline = "AI-Powered Women's Safety & Emergency Response";

  // Auth & Onboarding
  static const String welcomeBack = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to access your personal safety network';
  static const String createAccount = 'Create Account';
  static const String registerSubtitle = 'Join Safety Guardian to protect yourself and loved ones';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String verifyOtp = 'Verify OTP';
  static const String enterOtpPrompt = 'Enter the 6-digit verification code sent to your email';

  // Home & Dashboard
  static const String home = 'Home';
  static const String map = 'Map';
  static const String sos = 'SOS';
  static const String alerts = 'Alerts';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String emergencyContacts = 'Emergency Contacts';
  static const String nearbyPolice = 'Nearby Police';
  static const String nearbyHospitals = 'Nearby Hospitals';
  static const String reportIncident = 'Report Incident';
  static const String safeRoute = 'Safe Route';
  static const String crimeRisk = 'Crime Risk';

  // SOS Strings
  static const String sosEmergency = 'EMERGENCY SOS';
  static const String sosTapPrompt = 'Tap and hold to broadcast your live GPS to emergency contacts';
  static const String sosConfirmTitle = 'Send Emergency SOS?';
  static const String sosConfirmMessage = 'This will immediately broadcast your live GPS location and alert your emergency contacts.';
  static const String sosSentSuccess = 'SOS Alert Broadcasted';
  static const String sosSentDetail = 'Your emergency contacts and response centers have been notified with your live coordinates.';
  static const String sosCancel = 'Cancel SOS';

  // Risk Predictions
  static const String lowRisk = 'LOW RISK';
  static const String mediumRisk = 'MEDIUM RISK';
  static const String highRisk = 'HIGH RISK';
  static const String aiEstimatedRisk = 'AI Estimated Safety Score';
  static const String recommendedRoute = 'Recommended Safe Route';

  // Errors & Validations
  static const String noInternet = 'No Internet Connection. Please check your network settings.';
  static const String gpsDisabled = 'Location services are disabled. Please turn on GPS to enable safety features.';
  static const String permissionDenied = 'Location permission is required for emergency tracking and map safety.';
  static const String generalError = 'An unexpected error occurred. Please try again.';
}
