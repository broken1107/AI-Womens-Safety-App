import '../config/api_endpoints.dart';
import '../models/user.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class AuthService {
  AuthService({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
    return asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
    return asJsonMap(response.data);
  }

  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Local logout must succeed even if network drops
    }
  }

  Future<User?> getProfile() async {
    final response = await apiClient.get(ApiEndpoints.profile);
    final body = asJsonMap(response.data);
    final userData = body['user'] ?? body['data'];
    if (userData is Map<String, dynamic>) {
      return User.fromJson(userData);
    }
    return null;
  }

  Future<User?> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    final response = await apiClient.put(
      ApiEndpoints.profile,
      data: {
        'name': name,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    final body = asJsonMap(response.data);
    final userData = body['user'] ?? body['data'];
    if (userData is Map<String, dynamic>) {
      return User.fromJson(userData);
    }
    return null;
  }
}
