import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider({ConnectivityService? connectivityService})
      : _connectivityService = connectivityService ?? ConnectivityService() {
    _init();
  }

  final ConnectivityService _connectivityService;
  bool _isOnline = true;
  StreamSubscription<bool>? _sub;

  bool get isOnline => _isOnline;

  Future<void> _init() async {
    _isOnline = await _connectivityService.isConnected();
    notifyListeners();

    _sub = _connectivityService.onConnectivityChanged.listen((connected) {
      if (_isOnline != connected) {
        _isOnline = connected;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
