import 'package:latlong2/latlong.dart';
import 'crime_risk.dart';
import 'route_model.dart';

class SafeRoute {
  const SafeRoute({
    required this.id,
    required this.name,
    required this.route,
    required this.risk,
    this.isRecommended = false,
    this.safetyRecommendation,
    this.alternativeIndex = 0,
  });

  final String id;
  final String name;
  final RouteModel route;
  final CrimeRisk risk;
  final bool isRecommended;
  final String? safetyRecommendation;
  final int alternativeIndex;

  double get distanceInKm => route.distanceInKm;
  double get durationInMinutes => route.durationInMinutes;
  String get formattedDistance => route.formattedDistance;
  String get formattedDuration => route.formattedDuration;
  List<LatLng> get coordinates => route.geometryCoordinates;

  factory SafeRoute.fromJson(Map<String, dynamic> json) {
    RouteModel parsedRoute;
    if (json['route'] is Map<String, dynamic>) {
      parsedRoute = RouteModel.fromJson(json['route'] as Map<String, dynamic>);
    } else if (json['osrm'] is Map<String, dynamic>) {
      parsedRoute = RouteModel.fromOsrm(json['osrm'] as Map<String, dynamic>);
    } else {
      parsedRoute = const RouteModel(
        distanceMeters: 0,
        durationSeconds: 0,
        geometryCoordinates: [],
      );
    }

    CrimeRisk parsedRisk;
    if (json['risk'] is Map<String, dynamic>) {
      parsedRisk = CrimeRisk.fromJson(json['risk'] as Map<String, dynamic>);
    } else if (json['crime_risk'] is Map<String, dynamic>) {
      parsedRisk = CrimeRisk.fromJson(json['crime_risk'] as Map<String, dynamic>);
    } else {
      final score = (json['risk_score'] as num?)?.toDouble() ?? 20.0;
      final level = json['risk_level'] as String? ?? 'LOW';
      parsedRisk = CrimeRisk(riskLevel: level, riskScore: score);
    }

    return SafeRoute(
      id: '${json['id'] ?? 'route_${DateTime.now().millisecondsSinceEpoch}'}',
      name: json['name'] as String? ?? 'Recommended Safety Route',
      route: parsedRoute,
      risk: parsedRisk,
      isRecommended: json['is_recommended'] == true || json['recommended'] == true,
      safetyRecommendation: json['safety_recommendation'] as String? ?? parsedRisk.recommendation,
      alternativeIndex: json['alternative_index'] is int ? json['alternative_index'] as int : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'route': route.toJson(),
    'risk': risk.toJson(),
    'is_recommended': isRecommended,
    'safety_recommendation': safetyRecommendation,
    'alternative_index': alternativeIndex,
  };
}
