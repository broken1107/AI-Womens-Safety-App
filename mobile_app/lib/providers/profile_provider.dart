import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/api_exception.dart';
import '../utils/json_utils.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    ApiClient? apiClient,
    AuthService? authService,
  }) : _authService = authService ?? AuthService(apiClient: apiClient ?? ApiClient());

  final AuthService _authService;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _user != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(StorageKeys.cachedProfile);
      if (cached != null) {
        final map = asJsonMap(jsonDecode(cached));
        if (map.isNotEmpty) {
          _user = User.fromJson(map);
          notifyListeners();
        }
      }

      final fresh = await _authService.getProfile();
      if (fresh != null) {
        _user = fresh;
        await prefs.setString(StorageKeys.cachedProfile, jsonEncode(fresh.toJson()));
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

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _authService.updateProfile(
        name: name,
        phone: phone,
        email: email,
      );

      if (updated != null) {
        _user = updated;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(StorageKeys.cachedProfile, jsonEncode(updated.toJson()));
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update profile. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
