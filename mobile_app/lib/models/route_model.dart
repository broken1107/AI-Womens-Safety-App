import 'package:latlong2/latlong.dart';

class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    this.name,
    this.maneuverType,
    this.maneuverModifier,
  });

  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final String? name;
  final String? maneuverType;
  final String? maneuverModifier;

  double get distanceInKm => distanceMeters / 1000.0;
  double get durationInMinutes => durationSeconds / 60.0;

  String get formattedDistance {
    if (distanceInKm < 1.0) {
      return '${distanceMeters.round()} m';
    }
    return '${distanceInKm.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    final mins = durationInMinutes.round();
    if (mins < 1) return '< 1 min';
    return '$mins min';
  }

  factory RouteStep.fromOsrmStep(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] is Map ? json['maneuver'] as Map : {};
    final type = maneuver['type'] as String? ?? 'turn';
    final modifier = maneuver['modifier'] as String? ?? '';
    final streetName = json['name'] as String? ?? '';

    String instruction = json['instruction'] as String? ?? '';
    if (instruction.isEmpty) {
      if (type == 'depart') {
        instruction = streetName.isNotEmpty ? 'Head on $streetName' : 'Start heading along route';
      } else if (type == 'arrive') {
        instruction = 'You have arrived at your destination';
      } else {
        final direction = modifier.isNotEmpty ? ' $modifier' : '';
        instruction = streetName.isNotEmpty ? 'Turn$direction onto $streetName' : 'Turn$direction';
      }
    }

    return RouteStep(
      instruction: instruction,
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['duration'] as num?)?.toDouble() ?? 0.0,
      name: streetName,
      maneuverType: type,
      maneuverModifier: modifier,
    );
  }

  factory RouteStep.fromJson(Map<String, dynamic> json) => RouteStep(
    instruction: json['instruction'] as String? ?? '',
    distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
    durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
    name: json['name'] as String?,
    maneuverType: json['maneuver_type'] as String?,
    maneuverModifier: json['maneuver_modifier'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'instruction': instruction,
    'distance_meters': distanceMeters,
    'duration_seconds': durationSeconds,
    'name': name,
    'maneuver_type': maneuverType,
    'maneuver_modifier': maneuverModifier,
  };
}

class RouteModel {
  const RouteModel({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometryCoordinates,
    this.steps = const [],
    this.summary,
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> geometryCoordinates;
  final List<RouteStep> steps;
  final String? summary;

  double get distanceInKm => distanceMeters / 1000.0;
  double get durationInMinutes => durationSeconds / 60.0;

  String get formattedDistance {
    if (distanceInKm < 1.0) {
      return '${distanceMeters.round()} m';
    }
    return '${distanceInKm.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    final mins = durationInMinutes.round();
    if (mins < 60) {
      return '$mins min';
    }
    final hrs = mins ~/ 60;
    final remainingMins = mins % 60;
    return remainingMins > 0 ? '$hrs hr $remainingMins min' : '$hrs hr';
  }

  factory RouteModel.fromOsrm(Map<String, dynamic> routeJson) {
    final distance = (routeJson['distance'] as num?)?.toDouble() ?? 0.0;
    final duration = (routeJson['duration'] as num?)?.toDouble() ?? 0.0;
    final summary = routeJson['weight_name'] as String? ?? '';

    // Geometry is GeoJSON format: coordinates are [[lon, lat], ...]
    final coordinates = <LatLng>[];
    if (routeJson['geometry'] is Map) {
      final geo = routeJson['geometry'] as Map;
      if (geo['coordinates'] is List) {
        for (final item in geo['coordinates'] as List) {
          if (item is List && item.length >= 2) {
            final lon = (item[0] as num).toDouble();
            final lat = (item[1] as num).toDouble();
            coordinates.add(LatLng(lat, lon));
          }
        }
      }
    }

    final steps = <RouteStep>[];
    if (routeJson['legs'] is List && (routeJson['legs'] as List).isNotEmpty) {
      final firstLeg = (routeJson['legs'] as List).first as Map;
      if (firstLeg['steps'] is List) {
        for (final s in firstLeg['steps'] as List) {
          if (s is Map<String, dynamic>) {
            steps.add(RouteStep.fromOsrmStep(s));
          } else if (s is Map) {
            steps.add(RouteStep.fromOsrmStep(Map<String, dynamic>.from(s)));
          }
        }
      }
    }

    return RouteModel(
      distanceMeters: distance,
      durationSeconds: duration,
      geometryCoordinates: coordinates,
      steps: steps,
      summary: summary,
    );
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final coords = <LatLng>[];
    if (json['coordinates'] is List) {
      for (final c in json['coordinates'] as List) {
        if (c is List && c.length >= 2) {
          coords.add(LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble()));
        } else if (c is Map) {
          coords.add(LatLng((c['lat'] as num).toDouble(), (c['lng'] as num).toDouble()));
        }
      }
    }

    final steps = <RouteStep>[];
    if (json['steps'] is List) {
      for (final s in json['steps'] as List) {
        if (s is Map) {
          steps.add(RouteStep.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    return RouteModel(
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      geometryCoordinates: coords,
      steps: steps,
      summary: json['summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'distance_meters': distanceMeters,
    'duration_seconds': durationSeconds,
    'coordinates': geometryCoordinates.map((e) => [e.latitude, e.longitude]).toList(),
    'steps': steps.map((e) => e.toJson()).toList(),
    'summary': summary,
  };
}
