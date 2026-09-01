import '../config/api_endpoints.dart';
import '../models/emergency_contact.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class ContactService {
  ContactService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<EmergencyContact>> getContacts() async {
    final response = await apiClient.get(ApiEndpoints.contacts);
    final body = asJsonMap(response.data);
    final rawList = body['contacts'] ?? body['data'];

    final contacts = <EmergencyContact>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          contacts.add(EmergencyContact.fromJson(item));
        } else if (item is Map) {
          contacts.add(EmergencyContact.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return contacts;
  }

  Future<EmergencyContact> addContact({
    required String name,
    required String phone,
    required String relationship,
    bool isTrusted = true,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.contacts,
      data: {
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'is_trusted': isTrusted,
      },
    );
    final body = asJsonMap(response.data);
    final rawContact = body['contact'] ?? body['data'];
    if (rawContact is Map<String, dynamic>) {
      return EmergencyContact.fromJson(rawContact);
    }
    return EmergencyContact(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      phone: phone,
      relationship: relationship,
      isPrimary: isTrusted,
    );
  }

  Future<EmergencyContact> updateContact({
    required int id,
    String? name,
    String? phone,
    String? relationship,
    bool? isTrusted,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (relationship != null) data['relationship'] = relationship;
    if (isTrusted != null) data['is_trusted'] = isTrusted;

    final response = await apiClient.put(
      ApiEndpoints.contactDetail(id),
      data: data,
    );
    final body = asJsonMap(response.data);
    final rawContact = body['contact'] ?? body['data'];
    if (rawContact is Map<String, dynamic>) {
      return EmergencyContact.fromJson(rawContact);
    }
    return EmergencyContact(
      id: id,
      name: name ?? '',
      phone: phone ?? '',
      relationship: relationship ?? 'Family',
      isPrimary: isTrusted ?? false,
    );
  }

  Future<bool> deleteContact(int id) async {
    final response = await apiClient.delete(ApiEndpoints.contactDetail(id));
    final body = asJsonMap(response.data);
    return body['success'] == true;
  }
}
