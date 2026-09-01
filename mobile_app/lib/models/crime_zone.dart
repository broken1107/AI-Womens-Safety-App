import 'package:latlong2/latlong.dart';

class CrimeZone {
  const CrimeZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.riskLevel, // 'LOW', 'MEDIUM', 'HIGH'
    required this.riskScore, // 0 - 100
    this.description,
    this.reportedIncidentsCount = 0,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String riskLevel;
  final double riskScore;
  final String? description;
  final int reportedIncidentsCount;

  LatLng get coordinates => LatLng(latitude, longitude);
  double get radiusMeters => radius;
  int get incidentCount => reportedIncidentsCount;

  bool get isHighRisk => riskLevel.toUpperCase() == 'HIGH' || riskScore >= 70;
  bool get isMediumRisk => riskLevel.toUpperCase() == 'MEDIUM' || (riskScore >= 40 && riskScore < 70);
  bool get isLowRisk => !isHighRisk && !isMediumRisk;

  factory CrimeZone.fromJson(Map<String, dynamic> json) {
    return CrimeZone(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? 'Safety Observation Zone',
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse('${json['latitude']}') ?? 0.0,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse('${json['longitude']}') ?? 0.0,
      radius: (json['radius'] is num)
          ? (json['radius'] as num).toDouble()
          : double.tryParse('${json['radius']}') ?? 300.0,
      riskLevel: (json['risk_level'] as String? ?? 'LOW').toUpperCase(),
      riskScore: (json['risk_score'] is num)
          ? (json['risk_score'] as num).toDouble()
          : double.tryParse('${json['risk_score']}') ?? 0.0,
      description: json['description'] as String?,
      reportedIncidentsCount: json['reported_incidents_count'] is int
          ? json['reported_incidents_count'] as int
          : json['incident_count'] is int
              ? json['incident_count'] as int
              : int.tryParse('${json['reported_incidents_count'] ?? json['incident_count']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'risk_level': riskLevel,
    'risk_score': riskScore,
    'description': description,
    'reported_incidents_count': reportedIncidentsCount,
  };
}
