import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/amenity_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/crime_risk_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/location_provider.dart';
import 'providers/map_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/route_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sos_provider.dart';
import 'services/api_client.dart';
import 'services/connectivity_service.dart';
import 'services/incident_service.dart';
import 'services/local_notification_service.dart';
import 'services/location_service.dart';
import 'services/nominatim_service.dart';
import 'services/overpass_service.dart';
import 'services/prediction_service.dart';
import 'services/route_service.dart';
import 'services/routing_service.dart';
import 'services/sos_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Notifications
  await LocalNotificationService.instance.initialize();

  final apiClient = ApiClient();
  final locationService = LocationService();
  final nominatimService = NominatimService();
  final overpassService = OverpassService();
  final routingService = RoutingService();
  final routeService = RouteService(apiClient: apiClient, routingService: routingService);
  final predictionService = PredictionService(apiClient: apiClient);
  final sosService = SosService(apiClient: apiClient);
  final incidentService = IncidentService(apiClient: apiClient);
  final connectivityService = ConnectivityService();

  final authProvider = AuthProvider(apiClient: apiClient);
  final contactProvider = ContactProvider(apiClient: apiClient);
  final notificationProvider = NotificationProvider(apiClient: apiClient);
  final profileProvider = ProfileProvider(apiClient: apiClient);
  final locationProvider = LocationProvider(
    locationService: locationService,
    nominatimService: nominatimService,
  );
  final mapProvider = MapProvider(nominatimService: nominatimService);
  final amenityProvider = AmenityProvider(overpassService: overpassService);
  final routeProvider = RouteProvider(apiClient: apiClient, routeService: routeService);
  final crimeRiskProvider = CrimeRiskProvider(apiClient: apiClient, predictionService: predictionService);
  final sosProvider = SosProvider(apiClient: apiClient, sosService: sosService);
  final incidentProvider = IncidentProvider(apiClient: apiClient, incidentService: incidentService);
  final connectivityProvider = ConnectivityProvider(connectivityService: connectivityService);
  final settingsProvider = SettingsProvider(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: contactProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
        ChangeNotifierProvider.value(value: profileProvider),
        ChangeNotifierProvider.value(value: locationProvider),
        ChangeNotifierProvider.value(value: mapProvider),
        ChangeNotifierProvider.value(value: amenityProvider),
        ChangeNotifierProvider.value(value: routeProvider),
        ChangeNotifierProvider.value(value: crimeRiskProvider),
        ChangeNotifierProvider.value(value: sosProvider),
        ChangeNotifierProvider.value(value: incidentProvider),
        ChangeNotifierProvider.value(value: connectivityProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const SafetyGuardianApp(),
    ),
  );
}
