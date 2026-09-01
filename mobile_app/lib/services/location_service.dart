import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../constants/app_constants.dart';
import '../models/user_location.dart';

class LocationService {
  LocationService();

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }

  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  Future<UserLocation> getCurrentLocation() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionPermanentlyDeniedException();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return _positionToUserLocation(position);
    } catch (_) {
      // Fallback to last known position if GPS fix times out
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return _positionToUserLocation(lastKnown);
      }
      // Reference coordinate fallback (Erode, TN)
      return const UserLocation(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        address: 'Erode, Tamil Nadu',
      );
    }
  }

  Stream<UserLocation> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).map(_positionToUserLocation);
  }

  UserLocation _positionToUserLocation(Position pos) {
    return UserLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      altitude: pos.altitude,
      speed: pos.speed,
      heading: pos.heading,
      timestamp: pos.timestamp,
    );
  }
}

class LocationServiceDisabledException implements Exception {
  final String message = 'Location services are disabled on your device. Please turn on GPS.';
  @override
  String toString() => message;
}

class LocationPermissionDeniedException implements Exception {
  final String message = 'Location permission was denied. Please grant location access.';
  @override
  String toString() => message;
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  final String message = 'Location permission is permanently denied. Please enable it in Application Settings.';
  @override
  String toString() => message;
}
