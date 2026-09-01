import 'package:latlong2/latlong.dart';

/// Google-compatible encoded polyline utilities.
///
/// Laravel safe-route responses use an encoded overview polyline while OSRM
/// returns GeoJSON coordinates. This utility normalises both to [LatLng].
abstract final class PolylineCodec {
  static List<LatLng> decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return const <LatLng>[];
    }

    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    try {
      while (index < encoded.length) {
        final latitudeDelta = _decodeValue(encoded, () => index++);
        final longitudeDelta = _decodeValue(encoded, () => index++);
        latitude += latitudeDelta;
        longitude += longitudeDelta;
        points.add(LatLng(latitude / 1e5, longitude / 1e5));
      }
    } on RangeError {
      // A malformed route should not crash a map screen. Returning points
      // decoded before the malformed section is more useful than throwing.
    }
    return List<LatLng>.unmodifiable(points);
  }

  static int _decodeValue(String encoded, int Function() advance) {
    var result = 0;
    var shift = 0;
    var byte = 0;
    do {
      final currentIndex = advance();
      byte = encoded.codeUnitAt(currentIndex) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return (result & 1) == 1 ? ~(result >> 1) : (result >> 1);
  }

  static String encode(Iterable<LatLng> points) {
    final buffer = StringBuffer();
    var previousLatitude = 0;
    var previousLongitude = 0;

    for (final point in points) {
      final latitude = (point.latitude * 1e5).round();
      final longitude = (point.longitude * 1e5).round();
      _encodeValue(latitude - previousLatitude, buffer);
      _encodeValue(longitude - previousLongitude, buffer);
      previousLatitude = latitude;
      previousLongitude = longitude;
    }
    return buffer.toString();
  }

  static void _encodeValue(int value, StringBuffer buffer) {
    var encoded = value < 0 ? ~(value << 1) : value << 1;
    while (encoded >= 0x20) {
      buffer.writeCharCode((0x20 | (encoded & 0x1f)) + 63);
      encoded >>= 5;
    }
    buffer.writeCharCode(encoded + 63);
  }

  static List<LatLng> fromGeoJsonCoordinates(Object? rawCoordinates) {
    if (rawCoordinates is! Iterable) {
      return const <LatLng>[];
    }
    final points = <LatLng>[];
    for (final rawPoint in rawCoordinates) {
      if (rawPoint is Iterable) {
        final values = rawPoint.toList(growable: false);
        if (values.length >= 2) {
          final longitude = double.tryParse(values[0].toString());
          final latitude = double.tryParse(values[1].toString());
          if (latitude != null && longitude != null) {
            points.add(LatLng(latitude, longitude));
          }
        }
      }
    }
    return List<LatLng>.unmodifiable(points);
  }

  static List<List<double>> toGeoJsonCoordinates(Iterable<LatLng> points) {
    return points
        .map((point) => <double>[point.longitude, point.latitude])
        .toList(growable: false);
  }
}
