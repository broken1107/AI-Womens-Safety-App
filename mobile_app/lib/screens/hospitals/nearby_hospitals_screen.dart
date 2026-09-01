import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/amenity_provider.dart';
import '../../providers/location_provider.dart';
import '../../utils/url_actions.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHospitals();
    });
  }

  void _loadHospitals({bool forceRefresh = false}) {
    final locationProvider = context.read<LocationProvider>();
    final pos = locationProvider.currentLatLng;
    context.read<AmenityProvider>().fetchNearbyHospitals(
          latitude: pos.latitude,
          longitude: pos.longitude,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    final amenityProvider = context.watch<AmenityProvider>();
    final hospitals = amenityProvider.hospitals;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.nearbyHospitals),
        actions: [
          IconButton(
            tooltip: 'Refresh Radar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadHospitals(forceRefresh: true),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (amenityProvider.isLoadingHospitals && hospitals.isEmpty) {
            return const LoadingWidget(message: 'Scanning Overpass for hospitals & clinics within 5 km...');
          }

          if (amenityProvider.errorMessage != null && hospitals.isEmpty) {
            return AppErrorWidget(
              message: amenityProvider.errorMessage!,
              onRetry: () => _loadHospitals(forceRefresh: true),
            );
          }

          if (hospitals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.hospitalTeal.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital_outlined, size: 56, color: AppColors.hospitalTeal),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Hospitals Detected in 5km',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can still directly connect to the National Emergency Medical Ambulance Service via 108.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.hospitalTeal),
                      onPressed: () => launchPhoneCall('108'),
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call Ambulance 108'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadHospitals(forceRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: hospitals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final h = hospitals[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.hospitalTeal.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_hospital_rounded, color: AppColors.hospitalTeal),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${h.displayDistance} away • 24/7 Emergency Care',
                                    style: const TextStyle(
                                      color: AppColors.hospitalTeal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (h.address != null && h.address!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            h.address!,
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => launchPhoneCall(h.phone ?? '108'),
                                icon: const Icon(Icons.call_rounded, color: AppColors.success, size: 18),
                                label: Text('Call (${h.phone ?? '108'})'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => launchMapDirections(h.latitude, h.longitude),
                                icon: const Icon(Icons.directions_rounded, size: 18),
                                label: const Text('Directions'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
