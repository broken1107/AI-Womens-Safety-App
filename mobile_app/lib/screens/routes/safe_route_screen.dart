import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/place.dart';
import '../../models/safe_route.dart';
import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/route_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class SafeRouteScreen extends StatefulWidget {
  const SafeRouteScreen({super.key});

  @override
  State<SafeRouteScreen> createState() => _SafeRouteScreenState();
}

class _SafeRouteScreenState extends State<SafeRouteScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _destFocus = FocusNode();
  Place? _selectedDestination;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapProvider = context.read<MapProvider>();
      if (mapProvider.selectedDestination != null) {
        setState(() {
          _selectedDestination = mapProvider.selectedDestination;
          _destinationController.text = mapProvider.selectedDestination!.name;
        });
        _calculateRoute();
      }
    });
  }

  Future<void> _calculateRoute() async {
    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination first')),
      );
      return;
    }

    final locationProvider = context.read<LocationProvider>();
    final pos = locationProvider.currentLatLng;

    await context.read<RouteProvider>().calculateSafeRoute(
          startLat: pos.latitude,
          startLon: pos.longitude,
          destLat: _selectedDestination!.latitude,
          destLon: _selectedDestination!.longitude,
          origin: Place(
            id: 'current_loc',
            name: locationProvider.currentAddress,
            latitude: pos.latitude,
            longitude: pos.longitude,
          ),
          destination: _selectedDestination,
        );
  }

  void _onSelectSearchPlace(Place place) {
    _destFocus.unfocus();
    setState(() {
      _selectedDestination = place;
      _destinationController.text = place.name;
    });
    context.read<MapProvider>().clearSearch();
    context.read<MapProvider>().selectDestination(place);
    _calculateRoute();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final mapProvider = context.watch<MapProvider>();
    final routeProvider = context.watch<RouteProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeRoute = routeProvider.activeSafeRoute;
    final allRoutes = routeProvider.safeRoutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.safeRoute),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Origin and Destination Selector Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Starting Point (Current Location)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                locationProvider.currentAddress,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, color: AppColors.danger, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _destinationController,
                            focusNode: _destFocus,
                            onChanged: (val) => mapProvider.search(val),
                            decoration: InputDecoration(
                              hintText: 'Enter destination in Tamil Nadu...',
                              hintStyle: const TextStyle(fontSize: 14),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                              suffixIcon: _destinationController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _destinationController.clear();
                                        mapProvider.clearSearch();
                                        setState(() => _selectedDestination = null);
                                        routeProvider.clearRoute();
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Autocomplete Search Results Dropdown
            if (mapProvider.isSearching || mapProvider.searchResults.isNotEmpty)
              Card(
                elevation: 6,
                margin: const EdgeInsets.only(top: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: mapProvider.isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: LoadingWidget(message: 'Searching locations...', size: 22),
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
                              title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(
                                place.address ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () => _onSelectSearchPlace(place),
                            );
                          },
                        ),
                ),
              ),

            const SizedBox(height: 16),

            if (_selectedDestination != null && allRoutes.isEmpty && !routeProvider.isLoading)
              AppButton(
                label: 'Calculate AI Safe Routes',
                icon: Icons.alt_route_rounded,
                onPressed: _calculateRoute,
              ),

            // Loading state
            if (routeProvider.isLoading) ...[
              const SizedBox(height: 40),
              const LoadingWidget(
                message: 'Querying OSRM road geometry & evaluating AI crime risk scores...',
              ),
            ],

            // Error state
            if (routeProvider.errorMessage != null && !routeProvider.isLoading) ...[
              const SizedBox(height: 20),
              AppErrorWidget(
                message: routeProvider.errorMessage!,
                onRetry: _calculateRoute,
              ),
            ],

            // Active Safe Route Card
            if (activeRoute != null && !routeProvider.isLoading) ...[
              const SizedBox(height: 10),
              _buildActiveRouteHero(context, activeRoute),
              const SizedBox(height: 20),

              // Alternative routes selector if available
              if (allRoutes.length > 1) ...[
                Text(
                  'Alternative Routes Evaluated',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...allRoutes.map((r) => _buildRouteOptionTile(context, r, r == activeRoute)),
                const SizedBox(height: 20),
              ],

              // Turn-by-turn Step Preview Card
              if (activeRoute.route.steps.isNotEmpty) ...[
                Text(
                  'Route Safety Directions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeRoute.route.steps.length > 6 ? 6 : activeRoute.route.steps.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final step = activeRoute.route.steps[idx];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        title: Text(step.instruction, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        trailing: Text(
                          step.formattedDistance,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action button to view route polyline on OpenStreetMap
              AppButton(
                label: 'View Route on Interactive Map',
                icon: Icons.map_outlined,
                onPressed: () {
                  Navigator.of(context).pushNamed('/map');
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRouteHero(BuildContext context, SafeRoute route) {
    final isLow = route.risk.isLowRisk;
    final isHigh = route.risk.isHighRisk;
    final badgeColor = isLow ? AppColors.riskLow : (isHigh ? AppColors.riskHigh : AppColors.riskMedium);
    final badgeBg = isLow ? AppColors.riskLowContainer : (isHigh ? AppColors.riskHighContainer : AppColors.riskMediumContainer);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.6), width: 1.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${route.risk.riskLevel} RISK (${route.risk.riskScore.round()}%)',
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (route.isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AI RECOMMENDED',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildMetricBox(context, title: 'Distance', value: route.formattedDistance, icon: Icons.straighten_rounded),
                const SizedBox(width: 12),
                _buildMetricBox(context, title: 'Est. Time', value: route.formattedDuration, icon: Icons.schedule_rounded),
                const SizedBox(width: 12),
                _buildMetricBox(context, title: 'Safety Score', value: '${(100 - route.risk.riskScore).round()}/100', icon: Icons.shield_rounded),
              ],
            ),
            if (route.risk.recommendation != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : const Color(0xFFF6F8FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        route.risk.recommendation!,
                        style: const TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF282835)
              : const Color(0xFFF3F5FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteOptionTile(BuildContext context, SafeRoute route, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () => context.read<RouteProvider>().setActiveRoute(route),
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? AppColors.primary : Colors.grey,
        ),
        title: Text(route.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('${route.formattedDistance} • ${route.formattedDuration}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: route.risk.isLowRisk ? AppColors.riskLowContainer : AppColors.riskMediumContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${route.risk.riskLevel} (${route.risk.riskScore.round()}%)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: route.risk.isLowRisk ? AppColors.riskLow : AppColors.riskMedium,
            ),
          ),
        ),
      ),
    );
  }
}
