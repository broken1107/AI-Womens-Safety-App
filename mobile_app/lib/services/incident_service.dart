import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_endpoints.dart';
import '../models/incident_report.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class IncidentService {
  IncidentService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<IncidentReport>> getIncidents() async {
    final response = await apiClient.get(ApiEndpoints.incidents);
    final body = asJsonMap(response.data);

    final incidents = <IncidentReport>[];
    if (body['incidents'] is List) {
      for (final item in body['incidents'] as List) {
        if (item is Map<String, dynamic>) {
          incidents.add(IncidentReport.fromJson(item));
        } else if (item is Map) {
          incidents.add(IncidentReport.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return incidents;
  }

  Future<IncidentReport> reportIncident({
    required String title,
    required String description,
    required String category,
    required String area,
    required double latitude,
    required double longitude,
    String? imagePath,
  }) async {
    MultipartFile? file;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        file = await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last.split('\\').last,
        );
      } catch (_) {}
    }

    final formData = FormData.fromMap({
      'title': title,
      'description': description,
      'category': category,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'image': ?file,
    });

    final response = await apiClient.post(
      ApiEndpoints.incidents,
      data: formData,
    );

    final body = asJsonMap(response.data);
    if (body['incident'] is Map) {
      return IncidentReport.fromJson(asJsonMap(body['incident']));
    }

    return IncidentReport(
      id: 1,
      title: title,
      incidentType: category,
      description: description,
      area: area,
      latitude: latitude,
      longitude: longitude,
      status: 'PENDING',
      createdAt: DateTime.now(),
    );
  }
}
