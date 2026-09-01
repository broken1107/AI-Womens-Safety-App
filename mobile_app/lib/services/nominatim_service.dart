import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/place.dart';
import '../utils/json_utils.dart';

class NominatimService {
  NominatimService({Dio? client})
      : _client = client ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.nominatimBaseUrl,
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'User-Agent': AppConfig.userAgent,
                  'Accept': 'application/json',
                },
              ),
            );

  final Dio _client;

  // In-memory cache to respect Nominatim rate limit policies
  final Map<String, String> _reverseCache = {};
  final Map<String, List<Place>> _searchCache = {};

  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    // Round to 4 decimal places for caching (~11 meters precision)
    final cacheKey = '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(cacheKey)) {
      return _reverseCache[cacheKey]!;
    }

    try {
      final response = await _client.get(
        '/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'json',
          'addressdetails': 1,
        },
      );

      final body = asJsonMap(response.data);
      final displayName = body['display_name'] as String?;

      if (displayName != null && displayName.isNotEmpty) {
        _reverseCache[cacheKey] = displayName;
        return displayName;
      }

      final address = body['address'] is Map ? body['address'] as Map : {};
      final road = address['road'] as String?;
      final suburb = address['suburb'] as String? ?? address['neighbourhood'] as String?;
      final city = address['city'] as String? ?? address['town'] as String? ?? address['county'] as String?;

      final formatted = [road, suburb, city].where((e) => e != null && e.isNotEmpty).join(', ');
      final result = formatted.isNotEmpty ? formatted : 'Lat: $latitude, Lon: $longitude';
      _reverseCache[cacheKey] = result;
      return result;
    } catch (_) {
      return 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }

  Future<List<Place>> searchLocation(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    if (_searchCache.containsKey(trimmed)) {
      return _searchCache[trimmed]!;
    }

    try {
      final response = await _client.get(
        '/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 6,
        },
      );

      final places = <Place>[];
      if (response.data is List) {
        for (final item in response.data as List) {
          if (item is Map<String, dynamic>) {
            places.add(Place.fromNominatim(item));
          } else if (item is Map) {
            places.add(Place.fromNominatim(Map<String, dynamic>.from(item)));
          }
        }
      }

      _searchCache[trimmed] = places;
      return places;
    } catch (_) {
      return [];
    }
  }
}
