import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/crime_risk.dart';
import '../../models/crime_zone.dart';
import '../../providers/crime_risk_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class CrimeRiskScreen extends StatefulWidget {
  const CrimeRiskScreen({super.key});

  @override
  State<CrimeRiskScreen> createState() => _CrimeRiskScreenState();
}

class _CrimeRiskScreenState extends State<CrimeRiskScreen> {
  final List<String> _categories = ['Harassment', 'Stalking', 'Theft', 'Assault', 'General'];
  final List<String> _areas = ['Downtown', 'Commercial Corridor', 'Park/Isolation Zone', 'Residential', 'Industrial Area'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final locationProvider = context.read<LocationProvider>();
    final pos = locationProvider.currentLatLng;
    final riskProvider = context.read<CrimeRiskProvider>();

    riskProvider.evaluateRisk(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    riskProvider.loadCrimeZones(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM (Midnight)';
    if (hour == 12) return '12:00 PM (Noon)';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }

  @override
  Widget build(BuildContext context) {
    final riskProvider = context.watch<CrimeRiskProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final risk = riskProvider.currentRisk;
    final zones = riskProvider.crimeZones;
    final pos = locationProvider.currentLatLng;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.crimeRisk),
        actions: [
          IconButton(
            tooltip: 'Refresh AI Assessment',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadData(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (riskProvider.isLoading && risk == null) {
            return const LoadingWidget(
              message: 'Analyzing spatio-temporal crime patterns & risk models...',
            );
          }

          if (riskProvider.errorMessage != null && risk == null) {
            return AppErrorWidget(
              message: riskProvider.errorMessage!,
              onRetry: _loadData,
            );
          }

          final effectiveRisk = risk ??
              const CrimeRisk(
                riskScore: 22.0,
                riskLevel: 'LOW',
                recommendation: 'Standard safety protocols recommended for current vicinity.',
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // AI Risk Score Hero Dial
                _buildRiskDial(context, effectiveRisk),
                const SizedBox(height: 20),

                // Temporal Simulation Hour Slider Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Temporal Risk Simulator',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatHour(riskProvider.selectedHour),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: riskProvider.selectedHour.toDouble(),
                          min: 0,
                          max: 23,
                          divisions: 23,
                          label: _formatHour(riskProvider.selectedHour),
                          onChanged: (val) {
                            riskProvider.updateParameters(
                              latitude: pos.latitude,
                              longitude: pos.longitude,
                              hour: val.toInt(),
                            );
                          },
                        ),
                        Text(
                          'Slide to simulate crime probability across different hours of the day.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Area Classification & Category Chips Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incident Category Focus',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((cat) {
                            final isSelected = riskProvider.selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) {
                                riskProvider.updateParameters(
                                  latitude: pos.latitude,
                                  longitude: pos.longitude,
                                  category: cat,
                                );
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        Text(
                          'Vicinity Environment',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: riskProvider.selectedArea,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _areas
                              .map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              riskProvider.updateParameters(
                                latitude: pos.latitude,
                                longitude: pos.longitude,
                                area: val,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // AI Safety Recommendation Box
                if (effectiveRisk.recommendation != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282835) : const Color(0xFFEFF3FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Situational Guidance',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                effectiveRisk.recommendation!,
                                style: const TextStyle(fontSize: 13, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Identified Crime Zones Section
                Text(
                  'Identified Crime Hotspot Zones Nearby',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (zones.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No high density crime zones detected within your immediate 5 km radius.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...zones.map((z) => _buildCrimeZoneCard(context, z)),

                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('View Risk Hotspots on Map'),
                  onPressed: () => Navigator.of(context).pushNamed('/map'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRiskDial(BuildContext context, CrimeRisk risk) {
    final isLow = risk.isLowRisk;
    final isHigh = risk.isHighRisk;
    final color = isLow ? AppColors.riskLow : (isHigh ? AppColors.riskHigh : AppColors.riskMedium);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: (risk.riskScore / 100.0).clamp(0.05, 1.0),
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${risk.riskScore.round()}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${risk.riskLevel} RISK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isLow
                  ? 'Safe Vicinity Detected'
                  : (isHigh ? 'High Crime Vulnerability Area' : 'Moderate Caution Advised'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrimeZoneCard(BuildContext context, CrimeZone zone) {
    final isHigh = zone.isHighRisk;
    final isLow = zone.isLowRisk;
    final color = isLow ? AppColors.riskLow : (isHigh ? AppColors.riskHigh : AppColors.riskMedium);
    final bg = isLow ? AppColors.riskLowContainer : (isHigh ? AppColors.riskHighContainer : AppColors.riskMediumContainer);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          zone.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${zone.riskLevel} (${zone.incidentCount} Incidents)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (zone.description != null && zone.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      zone.description!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
