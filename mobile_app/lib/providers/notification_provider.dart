import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../models/notification_model.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../utils/api_exception.dart';
import '../utils/json_utils.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    ApiClient? apiClient,
    NotificationService? notificationService,
  }) : _notificationService = notificationService ?? NotificationService(apiClient: apiClient ?? ApiClient());

  final NotificationService _notificationService;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (!forceRefresh && _notifications.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(StorageKeys.cachedNotifications);
      if (cached != null) {
        final decoded = jsonDecode(cached);
        if (decoded is List) {
          _notifications = decoded
              .map((e) => NotificationModel.fromJson(asJsonMap(e)))
              .toList();
          notifyListeners();
        }
      }

      final remoteNotifications = await _notificationService.getNotifications();
      if (remoteNotifications.isNotEmpty) {
        _notifications = remoteNotifications;
        final encoded = jsonEncode(_notifications.map((e) => e.toJson()).toList());
        await prefs.setString(StorageKeys.cachedNotifications, encoded);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      // Offline fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      try {
        await _notificationService.markAsRead(id);
        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(_notifications.map((e) => e.toJson()).toList());
        await prefs.setString(StorageKeys.cachedNotifications, encoded);
      } catch (_) {}
    }
  }

  void addLocalNotification({
    required String title,
    required String body,
    String type = 'SYSTEM',
    Map<String, dynamic> data = const {},
  }) {
    final newNotif = NotificationModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      isRead: false,
      data: data,
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, newNotif);
    notifyListeners();
  }
}
