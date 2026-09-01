import 'package:latlong2/latlong.dart';

enum PlaceType {
  police,
  hospital,
  fireStation,
  pharmacy,
  emergency,
  destination,
  currentLocation,
  searchResult,
  generic,
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.type = PlaceType.generic,
    this.phone,
    this.distanceInKm,
    this.amenityTag,
    this.tags = const {},
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final PlaceType type;
  final String? phone;
  final double? distanceInKm;
  final String? amenityTag;
  final Map<String, dynamic> tags;

  LatLng get coordinates => LatLng(latitude, longitude);

  String get displayDistance {
    if (distanceInKm == null) return '';
    if (distanceInKm! < 1.0) {
      final meters = (distanceInKm! * 1000).round();
      return '$meters m';
    }
    return '${distanceInKm!.toStringAsFixed(1)} km';
  }

  factory Place.fromNominatim(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}') ?? 0.0;
    final lon = double.tryParse('${json['lon']}') ?? 0.0;
    final displayName = json['display_name'] as String? ?? 'Selected Location';
    final name = json['name'] as String? ?? displayName.split(',').first.trim();

    return Place(
      id: '${json['place_id'] ?? json['osm_id'] ?? '${lat}_$lon'}',
      name: name.isNotEmpty ? name : 'Selected Location',
      latitude: lat,
      longitude: lon,
      address: displayName,
      type: PlaceType.searchResult,
      tags: json,
    );
  }

  factory Place.fromOverpassNode(Map<String, dynamic> json, {double? userLat, double? userLon}) {
    final lat = (json['lat'] is num) ? (json['lat'] as num).toDouble() : double.tryParse('${json['lat']}') ?? 0.0;
    final lon = (json['lon'] is num) ? (json['lon'] as num).toDouble() : double.tryParse('${json['lon']}') ?? 0.0;
    final tags = json['tags'] is Map ? Map<String, dynamic>.from(json['tags'] as Map) : <String, dynamic>{};

    final amenity = tags['amenity'] as String? ?? tags['emergency'] as String? ?? '';
    final name = tags['name'] as String? ??
        tags['name:en'] as String? ??
        (amenity == 'police'
            ? 'Police Station'
            : amenity == 'hospital'
                ? 'Hospital / Clinic'
                : amenity == 'fire_station'
                    ? 'Fire Station'
                    : 'Emergency Facility');

    final street = tags['addr:street'] as String?;
    final city = tags['addr:city'] as String?;
    final fullAddr = [street, city].where((e) => e != null && e.isNotEmpty).join(', ');

    PlaceType type = PlaceType.generic;
    if (amenity == 'police') {
      type = PlaceType.police;
    } else if (amenity == 'hospital') {
      type = PlaceType.hospital;
    } else if (amenity == 'fire_station') {
      type = PlaceType.fireStation;
    } else if (amenity == 'pharmacy') {
      type = PlaceType.pharmacy;
    }

    double? distance;
    if (userLat != null && userLon != null && lat != 0.0 && lon != 0.0) {
      const distanceCalc = Distance();
      distance = distanceCalc.as(LengthUnit.Kilometer, LatLng(userLat, userLon), LatLng(lat, lon));
    }

    return Place(
      id: '${json['id']}',
      name: name,
      latitude: lat,
      longitude: lon,
      address: fullAddr.isNotEmpty ? fullAddr : tags['address'] as String?,
      phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
      type: type,
      distanceInKm: distance,
      amenityTag: amenity,
      tags: tags,
    );
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'generic';
    final placeType = PlaceType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => PlaceType.generic,
    );

    return Place(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : double.tryParse('${json['latitude']}') ?? 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : double.tryParse('${json['longitude']}') ?? 0.0,
      address: json['address'] as String?,
      type: placeType,
      phone: json['phone'] as String?,
      distanceInKm: (json['distance_in_km'] as num?)?.toDouble(),
      amenityTag: json['amenity_tag'] as String?,
      tags: json['tags'] is Map ? Map<String, dynamic>.from(json['tags'] as Map) : {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'type': type.name,
    'phone': phone,
    'distance_in_km': distanceInKm,
    'amenity_tag': amenityTag,
    'tags': tags,
  };
}
