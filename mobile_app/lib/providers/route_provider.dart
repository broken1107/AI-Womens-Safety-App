import 'package:flutter/foundation.dart';
import '../models/place.dart';
import '../models/safe_route.dart';
import '../services/api_client.dart';
import '../services/route_service.dart';

class RouteProvider extends ChangeNotifier {
  RouteProvider({
    ApiClient? apiClient,
    RouteService? routeService,
  }) : _routeService = routeService ?? RouteService(apiClient: apiClient ?? ApiClient());

  final RouteService _routeService;

  List<SafeRoute> _safeRoutes = [];
  SafeRoute? _activeSafeRoute;
  Place? _originPlace;
  Place? _destinationPlace;
  bool _isLoading = false;
  String? _errorMessage;

  List<SafeRoute> get safeRoutes => List.unmodifiable(_safeRoutes);
  SafeRoute? get activeSafeRoute => _activeSafeRoute;
  Place? get originPlace => _originPlace;
  Place? get destinationPlace => _destinationPlace;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> calculateSafeRoute({
    required double startLat,
    required double startLon,
    required double destLat,
    required double destLon,
    Place? origin,
    Place? destination,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _originPlace = origin;
    _destinationPlace = destination;
    notifyListeners();

    try {
      final routes = await _routeService.getSafeRoutes(
        startLat: startLat,
        startLon: startLon,
        destLat: destLat,
        destLon: destLon,
      );

      _safeRoutes = routes;
      if (routes.isNotEmpty) {
        // Automatically select the recommended route
        _activeSafeRoute = routes.firstWhere(
          (r) => r.isRecommended,
          orElse: () => routes.first,
        );
      } else {
        _activeSafeRoute = null;
      }
      return true;
    } catch (_) {
      _errorMessage = 'Could not calculate safe route between selected points.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setActiveRoute(SafeRoute route) {
    _activeSafeRoute = route;
    notifyListeners();
  }

  void clearRoute() {
    _safeRoutes = [];
    _activeSafeRoute = null;
    _destinationPlace = null;
    notifyListeners();
  }
}
