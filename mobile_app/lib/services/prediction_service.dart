import 'dart:async';
import '../config/api_endpoints.dart';
import '../models/crime_risk.dart';
import '../models/crime_zone.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class PredictionService {
  PredictionService({required this.apiClient});

  final ApiClient apiClient;

  // In-memory cache for prediction requests
  final Map<String, CrimeRisk> _cache = {};

  Future<CrimeRisk> predictRisk({
    required double latitude,
    required double longitude,
    String area = 'Downtown',
    int? hour,
    String crimeCategory = 'Harassment',
  }) async {
    final effectiveHour = hour ?? DateTime.now().hour;
    final cacheKey = '${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}_${area}_${effectiveHour}_$crimeCategory';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await apiClient.post(
        ApiEndpoints.predictRisk,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'area': area,
          'hour': effectiveHour,
          'crime_category': crimeCategory,
        },
      );

      final body = asJsonMap(response.data);
      if (body['prediction'] is Map) {
        final predictionJson = asJsonMap(body['prediction']);
        final result = CrimeRisk.fromJson(predictionJson);
        _cache[cacheKey] = result;
        return result;
      }
    } catch (_) {
      // Offline fallback calculation engine
    }

    final fallback = _calculateOfflineRisk(area, effectiveHour, crimeCategory);
    _cache[cacheKey] = fallback;
    return fallback;
  }

  Future<List<CrimeZone>> getNearbyCrimeZones({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    // Generate simulated/clustered hotspot zones around coordinates for Tamil Nadu region
    return [
      CrimeZone(
        id: 1,
        name: 'Market Street Back Alley',
        latitude: latitude + 0.006,
        longitude: longitude + 0.004,
        radius: 450,
        riskScore: 78.0,
        riskLevel: 'HIGH',
        reportedIncidentsCount: 14,
        description: 'Low lighting corridor with recorded night theft and stalking reports.',
      ),
      CrimeZone(
        id: 2,
        name: 'Railway Colony Crossing',
        latitude: latitude - 0.008,
        longitude: longitude + 0.007,
        radius: 600,
        riskScore: 54.0,
        riskLevel: 'MEDIUM',
        reportedIncidentsCount: 8,
        description: 'Moderate pedestrian traffic; exercise caution past 9:00 PM.',
      ),
      CrimeZone(
        id: 3,
        name: 'Town Central Square',
        latitude: latitude + 0.002,
        longitude: longitude - 0.003,
        radius: 350,
        riskScore: 16.0,
        riskLevel: 'LOW',
        reportedIncidentsCount: 1,
        description: 'High visibility CCTV zone with regular police patrol coverage.',
      ),
    ];
  }

  CrimeRisk _calculateOfflineRisk(String area, int hour, String category) {
    double score = 0.15;

    if (area == 'Park/Isolation Zone') {
      score += 0.25;
    } else if (area == 'Industrial Area') {
      score += 0.20;
    } else if (area == 'Downtown') {
      score += 0.10;
    }

    if (hour >= 22 || hour < 4) {
      score += 0.30;
    } else if (hour >= 18 || hour < 7) {
      score += 0.15;
    }

    if (category == 'Assault') {
      score += 0.30;
    } else if (category == 'Stalking') {
      score += 0.22;
    } else if (category == 'Harassment') {
      score += 0.18;
    } else if (category == 'Theft') {
      score += 0.12;
    }

    if (score > 1.0) score = 1.0;
    final percentage = (score * 100).roundToDouble();

    String level;
    String recommendation;

    if (percentage < 35) {
      level = 'LOW';
      recommendation = 'Area exhibits high safety indicators. Standard situational awareness recommended.';
    } else if (percentage < 65) {
      level = 'MEDIUM';
      recommendation = 'Moderate risk detected. Keep emergency contacts ready and stay along lighted avenues.';
    } else {
      level = 'HIGH';
      recommendation = 'Elevated crime risk probability. Avoid walking unaccompanied; consider sharing live GPS.';
    }

    return CrimeRisk(
      riskScore: percentage,
      riskLevel: level,
      probability: score,
      recommendation: recommendation,
      factors: [
        'Time of day: ${hour.toString().padLeft(2, '0')}:00',
        'Area classification: $area',
        'Specific incident category: $category',
      ],
    );
  }
}
