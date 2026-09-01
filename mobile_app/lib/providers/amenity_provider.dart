import 'package:flutter/foundation.dart';
import '../models/place.dart';
import '../services/overpass_service.dart';

class AmenityProvider extends ChangeNotifier {
  AmenityProvider({OverpassService? overpassService})
      : _overpassService = overpassService ?? OverpassService();

  final OverpassService _overpassService;

  List<Place> _policeStations = [];
  List<Place> _hospitals = [];
  bool _isLoadingPolice = false;
  bool _isLoadingHospitals = false;
  String? _errorMessage;

  List<Place> get policeStations => List.unmodifiable(_policeStations);
  List<Place> get hospitals => List.unmodifiable(_hospitals);
  bool get isLoadingPolice => _isLoadingPolice;
  bool get isLoadingHospitals => _isLoadingHospitals;
  bool get isLoading => _isLoadingPolice || _isLoadingHospitals;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNearbyPolice({
    required double latitude,
    required double longitude,
    int radius = 5000,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _policeStations.isNotEmpty) return;

    _isLoadingPolice = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _overpassService.getNearbyPolice(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius,
      );
      _policeStations = results;
    } catch (_) {
      _errorMessage = 'Could not fetch live police stations from Overpass radar.';
    } finally {
      _isLoadingPolice = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyHospitals({
    required double latitude,
    required double longitude,
    int radius = 5000,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _hospitals.isNotEmpty) return;

    _isLoadingHospitals = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _overpassService.getNearbyHospitals(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius,
      );
      _hospitals = results;
    } catch (_) {
      _errorMessage = 'Could not fetch live hospital facilities from Overpass radar.';
    } finally {
      _isLoadingHospitals = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllAmenities({
    required double latitude,
    required double longitude,
    int radius = 5000,
    bool forceRefresh = false,
  }) async {
    await Future.wait([
      fetchNearbyPolice(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        forceRefresh: forceRefresh,
      ),
      fetchNearbyHospitals(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        forceRefresh: forceRefresh,
      ),
    ]);
  }
}
