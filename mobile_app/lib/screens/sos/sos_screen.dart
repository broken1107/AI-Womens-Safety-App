import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/contact_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/sos_provider.dart';
import '../../utils/url_actions.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onSosPressed() {
    final locationProvider = context.read<LocationProvider>();
    final pos = locationProvider.currentLatLng;
    final sosProvider = context.read<SosProvider>();

    sosProvider.startCountdown(
      latitude: pos.latitude,
      longitude: pos.longitude,
      onTriggered: () {
        // Start live location streaming
        locationProvider.startLiveTracking(onUpdate: (loc) {
          sosProvider.sendLocationUpdate(
            latitude: loc.latitude,
            longitude: loc.longitude,
            speed: loc.speed,
          );
        });
      },
    );
  }

  void _showDeactivateDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Emergency SOS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter safety verification code or PIN to confirm you are safe:'),
            const SizedBox(height: 14),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter 4 or 6-digit PIN',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              final code = _pinController.text.trim();
              if (code.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              final sosProvider = context.read<SosProvider>();
              final locProvider = context.read<LocationProvider>();

              final success = await sosProvider.resolveSos(code);
              nav.pop();
              if (success) {
                locProvider.stopLiveTracking();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Emergency SOS resolved. You are marked as safe.')),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(sosProvider.errorMessage ?? 'Deactivation failed')),
                );
              }
            },
            child: const Text('Confirm Safe'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = context.watch<SosProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final contactProvider = context.watch<ContactProvider>();
    final primaryContact = contactProvider.primaryContact;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isActive = sosProvider.isSosActive;
    final isCountingDown = sosProvider.isCountingDown;
    final currentLat = locationProvider.currentLatLng.latitude;
    final currentLon = locationProvider.currentLatLng.longitude;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.sosEmergency),
        backgroundColor: isActive ? AppColors.sosRed : null,
        foregroundColor: isActive ? Colors.white : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.sosRed.withValues(alpha: 0.15)
                    : (isDark ? Colors.white10 : const Color(0xFFF3F5FA)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? AppColors.sosRed : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.sosRed : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'LIVE EMERGENCY BROADCAST ACTIVE' : 'Safety Shield Armed & Monitoring',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isActive ? AppColors.sosRed : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Giant Glowing SOS Button
            Center(
              child: ScaleTransition(
                scale: isActive ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                child: GestureDetector(
                  onTap: isActive ? null : _onSosPressed,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFF334B),
                          AppColors.sosRed,
                          Color(0xFF8A0012),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sosRed.withValues(alpha: isActive ? 0.6 : 0.35),
                          blurRadius: isActive ? 36 : 24,
                          spreadRadius: isActive ? 8 : 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emergency_rounded,
                            size: 52,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isActive ? 'ACTIVE' : 'SOS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          Text(
                            isActive ? 'BROADCASTING' : 'PRESS FOR HELP',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              isActive
                  ? 'Your live GPS coordinates and emergency SMS have been dispatched to registered contacts.'
                  : 'Press and hold to broadcast instant SMS alert with live Google Maps GPS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // SMS Notification Feedback Card when Active
            if (isActive && sosProvider.serverMessage != null) ...[
              Card(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sosProvider.serverMessage!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Current Location Ticker Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Live GPS Location', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            locationProvider.currentAddress,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'https://www.google.com/maps?q=$currentLat,$currentLon',
                            style: const TextStyle(fontSize: 10, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Deactivate Button if SOS Active
            if (isActive) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _showDeactivateDialog,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('I AM SAFE - DEACTIVATE SOS'),
              ),
              const SizedBox(height: 24),
            ],

            // Direct Emergency Helplines Grid
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Direct Emergency Helplines',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildHelplineCard(
                    context,
                    title: 'National (112)',
                    subtitle: 'All Emergencies',
                    phone: '112',
                    color: AppColors.sosRed,
                    icon: Icons.emergency_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildHelplineCard(
                    context,
                    title: 'Women (1091)',
                    subtitle: 'Women Safety',
                    phone: '1091',
                    color: AppColors.primary,
                    icon: Icons.female_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildHelplineCard(
                    context,
                    title: 'Police (100)',
                    subtitle: 'Police Patrol',
                    phone: '100',
                    color: AppColors.policeBlue,
                    icon: Icons.local_police_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildHelplineCard(
                    context,
                    title: 'Ambulance (108)',
                    subtitle: 'Medical Trauma',
                    phone: '108',
                    color: AppColors.hospitalTeal,
                    icon: Icons.local_hospital_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Emergency SMS Broadcast Button to Primary Contact
            if (primaryContact != null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  launchSms(
                    primaryContact.phone,
                    message: '🚨 EMERGENCY ALERT: I have activated an SOS alert. Please contact me immediately. Location: https://www.google.com/maps?q=$currentLat,$currentLon',
                  );
                },
                icon: const Icon(Icons.sms_rounded, color: AppColors.primary),
                label: Text('Direct SMS to ${primaryContact.name}'),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      // 3-second Countdown Modal Sheet
      bottomSheet: isCountingDown
          ? Container(
              color: Colors.black.withValues(alpha: 0.85),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TRIGGERING SOS IN ${sosProvider.countdownSeconds}...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Alerting police and dispatching SMS with Google Maps link to emergency contacts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => sosProvider.cancelCountdown(),
                      child: const Text(
                        'CANCEL (FALSE ALARM)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHelplineCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String phone,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => launchPhoneCall(phone),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
