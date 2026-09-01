import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/place.dart';
import '../../providers/amenity_provider.dart';
import '../../providers/crime_risk_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/route_provider.dart';
import '../../utils/url_actions.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  gmaps.GoogleMapController? _googleMapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Place? _inspectedAmenity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMapLocation();
    });
  }

  Future<void> _initMapLocation() async {
    final locationProvider = context.read<LocationProvider>();
    final amenityProvider = context.read<AmenityProvider>();
    final crimeProvider = context.read<CrimeRiskProvider>();

    await locationProvider.fetchLocation();
    if (mounted && locationProvider.currentLocation != null) {
      final loc = locationProvider.currentLatLng;
      _googleMapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(loc.latitude, loc.longitude),
          15.0,
        ),
      );
      amenityProvider.fetchAllAmenities(latitude: loc.latitude, longitude: loc.longitude);
      crimeProvider.loadCrimeZones(latitude: loc.latitude, longitude: loc.longitude);
      crimeProvider.evaluateRisk(latitude: loc.latitude, longitude: loc.longitude);
    }
  }

  void _zoomIn() {
    _googleMapController?.animateCamera(gmaps.CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _googleMapController?.animateCamera(gmaps.CameraUpdate.zoomOut());
  }

  void _centerOnUser() {
    final locationProvider = context.read<LocationProvider>();
    final userPos = locationProvider.currentLatLng;
    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        gmaps.LatLng(userPos.latitude, userPos.longitude),
        16.0,
      ),
    );
  }

  void _onSelectPlace(Place place) {
    _searchFocusNode.unfocus();
    _searchController.text = place.name;
    context.read<MapProvider>().selectDestination(place);
    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        gmaps.LatLng(place.latitude, place.longitude),
        16.5,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final mapProvider = context.watch<MapProvider>();
    final amenityProvider = context.watch<AmenityProvider>();
    final routeProvider = context.watch<RouteProvider>();
    final crimeProvider = context.watch<CrimeRiskProvider>();

    final userPos = locationProvider.currentLatLng;
    final selectedDest = mapProvider.selectedDestination;
    final activeRoute = routeProvider.activeSafeRoute;
    final crimeZones = crimeProvider.crimeZones;
    final currentRisk = crimeProvider.currentRisk;

    // Google Maps Markers
    final markers = <gmaps.Marker>{
      // Current User Location Marker
      gmaps.Marker(
        markerId: const gmaps.MarkerId('user_current_location'),
        position: gmaps.LatLng(userPos.latitude, userPos.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueViolet),
        infoWindow: gmaps.InfoWindow(
          title: 'You are here',
          snippet: locationProvider.currentAddress,
        ),
      ),
    };

    // Police Station Markers
    for (final police in amenityProvider.policeStations) {
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('police_${police.id}'),
          position: gmaps.LatLng(police.latitude, police.longitude),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
          infoWindow: gmaps.InfoWindow(title: police.name, snippet: police.address ?? 'Police Station'),
          onTap: () => setState(() => _inspectedAmenity = police),
        ),
      );
    }

    // Hospital Markers
    for (final hospital in amenityProvider.hospitals) {
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('hospital_${hospital.id}'),
          position: gmaps.LatLng(hospital.latitude, hospital.longitude),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueCyan),
          infoWindow: gmaps.InfoWindow(title: hospital.name, snippet: hospital.address ?? '24/7 Hospital / Clinic'),
          onTap: () => setState(() => _inspectedAmenity = hospital),
        ),
      );
    }

    // Destination Marker if chosen
    if (selectedDest != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('destination_target'),
          position: gmaps.LatLng(selectedDest.latitude, selectedDest.longitude),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
          infoWindow: gmaps.InfoWindow(
            title: selectedDest.name,
            snippet: selectedDest.address ?? 'Destination',
          ),
        ),
      );
    }

    // Polylines for Active Safe Route
    final polylines = <gmaps.Polyline>{};
    if (activeRoute != null && activeRoute.route.geometryCoordinates.isNotEmpty) {
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('active_safe_route_line'),
          points: activeRoute.route.geometryCoordinates
              .map((c) => gmaps.LatLng(c.latitude, c.longitude))
              .toList(),
          width: 5,
          color: activeRoute.risk.isLowRisk
              ? AppColors.primary
              : (activeRoute.risk.isHighRisk ? AppColors.danger : AppColors.secondary),
        ),
      );
    }

    // Circle Risk Heatmaps for Crime Zones
    final circleRiskZones = <gmaps.Circle>{};
    for (final zone in crimeZones) {
      final isHigh = zone.isHighRisk;
      final isLow = zone.isLowRisk;
      final color = isLow ? AppColors.riskLow : (isHigh ? AppColors.riskHigh : AppColors.riskMedium);

      circleRiskZones.add(
        gmaps.Circle(
          circleId: gmaps.CircleId('crime_zone_${zone.id}'),
          center: gmaps.LatLng(zone.latitude, zone.longitude),
          radius: zone.radiusMeters.toDouble(),
          fillColor: color.withValues(alpha: 0.22),
          strokeColor: color.withValues(alpha: 0.8),
          strokeWidth: 2,
        ),
      );
    }

    final riskBadgeColor = currentRisk?.isHighRisk == true
        ? AppColors.riskHigh
        : (currentRisk?.isMediumRisk == true ? AppColors.riskMedium : AppColors.riskLow);
    final riskBadgeBg = currentRisk?.isHighRisk == true
        ? AppColors.riskHighContainer
        : (currentRisk?.isMediumRisk == true ? AppColors.riskMediumContainer : AppColors.riskLowContainer);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.map),
        actions: [
          IconButton(
            tooltip: 'Refresh Location & Facilities',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _initMapLocation(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Maps Layer
          gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(
              target: gmaps.LatLng(userPos.latitude, userPos.longitude),
              zoom: 15.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            markers: markers,
            polylines: polylines,
            circles: circleRiskZones,
            onMapCreated: (controller) {
              _googleMapController = controller;
            },
            onTap: (_) {
              _searchFocusNode.unfocus();
              mapProvider.clearSearch();
              if (_inspectedAmenity != null) {
                setState(() => _inspectedAmenity = null);
              }
            },
          ),

          // Top Search Field
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (val) => mapProvider.search(val),
                    decoration: InputDecoration(
                      hintText: 'Search hospital, police, location in TN...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                mapProvider.clearSearch();
                                mapProvider.clearDestination();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    ),
                  ),
                ),

                // Search Results Dropdown List
                if (mapProvider.isSearching || mapProvider.searchResults.isNotEmpty)
                  Card(
                    elevation: 6,
                    margin: const EdgeInsets.only(top: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: mapProvider.isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: LoadingWidget(message: 'Searching locations...', size: 24),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: mapProvider.searchResults.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final place = mapProvider.searchResults[idx];
                                return ListTile(
                                  leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                                  title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(
                                    place.address ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onTap: () => _onSelectPlace(place),
                                );
                              },
                            ),
                    ),
                  ),
              ],
            ),
          ),

          // Map Control Floating Buttons (Recenter, Zoom In, Zoom Out)
          Positioned(
            right: 16,
            bottom: activeRoute != null ? 270 : 230,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_recenter_btn',
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: AppColors.primary,
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_in_btn',
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_out_btn',
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove_rounded),
                ),
              ],
            ),
          ),

          // Active Route Floating Information Banner
          if (activeRoute != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 185,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.alt_route_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Safe Route: ${activeRoute.formattedDistance} (${activeRoute.formattedDuration})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Risk Level: ${activeRoute.risk.riskLevel} (${activeRoute.risk.riskScore.round()}%)',
                              style: TextStyle(
                                fontSize: 11,
                                color: activeRoute.risk.isLowRisk ? AppColors.riskLow : AppColors.riskMedium,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Clear Route',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => routeProvider.clearRoute(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Inspected Amenity Popup Modal Card
          if (_inspectedAmenity != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 180,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _inspectedAmenity!.type == PlaceType.police
                                ? Icons.local_police_rounded
                                : Icons.local_hospital_rounded,
                            color: _inspectedAmenity!.type == PlaceType.police
                                ? AppColors.policeBlue
                                : AppColors.hospitalTeal,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _inspectedAmenity!.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => setState(() => _inspectedAmenity = null),
                          ),
                        ],
                      ),
                      if (_inspectedAmenity!.address != null) ...[
                        const SizedBox(height: 4),
                        Text(_inspectedAmenity!.address!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => launchPhoneCall(_inspectedAmenity!.phone ?? '112'),
                              icon: const Icon(Icons.call_rounded, size: 16, color: AppColors.success),
                              label: Text('Call (${_inspectedAmenity!.phone ?? '112'})'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => launchMapDirections(
                                _inspectedAmenity!.latitude,
                                _inspectedAmenity!.longitude,
                              ),
                              icon: const Icon(Icons.directions_rounded, size: 16),
                              label: const Text('Directions'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Sheet with Current Address, Safety Level and Quick Actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedDest != null ? selectedDest.name : locationProvider.currentAddress,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pushNamed('/crime-risk'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: riskBadgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${currentRisk?.riskLevel ?? 'LOW'} RISK (${currentRisk?.riskScore.round() ?? 18}%)',
                              style: TextStyle(
                                color: riskBadgeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed('/police'),
                            icon: const Icon(Icons.local_police_outlined, size: 18),
                            label: Text('Police (${amenityProvider.policeStations.length})'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed('/hospitals'),
                            icon: const Icon(Icons.local_hospital_outlined, size: 18),
                            label: Text('Hospitals (${amenityProvider.hospitals.length})'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.sosRed),
                            onPressed: () => Navigator.of(context).pushNamed('/sos'),
                            icon: const Icon(Icons.emergency_rounded, size: 18),
                            label: const Text('SOS'),
                          ),
                        ),
                      ],
                    ),
                    if (selectedDest != null) ...[
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () => Navigator.of(context).pushNamed('/safe-route'),
                        icon: const Icon(Icons.alt_route_rounded),
                        label: const Text('Get AI Safe Route to Destination'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Error Overlay if GPS is disabled or permission denied
          if (locationProvider.errorMessage != null && !locationProvider.hasPermission && !locationProvider.isLoading)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: AppErrorWidget(
                    title: 'GPS Location Required',
                    message: locationProvider.errorMessage!,
                    icon: Icons.location_off_rounded,
                    retryLabel: locationProvider.isPermanentlyDenied ? 'Open Settings' : 'Grant Permission',
                    onRetry: () async {
                      if (locationProvider.isPermanentlyDenied) {
                        await locationProvider.openAppSettings();
                      } else if (!locationProvider.isGpsEnabled) {
                        await locationProvider.openLocationSettings();
                      } else {
                        await locationProvider.fetchLocation();
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
