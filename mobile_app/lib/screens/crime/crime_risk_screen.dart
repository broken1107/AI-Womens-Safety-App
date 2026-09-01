import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/crime_risk.dart';

class CrimeRiskScreen extends StatefulWidget {
  const CrimeRiskScreen({super.key});

  @override
  State<CrimeRiskScreen> createState() => _CrimeRiskScreenState();
}

class _CrimeRiskScreenState extends State<CrimeRiskScreen> {
  final CrimeRisk _currentRisk = const CrimeRisk(
    riskLevel: 'LOW',
    riskScore: 18.5,
    probability: 0.185,
    recommendation: 'Area is currently rated safe. Standard situational awareness recommended.',
    factors: [
      'Active street lighting present',
      'Police station within 1.2 km',
      'Low past incident density in last 30 days',
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color riskColor = AppColors.riskLow;
    if (_currentRisk.isHighRisk) {
      riskColor = AppColors.riskHigh;
    } else if (_currentRisk.isMediumRisk) {
      riskColor = AppColors.riskMedium;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.crimeRisk),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI Safety Score Gauge Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: riskColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      AppStrings.aiEstimatedRisk,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: riskColor.withValues(alpha: 0.12),
                        border: Border.all(color: riskColor, width: 4),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_currentRisk.riskScore.round()}%',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: riskColor,
                                  ),
                            ),
                            Text(
                              _currentRisk.riskLevel,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: riskColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentRisk.defaultRecommendation,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // AI Decision Factors
            Text(
              'Contributing Safety Factors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ..._currentRisk.factors.map(
              (f) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                  title: Text(f, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time and Location context
            Card(
              color: isDark ? const Color(0xFF1E2230) : const Color(0xFFEFF4FB),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.mapBlue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI predictions correlate spatio-temporal crime patterns, lighting conditions, and proximity to response stations.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
