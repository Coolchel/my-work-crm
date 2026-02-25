import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object raw;

  const ApiException({
    required this.message,
    required this.raw,
    this.statusCode,
  });

  factory ApiException.fromDio(
    DioException error, {
    required String fallbackMessage,
  }) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final responseMessage = _extractMessage(responseData);

    return ApiException(
      message: responseMessage ?? fallbackMessage,
      statusCode: statusCode,
      raw: error,
    );
  }

  factory ApiException.unknown(
    Object error, {
    required String fallbackMessage,
  }) {
    return ApiException(
      message: fallbackMessage,
      raw: error,
    );
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }

      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return null;
  }

  @override
  String toString() =>
      'ApiException(message: $message, statusCode: $statusCode, raw: $raw)';
}
