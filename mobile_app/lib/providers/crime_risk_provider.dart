import 'package:flutter/foundation.dart';
import '../models/crime_risk.dart';
import '../models/crime_zone.dart';
import '../services/api_client.dart';
import '../services/prediction_service.dart';

class CrimeRiskProvider extends ChangeNotifier {
  CrimeRiskProvider({
    ApiClient? apiClient,
    PredictionService? predictionService,
  }) : _predictionService = predictionService ?? PredictionService(apiClient: apiClient ?? ApiClient());

  final PredictionService _predictionService;

  CrimeRisk? _currentRisk;
  List<CrimeZone> _crimeZones = [];
  int _selectedHour = DateTime.now().hour;
  String _selectedCategory = 'Harassment';
  String _selectedArea = 'Downtown';
  bool _isLoadingRisk = false;
  bool _isLoadingZones = false;
  String? _errorMessage;

  CrimeRisk? get currentRisk => _currentRisk;
  List<CrimeZone> get crimeZones => List.unmodifiable(_crimeZones);
  int get selectedHour => _selectedHour;
  String get selectedCategory => _selectedCategory;
  String get selectedArea => _selectedArea;
  bool get isLoading => _isLoadingRisk || _isLoadingZones;
  String? get errorMessage => _errorMessage;

  Future<void> evaluateRisk({
    required double latitude,
    required double longitude,
    String? area,
    int? hour,
    String? category,
  }) async {
    _isLoadingRisk = true;
    _errorMessage = null;
    if (area != null) _selectedArea = area;
    if (hour != null) _selectedHour = hour;
    if (category != null) _selectedCategory = category;
    notifyListeners();

    try {
      final risk = await _predictionService.predictRisk(
        latitude: latitude,
        longitude: longitude,
        area: _selectedArea,
        hour: _selectedHour,
        crimeCategory: _selectedCategory,
      );
      _currentRisk = risk;
    } catch (_) {
      _errorMessage = 'Could not compute AI crime risk prediction.';
    } finally {
      _isLoadingRisk = false;
      notifyListeners();
    }
  }

  Future<void> loadCrimeZones({
    required double latitude,
    required double longitude,
  }) async {
    _isLoadingZones = true;
    notifyListeners();

    try {
      final zones = await _predictionService.getNearbyCrimeZones(
        latitude: latitude,
        longitude: longitude,
      );
      _crimeZones = zones;
    } catch (_) {
      // Ignored: fallback zones
    } finally {
      _isLoadingZones = false;
      notifyListeners();
    }
  }

  void updateParameters({
    required double latitude,
    required double longitude,
    int? hour,
    String? category,
    String? area,
  }) {
    if (hour != null) _selectedHour = hour;
    if (category != null) _selectedCategory = category;
    if (area != null) _selectedArea = area;
    evaluateRisk(
      latitude: latitude,
      longitude: longitude,
      hour: _selectedHour,
      category: _selectedCategory,
      area: _selectedArea,
    );
  }
}
