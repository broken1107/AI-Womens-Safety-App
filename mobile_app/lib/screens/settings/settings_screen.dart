import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section: Appearance
          _buildSectionHeader(context, 'Appearance & Display'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_medium_rounded, color: AppColors.primary),
                  title: const Text('App Theme'),
                  subtitle: Text(_getThemeName(settings.themeMode)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showThemeDialog(context, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Emergency SOS Configuration
          _buildSectionHeader(context, 'Emergency SOS & Safety'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer_outlined, color: AppColors.sosRed),
                  title: const Text('SOS Abort Countdown'),
                  subtitle: Text('${settings.sosCountdownDuration} seconds buffer before broadcast'),
                  trailing: DropdownButton<int>(
                    value: settings.sosCountdownDuration,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3s')),
                      DropdownMenuItem(value: 5, child: Text('5s')),
                    ],
                    onChanged: (val) {
                      if (val != null) settings.setCountdownDuration(val);
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.gps_fixed_rounded, color: AppColors.primary),
                  title: const Text('Continuous GPS Live Stream'),
                  subtitle: const Text('Transmit updated coordinates during active SOS alerts'),
                  value: settings.autoShareGps,
                  onChanged: (val) => settings.setAutoShareGps(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_rounded, color: AppColors.primary),
                  title: const Text('Haptic Vibration Feedback'),
                  subtitle: const Text('Vibrate during emergency countdown & risk alerts'),
                  value: settings.vibrationFeedback,
                  onChanged: (val) => settings.setVibrationFeedback(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined, color: AppColors.primary),
                  title: const Text('Audible Emergency Siren'),
                  subtitle: const Text('Play audio notification for high priority crime alerts'),
                  value: settings.soundAlerts,
                  onChanged: (val) => settings.setSoundAlerts(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Device Permissions
          _buildSectionHeader(context, 'Device Permissions'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security_outlined, color: AppColors.secondary),
                  title: const Text('App System Permissions'),
                  subtitle: const Text('Manage Location, Camera, Microphone and SMS access'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => openAppSettings(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: About & Privacy
          _buildSectionHeader(context, 'About Safety Guardian'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  title: Text('App Version'),
                  subtitle: Text('1.0.0 (Build 1) • Production Release'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: const Text('Privacy & Data Protection'),
                  subtitle: const Text('Zero telemetry sold. Locations stored only for user safety.'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Privacy Policy'),
                        content: const Text(
                          'Safety Guardian processes GPS location solely for crime risk calculation, safe route guidance, and emergency SOS broadcasting to your selected contacts. We never share your personal data with third-party advertising networks.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select App Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System Default'),
              leading: Icon(
                settings.themeMode == ThemeMode.system ? Icons.radio_button_checked : Icons.radio_button_off,
                color: settings.themeMode == ThemeMode.system ? AppColors.primary : Colors.grey,
              ),
              onTap: () {
                settings.setThemeMode(ThemeMode.system);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: const Text('Light Mode'),
              leading: Icon(
                settings.themeMode == ThemeMode.light ? Icons.radio_button_checked : Icons.radio_button_off,
                color: settings.themeMode == ThemeMode.light ? AppColors.primary : Colors.grey,
              ),
              onTap: () {
                settings.setThemeMode(ThemeMode.light);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: const Text('Dark Mode'),
              leading: Icon(
                settings.themeMode == ThemeMode.dark ? Icons.radio_button_checked : Icons.radio_button_off,
                color: settings.themeMode == ThemeMode.dark ? AppColors.primary : Colors.grey,
              ),
              onTap: () {
                settings.setThemeMode(ThemeMode.dark);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
