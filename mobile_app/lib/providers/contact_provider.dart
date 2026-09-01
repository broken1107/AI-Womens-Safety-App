import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../models/emergency_contact.dart';
import '../services/api_client.dart';
import '../services/contact_service.dart';
import '../utils/api_exception.dart';
import '../utils/json_utils.dart';

class ContactProvider extends ChangeNotifier {
  ContactProvider({
    ApiClient? apiClient,
    ContactService? contactService,
  }) : _contactService = contactService ?? ContactService(apiClient: apiClient ?? ApiClient());

  final ContactService _contactService;

  List<EmergencyContact> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get count => _contacts.length;

  EmergencyContact? get primaryContact {
    try {
      return _contacts.firstWhere((c) => c.isPrimary);
    } catch (_) {
      return _contacts.isNotEmpty ? _contacts.first : null;
    }
  }

  Future<void> loadContacts({bool forceRefresh = false}) async {
    if (!forceRefresh && _contacts.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First load from local offline cache
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(StorageKeys.cachedContacts);
      if (cached != null) {
        final decoded = jsonDecode(cached);
        if (decoded is List) {
          _contacts = decoded
              .map((e) => EmergencyContact.fromJson(asJsonMap(e)))
              .toList();
          notifyListeners();
        }
      }

      // Fetch fresh list from server
      final remoteContacts = await _contactService.getContacts();
      _contacts = remoteContacts;

      // Update cache
      final encoded = jsonEncode(_contacts.map((e) => e.toJson()).toList());
      await prefs.setString(StorageKeys.cachedContacts, encoded);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Could not load contacts. Using offline saved list.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addContact({
    required String name,
    required String phone,
    required String relationship,
    bool isTrusted = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newContact = await _contactService.addContact(
        name: name,
        phone: phone,
        relationship: relationship,
        isTrusted: isTrusted,
      );

      _contacts.insert(0, newContact);
      await _persistCache();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to add contact. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateContact({
    required int id,
    String? name,
    String? phone,
    String? relationship,
    bool? isTrusted,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _contactService.updateContact(
        id: id,
        name: name,
        phone: phone,
        relationship: relationship,
        isTrusted: isTrusted,
      );

      final index = _contacts.indexWhere((c) => c.id == id);
      if (index != -1) {
        _contacts[index] = updated;
      }
      await _persistCache();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update contact.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteContact(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _contactService.deleteContact(id);
      _contacts.removeWhere((c) => c.id == id);
      await _persistCache();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to delete contact.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persistCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_contacts.map((e) => e.toJson()).toList());
      await prefs.setString(StorageKeys.cachedContacts, encoded);
    } catch (_) {}
  }
}
