import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:safety_guardian/app.dart';
import 'package:safety_guardian/models/crime_risk.dart';
import 'package:safety_guardian/models/crime_zone.dart';
import 'package:safety_guardian/models/emergency_contact.dart';
import 'package:safety_guardian/models/incident_report.dart';
import 'package:safety_guardian/models/notification_model.dart';
import 'package:safety_guardian/models/place.dart';
import 'package:safety_guardian/models/route_model.dart';
import 'package:safety_guardian/models/safe_route.dart';
import 'package:safety_guardian/models/sos_alert.dart';
import 'package:safety_guardian/models/user.dart';
import 'package:safety_guardian/models/user_location.dart';
import 'package:safety_guardian/providers/amenity_provider.dart';
import 'package:safety_guardian/providers/auth_provider.dart';
import 'package:safety_guardian/providers/connectivity_provider.dart';
import 'package:safety_guardian/providers/contact_provider.dart';
import 'package:safety_guardian/providers/crime_risk_provider.dart';
import 'package:safety_guardian/providers/incident_provider.dart';
import 'package:safety_guardian/providers/location_provider.dart';
import 'package:safety_guardian/providers/map_provider.dart';
import 'package:safety_guardian/providers/notification_provider.dart';
import 'package:safety_guardian/providers/profile_provider.dart';
import 'package:safety_guardian/providers/route_provider.dart';
import 'package:safety_guardian/providers/settings_provider.dart';
import 'package:safety_guardian/providers/sos_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Safety Guardian Model Tests', () {
    test('User fromJson and toJson work correctly', () {
      final json = {
        'id': 101,
        'name': 'Pooja',
        'email': 'pooja@example.com',
        'phone': '+919876543210',
      };
      final user = User.fromJson(json);
      expect(user.id, 101);
      expect(user.name, 'Pooja');
      expect(user.email, 'pooja@example.com');
      expect(user.phone, '+919876543210');
      expect(user.toJson()['name'], 'Pooja');
    });

    test('EmergencyContact model serializes properly', () {
      final json = {
        'id': 1,
        'name': 'Mom',
        'phone': '+919876543210',
        'relationship': 'Mother',
        'is_primary': 1,
      };
      final contact = EmergencyContact.fromJson(json);
      expect(contact.id, 1);
      expect(contact.name, 'Mom');
      expect(contact.isPrimary, true);
      expect(contact.toJson()['relationship'], 'Mother');
    });

    test('NotificationModel serialization and read status work', () {
      final json = {
        'id': 'notif_1',
        'title': 'Emergency Alert',
        'message': 'SOS broadcast triggered nearby',
        'type': 'SOS',
        'is_read': 0,
      };
      final notif = NotificationModel.fromJson(json);
      expect(notif.id, 'notif_1');
      expect(notif.title, 'Emergency Alert');
      expect(notif.body, 'SOS broadcast triggered nearby');
      expect(notif.isRead, false);

      final readCopy = notif.copyWith(isRead: true);
      expect(readCopy.isRead, true);
    });

    test('UserLocation serialization and copyWith work', () {
      const loc = UserLocation(
        latitude: 11.3410,
        longitude: 77.7172,
        accuracy: 5.0,
        address: 'Erode, TN',
      );
      expect(loc.latitude, 11.3410);
      expect(loc.longitude, 77.7172);
      expect(loc.address, 'Erode, TN');

      final updated = loc.copyWith(address: 'Perundurai, Erode');
      expect(updated.address, 'Perundurai, Erode');
      expect(updated.latitude, 11.3410);
    });

    test('Place fromNominatim parses search results correctly', () {
      final nominatimJson = {
        'place_id': 987654,
        'lat': '11.3410',
        'lon': '77.7172',
        'display_name': 'Erode Bus Stand, Erode, Tamil Nadu, India',
        'name': 'Erode Bus Stand',
      };
      final place = Place.fromNominatim(nominatimJson);
      expect(place.name, 'Erode Bus Stand');
      expect(place.latitude, 11.3410);
      expect(place.longitude, 77.7172);
      expect(place.type, PlaceType.searchResult);
    });

    test('CrimeRisk model parses levels and recommendations accurately', () {
      final json = {
        'risk_score': 82,
        'risk_level': 'HIGH',
        'recommendation': 'Stay along well-lit main corridors.',
      };
      final risk = CrimeRisk.fromJson(json);
      expect(risk.riskScore, 82.0);
      expect(risk.isHighRisk, true);
      expect(risk.isLowRisk, false);
      expect(risk.recommendation, 'Stay along well-lit main corridors.');
    });

    test('CrimeZone model serializes and checks risk levels properly', () {
      final json = {
        'id': 1,
        'name': 'Market Back Alley',
        'latitude': 11.3450,
        'longitude': 77.7190,
        'radius': 500,
        'risk_score': 85.0,
        'risk_level': 'HIGH',
        'reported_incidents_count': 12,
        'description': 'Poor lighting corridor',
      };
      final zone = CrimeZone.fromJson(json);
      expect(zone.name, 'Market Back Alley');
      expect(zone.isHighRisk, true);
      expect(zone.isLowRisk, false);
      expect(zone.incidentCount, 12);
    });

    test('SOSAlert model serialization works correctly', () {
      final json = {
        'id': 42,
        'latitude': 11.3410,
        'longitude': 77.7172,
        'status': 'active',
      };
      final alert = SOSAlert.fromJson(json);
      expect(alert.id, 42);
      expect(alert.latitude, 11.3410);
      expect(alert.status, 'active');
    });

    test('IncidentReport model serialization works correctly', () {
      final json = {
        'id': 7,
        'title': 'Broken Street Lamp',
        'description': 'Road is completely dark after 7pm',
        'category': 'Poor Lighting',
        'area': 'Perundurai',
        'latitude': 11.3400,
        'longitude': 77.7100,
        'status': 'PENDING',
      };
      final incident = IncidentReport.fromJson(json);
      expect(incident.id, 7);
      expect(incident.displayTitle, 'Broken Street Lamp');
      expect(incident.category, 'Poor Lighting');
    });

    test('Place fromOverpassNode parses amenities correctly', () {
      final node = {
        'id': 123456,
        'lat': 11.3410,
        'lon': 77.7172,
        'tags': {
          'amenity': 'police',
          'name': 'Central Police Station',
          'phone': '100',
        },
      };
      final place = Place.fromOverpassNode(node);
      expect(place.type, PlaceType.police);
      expect(place.name, 'Central Police Station');
      expect(place.phone, '100');
    });

    test('RouteModel fromOsrm parses distances and durations', () {
      final osrmJson = {
        'distance': 4500.0,
        'duration': 720.0,
        'geometry': {
          'coordinates': [
            [77.7172, 11.3410],
            [77.7200, 11.3450],
          ],
        },
        'legs': [
          {
            'steps': [
              {
                'instruction': 'Head north on Main Rd',
                'distance': 1500.0,
                'duration': 240.0,
                'name': 'Main Rd',
              }
            ],
          }
        ],
      };
      final route = RouteModel.fromOsrm(osrmJson);
      expect(route.distanceInKm, 4.5);
      expect(route.durationInMinutes, 12.0);
      expect(route.formattedDistance, '4.5 km');
      expect(route.formattedDuration, '12 min');
      expect(route.geometryCoordinates.length, 2);
      expect(route.steps.length, 1);
    });

    test('SafeRoute combines route and risk', () {
      final safeRoute = SafeRoute(
        id: 'sr_1',
        name: 'Main Well-Lit Boulevard',
        route: const RouteModel(
          distanceMeters: 4500,
          durationSeconds: 720,
          geometryCoordinates: [],
        ),
        risk: const CrimeRisk(riskLevel: 'LOW', riskScore: 18.0),
        isRecommended: true,
      );
      expect(safeRoute.isRecommended, true);
      expect(safeRoute.risk.isLowRisk, true);
      expect(safeRoute.formattedDistance, '4.5 km');
    });
  });

  group('Safety Guardian Provider Tests', () {
    test('NotificationProvider tracks unread alerts and local notifications', () {
      final provider = NotificationProvider();
      expect(provider.unreadCount, 0);

      provider.addLocalNotification(
        title: 'Safe Arrival',
        body: 'You have reached your designated safe zone.',
        type: 'SYSTEM',
      );

      expect(provider.notifications.length, 1);
      expect(provider.unreadCount, 1);
    });

    test('MapProvider manages destination selection and map center', () {
      final provider = MapProvider();
      expect(provider.selectedDestination, null);

      const place = Place(
        id: 'p1',
        name: 'City Hospital',
        latitude: 11.3450,
        longitude: 77.7200,
      );

      provider.selectDestination(place);
      expect(provider.selectedDestination?.name, 'City Hospital');
      expect(provider.mapCenter.latitude, 11.3450);

      provider.clearDestination();
      expect(provider.selectedDestination, null);
    });

    test('AmenityProvider tracks police stations and hospital lists', () {
      final provider = AmenityProvider();
      expect(provider.policeStations.isEmpty, true);
      expect(provider.hospitals.isEmpty, true);
      expect(provider.isLoading, false);
    });

    test('RouteProvider manages active route and clear actions', () {
      final provider = RouteProvider();
      expect(provider.activeSafeRoute, null);
      expect(provider.safeRoutes.isEmpty, true);

      final mockRoute = SafeRoute(
        id: 'sr_test',
        name: 'Test Safe Route',
        route: const RouteModel(distanceMeters: 2000, durationSeconds: 300, geometryCoordinates: []),
        risk: const CrimeRisk(riskLevel: 'LOW', riskScore: 15.0),
      );

      provider.setActiveRoute(mockRoute);
      expect(provider.activeSafeRoute?.name, 'Test Safe Route');

      provider.clearRoute();
      expect(provider.activeSafeRoute, null);
      expect(provider.safeRoutes.isEmpty, true);
    });

    test('CrimeRiskProvider manages temporal simulations and categories', () {
      final provider = CrimeRiskProvider();
      expect(provider.selectedCategory, 'Harassment');
      expect(provider.selectedArea, 'Downtown');
      expect(provider.crimeZones.isEmpty, true);
    });

    test('SosProvider tracks countdown and active broadcast status', () {
      final provider = SosProvider();
      expect(provider.isSosActive, false);
      expect(provider.isCountingDown, false);
      expect(provider.countdownSeconds, 3);
    });

    test('IncidentProvider manages incident reporting state', () {
      final provider = IncidentProvider();
      expect(provider.incidents.isEmpty, true);
      expect(provider.isLoading, false);
      expect(provider.isSubmitting, false);
    });

    test('SettingsProvider updates ThemeMode and countdown preferences', () async {
      final provider = SettingsProvider();
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.sosCountdownDuration, 3);

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);

      await provider.setCountdownDuration(5);
      expect(provider.sosCountdownDuration, 5);
    });
  });

  group('Safety Guardian Widget Tests', () {
    testWidgets('App renders splash screen initially with brand title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ContactProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => LocationProvider()),
            ChangeNotifierProvider(create: (_) => MapProvider()),
            ChangeNotifierProvider(create: (_) => AmenityProvider()),
            ChangeNotifierProvider(create: (_) => RouteProvider()),
            ChangeNotifierProvider(create: (_) => CrimeRiskProvider()),
            ChangeNotifierProvider(create: (_) => SosProvider()),
            ChangeNotifierProvider(create: (_) => IncidentProvider()),
            ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const SafetyGuardianApp(),
        ),
      );

      expect(find.text('Safety Guardian'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
