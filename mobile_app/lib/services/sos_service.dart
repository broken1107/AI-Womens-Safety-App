import 'dart:async';
import '../config/api_endpoints.dart';
import '../models/sos_alert.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class SosTriggerResult {
  const SosTriggerResult({
    required this.alert,
    required this.message,
    this.sentCount = 0,
    this.failedCount = 0,
    this.totalContacts = 0,
  });

  final SOSAlert alert;
  final String message;
  final int sentCount;
  final int failedCount;
  final int totalContacts;
}

class SosService {
  SosService({required this.apiClient});

  final ApiClient apiClient;

  Future<SosTriggerResult> triggerSos({
    required double latitude,
    required double longitude,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.sosTrigger,
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    final body = asJsonMap(response.data);
    final alertMap = body['sos_alert'] is Map ? asJsonMap(body['sos_alert']) : <String, dynamic>{};
    final alert = alertMap.isNotEmpty
        ? SOSAlert.fromJson(alertMap)
        : SOSAlert(
            id: 1,
            latitude: latitude,
            longitude: longitude,
            status: 'active',
            createdAt: DateTime.now(),
          );

    return SosTriggerResult(
      alert: alert,
      message: body['message'] as String? ?? 'Emergency SOS Alert activated.',
      sentCount: body['sent_count'] is int ? body['sent_count'] as int : int.tryParse('${body['sent_count']}') ?? 0,
      failedCount: body['failed_count'] is int ? body['failed_count'] as int : int.tryParse('${body['failed_count']}') ?? 0,
      totalContacts: body['total_contacts'] is int ? body['total_contacts'] as int : int.tryParse('${body['total_contacts']}') ?? 0,
    );
  }

  Future<bool> updateTrackingLocation({
    required dynamic sosId,
    required double latitude,
    required double longitude,
    double? speed,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.sosTrack(sosId),
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'speed': ?speed,
        },
      );
      final body = asJsonMap(response.data);
      return body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resolveSos({
    required dynamic sosId,
    required String verificationCode,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.sosResolve(sosId),
      data: {
        'verification_code': verificationCode,
      },
    );

    final body = asJsonMap(response.data);
    return body['success'] == true;
  }
}
