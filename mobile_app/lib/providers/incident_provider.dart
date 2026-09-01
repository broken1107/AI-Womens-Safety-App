import 'package:flutter/foundation.dart';
import '../models/incident_report.dart';
import '../services/api_client.dart';
import '../services/incident_service.dart';

class IncidentProvider extends ChangeNotifier {
  IncidentProvider({
    ApiClient? apiClient,
    IncidentService? incidentService,
  }) : _incidentService = incidentService ?? IncidentService(apiClient: apiClient ?? ApiClient());

  final IncidentService _incidentService;

  List<IncidentReport> _incidents = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<IncidentReport> get incidents => List.unmodifiable(_incidents);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> loadIncidents({bool forceRefresh = false}) async {
    if (!forceRefresh && _incidents.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reports = await _incidentService.getIncidents();
      _incidents = reports;
    } catch (_) {
      _errorMessage = 'Could not load incident reports.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitIncident({
    required String title,
    required String description,
    required String category,
    required String area,
    required double latitude,
    required double longitude,
    String? imagePath,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final report = await _incidentService.reportIncident(
        title: title,
        description: description,
        category: category,
        area: area,
        latitude: latitude,
        longitude: longitude,
        imagePath: imagePath,
      );

      _incidents = [report, ..._incidents];
      return true;
    } catch (_) {
      _errorMessage = 'Failed to submit incident report. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
