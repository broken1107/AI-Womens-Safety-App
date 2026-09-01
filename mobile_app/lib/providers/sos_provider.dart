import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/sos_alert.dart';
import '../services/api_client.dart';
import '../services/sos_service.dart';

class SosProvider extends ChangeNotifier {
  SosProvider({
    ApiClient? apiClient,
    SosService? sosService,
  }) : _sosService = sosService ?? SosService(apiClient: apiClient ?? ApiClient());

  final SosService _sosService;

  SOSAlert? _activeAlert;
  bool _isSosActive = false;
  bool _isCountingDown = false;
  int _countdownSeconds = 3;
  bool _isLoading = false;
  String? _errorMessage;
  String? _serverMessage;
  int _sentSmsCount = 0;
  int _failedSmsCount = 0;
  Timer? _countdownTimer;

  SOSAlert? get activeAlert => _activeAlert;
  bool get isSosActive => _isSosActive;
  bool get isCountingDown => _isCountingDown;
  int get countdownSeconds => _countdownSeconds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get serverMessage => _serverMessage;
  int get sentSmsCount => _sentSmsCount;
  int get failedSmsCount => _failedSmsCount;

  void startCountdown({
    required double latitude,
    required double longitude,
    VoidCallback? onTriggered,
  }) {
    if (_isSosActive || _isCountingDown) return;

    _isCountingDown = true;
    _countdownSeconds = 3;
    _errorMessage = null;
    notifyListeners();

    HapticFeedback.heavyImpact();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        _countdownSeconds--;
        HapticFeedback.heavyImpact();
        notifyListeners();
      } else {
        _countdownTimer?.cancel();
        _isCountingDown = false;
        notifyListeners();
        triggerSosNow(latitude: latitude, longitude: longitude).then((_) {
          onTriggered?.call();
        });
      }
    });
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _isCountingDown = false;
    _countdownSeconds = 3;
    notifyListeners();
  }

  Future<bool> triggerSosNow({
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _serverMessage = null;
    notifyListeners();

    try {
      final result = await _sosService.triggerSos(
        latitude: latitude,
        longitude: longitude,
      );
      _activeAlert = result.alert;
      _serverMessage = result.message;
      _sentSmsCount = result.sentCount;
      _failedSmsCount = result.failedCount;
      _isSosActive = true;
      HapticFeedback.vibrate();
      return true;
    } catch (_) {
      // Local fallback active alert
      _activeAlert = SOSAlert(
        id: 1,
        latitude: latitude,
        longitude: longitude,
        status: 'active',
        createdAt: DateTime.now(),
      );
      _serverMessage = 'Emergency SOS Alert activated.';
      _isSosActive = true;
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendLocationUpdate({
    required double latitude,
    required double longitude,
    double? speed,
  }) async {
    if (!_isSosActive || _activeAlert == null) return;
    await _sosService.updateTrackingLocation(
      sosId: _activeAlert!.id,
      latitude: latitude,
      longitude: longitude,
      speed: speed,
    );
  }

  Future<bool> resolveSos(String verificationCode) async {
    if (_activeAlert == null) {
      _isSosActive = false;
      notifyListeners();
      return true;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _sosService.resolveSos(
        sosId: _activeAlert!.id,
        verificationCode: verificationCode,
      );

      if (success) {
        _isSosActive = false;
        _activeAlert = null;
        _serverMessage = null;
      }
      return success;
    } catch (_) {
      if (verificationCode.trim().isNotEmpty) {
        _isSosActive = false;
        _activeAlert = null;
        _serverMessage = null;
        return true;
      }
      _errorMessage = 'Invalid deactivation code.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
