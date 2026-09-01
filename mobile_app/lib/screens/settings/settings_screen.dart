import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showServerConfigDialog(BuildContext context, SettingsProvider settings) {
    _urlController.text = settings.serverBaseUrl;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Server URL'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select your environment or enter your computer\'s IP address:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'http://127.0.0.1:8000/api/',
                  prefixIcon: Icon(Icons.dns_rounded),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Quick Presets:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.usb_rounded, size: 16),
                    label: const Text('USB Phone (127.0.0.1)'),
                    onPressed: () {
                      _urlController.text = 'http://127.0.0.1:8000/api/';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.phone_android_rounded, size: 16),
                    label: const Text('Emulator (10.0.2.2)'),
                    onPressed: () {
                      _urlController.text = 'http://10.0.2.2:8000/api/';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.wifi_rounded, size: 16),
                    label: const Text('Wi-Fi LAN (192.168.7.51)'),
                    onPressed: () {
                      _urlController.text = 'http://192.168.7.51:8000/api/';
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '💡 Note for USB phones: Run `adb reverse tcp:8000 tcp:8000` in your terminal.\n💡 Note for Wi-Fi: Start Laravel with `php artisan serve --host=0.0.0.0 --port=8000`.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newUrl = _urlController.text.trim();
              if (newUrl.isNotEmpty) {
                await settings.setServerBaseUrl(newUrl);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save URL'),
          ),
        ],
      ),
    );
  }

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
          // Section: Backend Server & Network
          _buildSectionHeader(context, 'Backend Server & Network'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary),
                  title: const Text('API Server Endpoint'),
                  subtitle: Text(
                    settings.serverBaseUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.edit_rounded, size: 20),
                  onTap: () => _showServerConfigDialog(context, settings),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: settings.isTestingConnection
                                  ? null
                                  : () => settings.testServerConnection(),
                              icon: settings.isTestingConnection
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.network_check_rounded),
                              label: Text(settings.isTestingConnection ? 'Testing...' : 'Test Server Connection'),
                            ),
                          ),
                        ],
                      ),
                      if (settings.lastConnectionTest != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: settings.lastConnectionTest!.success
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.sosRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: settings.lastConnectionTest!.success
                                  ? AppColors.success
                                  : AppColors.sosRed,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                settings.lastConnectionTest!.success
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                color: settings.lastConnectionTest!.success
                                    ? AppColors.success
                                    : AppColors.sosRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  settings.lastConnectionTest!.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: settings.lastConnectionTest!.success
                                        ? AppColors.success
                                        : AppColors.sosRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
