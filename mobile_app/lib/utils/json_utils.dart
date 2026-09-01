/// Small, defensive JSON conversion helpers used by API models.
///
/// Laravel responses can contain numbers, booleans, and nullable values in
/// slightly different forms depending on the database driver. Keeping those
/// conversions in one place makes the model layer tolerant of that variation.
Map<String, dynamic> asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries
          .where((entry) => entry.key is String)
          .map((entry) => MapEntry(entry.key as String, entry.value)),
    );
  }
  return const <String, dynamic>{};
}

List<dynamic> asJsonList(Object? value) {
  if (value is List<dynamic>) {
    return value;
  }
  if (value is Iterable) {
    return value.toList(growable: false);
  }
  return const <dynamic>[];
}

Object? firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      return json[key];
    }
  }
  return null;
}

String? asNullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final string = value.toString().trim();
  return string.isEmpty ? null : string;
}

String asString(Object? value, {String fallback = ''}) {
  return asNullableString(value) ?? fallback;
}

double? asNullableDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}

double asDouble(Object? value, {double fallback = 0}) {
  return asNullableDouble(value) ?? fallback;
}

int? asNullableInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

int asInt(Object? value, {int fallback = 0}) {
  return asNullableInt(value) ?? fallback;
}

bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  switch (value?.toString().trim().toLowerCase()) {
    case 'true':
    case '1':
    case 'yes':
    case 'on':
      return true;
    case 'false':
    case '0':
    case 'no':
    case 'off':
      return false;
    default:
      return fallback;
  }
}

DateTime? asDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  final text = asNullableString(value);
  return text == null ? null : DateTime.tryParse(text);
}

Map<String, dynamic> asStringKeyedMap(Object? value) => asJsonMap(value);

Map<String, double> asStringDoubleMap(Object? value) {
  final values = asJsonMap(value);
  return Map<String, double>.unmodifiable({
    for (final entry in values.entries)
      entry.key: ?asNullableDouble(entry.value),
  });
}
