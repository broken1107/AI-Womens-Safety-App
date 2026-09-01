import 'package:dio/dio.dart';

import 'json_utils.dart';

/// A user-displayable API failure with optional Laravel validation details.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.validationErrors = const <String, List<String>>{},
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>> validationErrors;
  final bool isNetworkError;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final body = asJsonMap(response?.data);
    final validationErrors = _parseValidationErrors(body['errors']);
    final fallback = switch (statusCode) {
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested item could not be found.',
      422 => validationErrors.values.expand((messages) => messages).join('\n'),
      final code? when code >= 500 =>
        'The server is temporarily unavailable. Please try again.',
      _ => null,
    };
    final networkError = switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => true,
      _ => false,
    };
    final networkMessage =
        error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout
        ? 'The request timed out. Ensure the backend server is running and check your connection settings.'
        : 'Unable to reach the server. Check your internet connection or verify the server IP in Settings.';

    return ApiException(
      message:
          asNullableString(body['message']) ??
          (fallback?.isNotEmpty == true ? fallback! : null) ??
          (networkError
              ? networkMessage
              : 'Something went wrong. Please try again.'),
      statusCode: statusCode,
      validationErrors: validationErrors,
      isNetworkError: networkError,
    );
  }

  static Map<String, List<String>> _parseValidationErrors(Object? rawErrors) {
    final errors = asJsonMap(rawErrors);
    return Map<String, List<String>>.unmodifiable({
      for (final entry in errors.entries)
        entry.key: switch (entry.value) {
          Iterable values =>
            values
                .map((value) => asString(value))
                .where((value) => value.isNotEmpty)
                .toList(growable: false),
          _ => <String>[asString(entry.value)],
        },
    });
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
