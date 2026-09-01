import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/api_exception.dart';
import '../utils/json_utils.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    ApiClient? apiClient,
    AuthService? authService,
    FlutterSecureStorage? secureStorage,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _authService = authService ?? AuthService(apiClient: apiClient ?? ApiClient());

  final FlutterSecureStorage _secureStorage;
  final AuthService _authService;

  User? _currentUser;
  String? _token;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isRestoring = true;
  bool _isOnboardingComplete = false;

  // Login Challenge State
  String? _loginChallengeId;
  List<String> _availableMethods = [];
  String? _maskedEmail;
  String? _maskedPhone;
  String? _selectedMethod;
  String? _maskedDestination;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get user => _currentUser?.toJson();
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isOnboardingComplete => _isOnboardingComplete;

  String? get loginChallengeId => _loginChallengeId;
  List<String> get availableMethods => _availableMethods;
  String? get maskedEmail => _maskedEmail;
  String? get maskedPhone => _maskedPhone;
  String? get selectedMethod => _selectedMethod;
  String? get maskedDestination => _maskedDestination;

  Future<void> restoreSession() async {
    _isRestoring = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboardingComplete = prefs.getBool(StorageKeys.onboardingComplete) ?? false;

      _token = await _secureStorage.read(key: StorageKeys.authToken);
      if (_token != null && _token!.isNotEmpty) {
        final storedUserJson = prefs.getString(StorageKeys.cachedUser);
        if (storedUserJson != null) {
          final map = asJsonMap(jsonDecode(storedUserJson));
          if (map.isNotEmpty) {
            _currentUser = User.fromJson(map);
          }
        }
        // Fetch fresh profile in background
        _fetchFreshProfile();
      }
    } catch (_) {
      _token = null;
      _currentUser = null;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFreshProfile() async {
    try {
      final user = await _authService.getProfile();
      if (user != null) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(StorageKeys.cachedUser, jsonEncode(user.toJson()));
        notifyListeners();
      }
    } catch (_) {
      // Offline fallback: keep cached profile
    }
  }

  Future<void> completeOnboarding() async {
    _isOnboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingComplete, true);
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final result = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      final token = asNullableString(result['access_token']) ?? asNullableString(result['token']);
      final userMap = asJsonMap(result['user'] ?? result['data']);

      if (token != null && token.isNotEmpty) {
        _token = token;
        _currentUser = userMap.isNotEmpty ? User.fromJson(userMap) : null;
        await _persistSession();
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Registration failed. Please check your connection and try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Initiates login: validates email + password and receives login challenge.
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    _setLoading(true);
    try {
      final result = await _authService.login(email: email, password: password);

      final isOtpRequired = result['otp_required'] == true;
      final challengeId = asNullableString(result['login_challenge_id']);

      if (isOtpRequired && challengeId != null) {
        _loginChallengeId = challengeId;
        _availableMethods = (result['available_methods'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            ['email'];
        _maskedEmail = asNullableString(result['masked_email']);
        _maskedPhone = asNullableString(result['masked_phone']);
        notifyListeners();
        return result;
      }

      final token = asNullableString(result['access_token']) ?? asNullableString(result['token']);
      final userMap = asJsonMap(result['user'] ?? result['data']);

      if (token != null && token.isNotEmpty) {
        _token = token;
        _currentUser = userMap.isNotEmpty ? User.fromJson(userMap) : null;
        if (rememberMe) {
          await _persistSession();
        }
      }
      return result;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Login failed. Please verify credentials and network connection.';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Sends OTP via chosen channel ('email' or 'sms').
  Future<Map<String, dynamic>?> sendLoginOtp({
    required String loginChallengeId,
    required String method,
  }) async {
    _setLoading(true);
    try {
      final result = await _authService.sendLoginOtp(
        loginChallengeId: loginChallengeId,
        method: method,
      );
      _selectedMethod = method;
      _maskedDestination = asNullableString(result['masked_destination']);
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Unable to send verification code. Please try again.';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Verifies 6-digit login OTP and creates authenticated session.
  Future<bool> verifyLoginOtp({
    required String loginChallengeId,
    required String otp,
    bool rememberMe = true,
  }) async {
    _setLoading(true);
    try {
      final result = await _authService.verifyLoginOtp(
        loginChallengeId: loginChallengeId,
        otp: otp,
      );

      final token = asNullableString(result['access_token']) ?? asNullableString(result['token']);
      final userMap = asJsonMap(result['user'] ?? result['data']);

      if (token != null && token.isNotEmpty) {
        _token = token;
        _currentUser = userMap.isNotEmpty ? User.fromJson(userMap) : null;
        if (rememberMe) {
          await _persistSession();
        }
      }
      _clearLoginChallenge();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'OTP verification failed. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Resends login OTP using previously chosen channel.
  Future<Map<String, dynamic>?> resendLoginOtp({
    required String loginChallengeId,
  }) async {
    _setLoading(true);
    try {
      final result = await _authService.resendLoginOtp(
        loginChallengeId: loginChallengeId,
      );
      _maskedDestination = asNullableString(result['masked_destination']);
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Unable to resend verification code. Please try again.';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Legacy / Registration OTP verification.
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    try {
      final result = await _authService.verifyOtp(email: email, otp: otp);
      final token = asNullableString(result['access_token']) ?? asNullableString(result['token']);
      final userMap = asJsonMap(result['user'] ?? result['data']);

      if (token != null && token.isNotEmpty) {
        _token = token;
        _currentUser = userMap.isNotEmpty ? User.fromJson(userMap) : null;
        await _persistSession();
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'OTP verification failed. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    _setLoading(true);
    try {
      final updated = await _authService.updateProfile(
        name: name,
        phone: phone,
        email: email,
      );
      if (updated != null) {
        _currentUser = updated;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(StorageKeys.cachedUser, jsonEncode(updated.toJson()));
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
    } catch (_) {
      // Offline fallback
    } finally {
      await _clearSession();
      _setLoading(false);
    }
  }

  void _clearLoginChallenge() {
    _loginChallengeId = null;
    _availableMethods = [];
    _maskedEmail = null;
    _maskedPhone = null;
    _selectedMethod = null;
    _maskedDestination = null;
  }

  Future<void> _persistSession() async {
    await _secureStorage.write(key: StorageKeys.authToken, value: _token);
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString(StorageKeys.cachedUser, jsonEncode(_currentUser!.toJson()));
    }
  }

  Future<void> _clearSession() async {
    _token = null;
    _currentUser = null;
    _errorMessage = null;
    _clearLoginChallenge();
    await _secureStorage.delete(key: StorageKeys.authToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.cachedUser);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }
}
