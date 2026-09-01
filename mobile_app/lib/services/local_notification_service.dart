import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String emergencyChannelId = 'emergency_sos_channel';
  static const String emergencyChannelName = 'Emergency SOS & High Risk Alerts';
  static const String safetyChannelId = 'safety_updates_channel';
  static const String safetyChannelName = 'Safety & Crime Zone Updates';

  Future<void> initialize({void Function(NotificationResponse)? onSelectNotification}) async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );

    // Create high-priority emergency channel
    const emergencyChannel = AndroidNotificationChannel(
      emergencyChannelId,
      emergencyChannelName,
      description: 'Critical high-priority emergency SOS broadcasts and danger alerts.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(emergencyChannel);
      await androidImplementation.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
    bool isEmergency = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      isEmergency ? emergencyChannelId : safetyChannelId,
      isEmergency ? emergencyChannelName : safetyChannelName,
      importance: isEmergency ? Importance.max : Importance.defaultImportance,
      priority: isEmergency ? Priority.max : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: id == 0 ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  Future<void> showSosNotification({required String title, required String body}) async {
    await showNotification(
      id: 9999,
      title: '🚨 $title',
      body: body,
      isEmergency: true,
      payload: '/sos',
    );
  }

  Future<void> showCrimeRiskNotification({required String title, required String body}) async {
    await showNotification(
      id: 8888,
      title: '⚠️ $title',
      body: body,
      isEmergency: false,
      payload: '/crime-risk',
    );
  }
}
