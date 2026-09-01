/// Helpers for presenting user data while providers may use different API-model
/// field names (for example, `name` versus `fullName`).
String userDisplayName(dynamic user, {String fallback = 'Safety Guardian'}) {
  return _readUserValue(user, const ['fullName', 'name', 'displayName']) ??
      fallback;
}

String? userEmail(dynamic user) =>
    _readUserValue(user, const ['email', 'emailAddress']);

String? userPhone(dynamic user) =>
    _readUserValue(user, const ['phone', 'phoneNumber', 'mobile']);

String? userAvatarUrl(dynamic user) => _readUserValue(user, const [
  'avatarUrl',
  'profileImage',
  'profileImageUrl',
  'imageUrl',
]);

String? userAddress(dynamic user) =>
    _readUserValue(user, const ['address', 'homeAddress', 'location']);

String? userMedicalInfo(dynamic user) => _readUserValue(user, const [
  'medicalInfo',
  'medicalInformation',
  'emergencyMedicalInfo',
]);

String? providerErrorMessage(dynamic provider) {
  try {
    return _asMeaningfulString(provider.errorMessage);
  } catch (_) {
    return null;
  }
}

bool providerIsLoading(dynamic provider) {
  try {
    return provider.isLoading == true;
  } catch (_) {
    return false;
  }
}

String? _readUserValue(dynamic user, List<String> keys) {
  if (user == null) return null;
  if (user is Map) {
    for (final key in keys) {
      final value = _asMeaningfulString(user[key]);
      if (value != null) return value;
    }
  }

  for (final reader in <dynamic Function()>[
    () => user.fullName,
    () => user.name,
    () => user.displayName,
    () => user.email,
    () => user.emailAddress,
    () => user.phone,
    () => user.phoneNumber,
    () => user.mobile,
    () => user.avatarUrl,
    () => user.profileImage,
    () => user.profileImageUrl,
    () => user.imageUrl,
    () => user.address,
    () => user.homeAddress,
    () => user.location,
    () => user.medicalInfo,
    () => user.medicalInformation,
    () => user.emergencyMedicalInfo,
  ]) {
    try {
      final value = _asMeaningfulString(reader());
      if (value == null) continue;
      final matches = keys.any((key) {
        final lower = key.toLowerCase();
        if (lower.contains('email')) return value.contains('@');
        return true;
      });
      if (matches) return value;
    } catch (_) {
      // The dynamic model does not expose this optional field.
    }
  }
  return null;
}

String? _asMeaningfulString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty || text == 'null' ? null : text;
}
