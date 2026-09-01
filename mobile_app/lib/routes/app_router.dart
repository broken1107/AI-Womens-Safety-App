import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/contacts/add_contact_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/contacts/edit_contact_screen.dart';
import '../screens/crime_risk/crime_risk_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/hospitals/nearby_hospitals_screen.dart';
import '../screens/incident/incident_report_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/police/nearby_police_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/routes/safe_route_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/sos/sos_screen.dart';
import '../screens/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';
  static const String map = '/map';
  static const String sos = '/sos';
  static const String contacts = '/contacts';
  static const String addContact = '/contacts/add';
  static const String editContact = '/contacts/edit';
  static const String crimeRisk = '/crime-risk';
  static const String safeRoute = '/safe-route';
  static const String police = '/police';
  static const String hospitals = '/hospitals';
  static const String incidentReport = '/incident-report';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen(), settings: settings);
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen(), settings: settings);
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen(), settings: settings);
      case otpVerification:
        final email = settings.arguments is String ? settings.arguments as String : '';
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: email),
          settings: settings,
        );
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen(), settings: settings);
      case map:
        return MaterialPageRoute(builder: (_) => const MapScreen(), settings: settings);
      case sos:
        return MaterialPageRoute(builder: (_) => const SOSScreen(), settings: settings);
      case contacts:
        return MaterialPageRoute(builder: (_) => const ContactsScreen(), settings: settings);
      case addContact:
        return MaterialPageRoute(builder: (_) => const AddContactScreen(), settings: settings);
      case editContact:
        return MaterialPageRoute(
          builder: (_) => EditContactScreen(contact: settings.arguments),
          settings: settings,
        );
      case crimeRisk:
        return MaterialPageRoute(builder: (_) => const CrimeRiskScreen(), settings: settings);
      case safeRoute:
        return MaterialPageRoute(builder: (_) => const SafeRouteScreen(), settings: settings);
      case police:
        return MaterialPageRoute(builder: (_) => const NearbyPoliceScreen(), settings: settings);
      case hospitals:
        return MaterialPageRoute(builder: (_) => const NearbyHospitalsScreen(), settings: settings);
      case incidentReport:
        return MaterialPageRoute(builder: (_) => const IncidentReportScreen(), settings: settings);
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen(), settings: settings);
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen(), settings: settings);
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen(), settings: settings);
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen(), settings: settings);
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(child: Text('Page not found: ${settings.name}')),
          ),
          settings: settings,
        );
    }
  }
}
