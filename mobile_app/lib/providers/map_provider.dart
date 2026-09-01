import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_constants.dart';
import '../models/place.dart';
import '../services/nominatim_service.dart';

class MapProvider extends ChangeNotifier {
  MapProvider({NominatimService? nominatimService})
      : _nominatimService = nominatimService ?? NominatimService();

  final NominatimService _nominatimService;

  LatLng _mapCenter = const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);
  double _zoom = AppConstants.defaultZoom;
  Place? _selectedDestination;
  List<Place> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  LatLng get mapCenter => _mapCenter;
  double get zoom => _zoom;
  Place? get selectedDestination => _selectedDestination;
  List<Place> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;

  void updateCenter(LatLng newCenter, [double? newZoom]) {
    _mapCenter = newCenter;
    if (newZoom != null) _zoom = newZoom;
    notifyListeners();
  }

  void search(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _debounceTimer = Timer(AppConstants.searchDebounce, () async {
      final results = await _nominatimService.searchLocation(query);
      _searchResults = results;
      _isSearching = false;
      notifyListeners();
    });
  }

  void selectDestination(Place place) {
    _selectedDestination = place;
    _mapCenter = place.coordinates;
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  void clearDestination() {
    _selectedDestination = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
