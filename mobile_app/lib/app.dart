import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'providers/connectivity_provider.dart';
import 'providers/settings_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class SafetyGuardianApp extends StatelessWidget {
  const SafetyGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider?>();
    final connectivity = context.watch<ConnectivityProvider?>();
    final isOffline = connectivity?.isOnline == false;

    return MaterialApp(
      title: 'Safety Guardian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings?.themeMode ?? ThemeMode.system,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        return Stack(
          children: [
            ?child,
            if (isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: AppColors.warning,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Offline Mode - Using cached emergency data',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
