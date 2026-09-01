import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_constants.dart';
import '../models/user_location.dart';
import '../services/location_service.dart';
import '../services/nominatim_service.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider({
    LocationService? locationService,
    NominatimService? nominatimService,
  })  : _locationService = locationService ?? LocationService(),
        _nominatimService = nominatimService ?? NominatimService();

  final LocationService _locationService;
  final NominatimService _nominatimService;

  UserLocation? _currentLocation;
  String _currentAddress = 'Fetching current address...';
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _isGpsEnabled = true;
  bool _isPermanentlyDenied = false;
  String? _errorMessage;
  StreamSubscription<UserLocation>? _positionSub;
  bool _isLiveTracking = false;

  UserLocation? get currentLocation => _currentLocation;
  LatLng get currentLatLng => _currentLocation != null
      ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
      : const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);

  String get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  bool get isGpsEnabled => _isGpsEnabled;
  bool get isPermanentlyDenied => _isPermanentlyDenied;
  bool get isLiveTracking => _isLiveTracking;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loc = await _locationService.getCurrentLocation();
      _currentLocation = loc;
      _hasPermission = true;
      _isGpsEnabled = true;
      _isPermanentlyDenied = false;

      // Reverse geocode in background to avoid blocking GPS fix
      _reverseGeocodeCurrent(loc.latitude, loc.longitude);
    } on LocationServiceDisabledException {
      _isGpsEnabled = false;
      _errorMessage = 'Location services (GPS) are disabled. Please enable GPS to use map and safety features.';
    } on LocationPermissionDeniedException {
      _hasPermission = false;
      _errorMessage = 'Location permission was denied. Please grant location access.';
    } on LocationPermissionPermanentlyDeniedException {
      _hasPermission = false;
      _isPermanentlyDenied = true;
      _errorMessage = 'Location permission is permanently denied. Please enable it in Application Settings.';
    } catch (_) {
      _errorMessage = 'Unable to determine GPS location.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reverseGeocodeCurrent(double lat, double lon) async {
    try {
      final addr = await _nominatimService.reverseGeocode(latitude: lat, longitude: lon);
      _currentAddress = addr;
      if (_currentLocation != null) {
        _currentLocation = _currentLocation!.copyWith(address: addr);
      }
      notifyListeners();
    } catch (_) {}
  }

  void startLiveTracking({void Function(UserLocation)? onUpdate}) {
    if (_isLiveTracking) return;
    _isLiveTracking = true;
    _positionSub?.cancel();

    _positionSub = _locationService.getPositionStream().listen(
      (loc) {
        _currentLocation = loc;
        onUpdate?.call(loc);
        notifyListeners();
      },
      onError: (err) {
        _isLiveTracking = false;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void stopLiveTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _isLiveTracking = false;
    notifyListeners();
  }

  Future<bool> openAppSettings() => _locationService.openAppSettings();
  Future<bool> openLocationSettings() => _locationService.openLocationSettings();

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
