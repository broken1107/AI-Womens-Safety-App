import 'package:url_launcher/url_launcher.dart';

abstract final class UrlActions {
  static Future<bool> call(String phoneNumber) {
    return _launch(Uri(scheme: 'tel', path: phoneNumber));
  }

  static Future<bool> sendSms(String phoneNumber, {String? message}) {
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: message == null || message.isEmpty
          ? null
          : <String, String>{'body': message},
    );
    return _launch(uri);
  }

  static Future<bool> openOsmDirections({
    required double latitude,
    required double longitude,
  }) {
    return _launch(
      Uri.parse(
        'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=17/$latitude/$longitude',
      ),
    );
  }

  static Future<bool> _launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<bool> launchPhoneCall(String phoneNumber) => UrlActions.call(phoneNumber);

Future<bool> launchSms(String phoneNumber, {String? message}) =>
    UrlActions.sendSms(phoneNumber, message: message);

Future<bool> launchMapDirections(double latitude, double longitude) =>
    UrlActions.openOsmDirections(latitude: latitude, longitude: longitude);
