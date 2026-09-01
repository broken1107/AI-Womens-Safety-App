import '../config/api_endpoints.dart';
import '../models/notification_model.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.get(ApiEndpoints.notifications);
    final body = asJsonMap(response.data);
    final rawList = body['notifications'] ?? body['data'];

    final list = <NotificationModel>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          list.add(NotificationModel.fromJson(item));
        } else if (item is Map) {
          list.add(NotificationModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return list;
  }

  Future<bool> markAsRead(String id) async {
    final response = await apiClient.put(ApiEndpoints.notificationRead(id));
    final body = asJsonMap(response.data);
    return body['success'] == true;
  }
}
