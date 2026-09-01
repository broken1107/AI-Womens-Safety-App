import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/amenity_provider.dart';
import '../../providers/location_provider.dart';
import '../../utils/url_actions.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class NearbyPoliceScreen extends StatefulWidget {
  const NearbyPoliceScreen({super.key});

  @override
  State<NearbyPoliceScreen> createState() => _NearbyPoliceScreenState();
}

class _NearbyPoliceScreenState extends State<NearbyPoliceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPolice();
    });
  }

  void _loadPolice({bool forceRefresh = false}) {
    final locationProvider = context.read<LocationProvider>();
    final pos = locationProvider.currentLatLng;
    context.read<AmenityProvider>().fetchNearbyPolice(
          latitude: pos.latitude,
          longitude: pos.longitude,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    final amenityProvider = context.watch<AmenityProvider>();
    final stations = amenityProvider.policeStations;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.nearbyPolice),
        actions: [
          IconButton(
            tooltip: 'Refresh Radar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadPolice(forceRefresh: true),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (amenityProvider.isLoadingPolice && stations.isEmpty) {
            return const LoadingWidget(message: 'Scanning Overpass for police stations within 5 km...');
          }

          if (amenityProvider.errorMessage != null && stations.isEmpty) {
            return AppErrorWidget(
              message: amenityProvider.errorMessage!,
              onRetry: () => _loadPolice(forceRefresh: true),
            );
          }

          if (stations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.policeBlue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_police_outlined, size: 56, color: AppColors.policeBlue),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Police Stations Detected in 5km',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can still directly connect to the National Emergency Police Response via 100 or 112.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.policeBlue),
                      onPressed: () => launchPhoneCall('100'),
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call Police Helpline 100'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadPolice(forceRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: stations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = stations[index];
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
                                color: AppColors.policeBlue.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_police_rounded, color: AppColors.policeBlue),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${p.displayDistance} away • Active Police Radar',
                                    style: const TextStyle(
                                      color: AppColors.policeBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (p.address != null && p.address!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            p.address!,
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
                                onPressed: () => launchPhoneCall(p.phone ?? '100'),
                                icon: const Icon(Icons.call_rounded, color: AppColors.success, size: 18),
                                label: Text('Call (${p.phone ?? '100'})'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => launchMapDirections(p.latitude, p.longitude),
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
