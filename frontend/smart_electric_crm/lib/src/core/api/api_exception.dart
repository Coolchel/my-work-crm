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
    final message = _humanizeMessage(
      error: error,
      statusCode: statusCode,
      responseMessage: responseMessage,
      fallbackMessage: fallbackMessage,
    );

    return ApiException(
      message: message,
      statusCode: statusCode,
      raw: error,
    );
  }

  factory ApiException.unknown(
    Object error, {
    required String fallbackMessage,
  }) {
    return ApiException(
      message: _sanitizeFallback(fallbackMessage),
      raw: error,
    );
  }

  static String _humanizeMessage({
    required DioException error,
    required int? statusCode,
    required String? responseMessage,
    required String fallbackMessage,
  }) {
    if (_isNetworkError(error)) {
      return 'Нет подключения к интернету. Проверьте сеть и повторите попытку.';
    }

    if (statusCode == 401 && _looksLikeInvalidCredentials(responseMessage)) {
      return 'Неверный логин или пароль. Проверьте данные и попробуйте снова.';
    }

    if (responseMessage != null) {
      final trimmed = responseMessage.trim();
      if (trimmed.isNotEmpty && !_looksTechnical(trimmed)) {
        return trimmed;
      }
    }

    return _sanitizeFallback(fallbackMessage);
  }

  static bool _isNetworkError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return true;
    }

    final message = error.message?.toLowerCase() ?? '';
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection error') ||
        message.contains('timed out') ||
        message.contains('network is unreachable');
  }

  static bool _looksLikeInvalidCredentials(String? message) {
    if (message == null) return false;
    final text = message.toLowerCase();
    return text.contains('invalid credentials') ||
        text.contains('no active account') ||
        text.contains('неверн') ||
        text.contains('неправильн') ||
        text.contains('учетн');
  }

  static bool _looksTechnical(String message) {
    final text = message.toLowerCase();
    return text.contains('dioexception') ||
        text.contains('socketexception') ||
        text.startsWith('failed to ');
  }

  static String _sanitizeFallback(String fallbackMessage) {
    final trimmed = fallbackMessage.trim();
    if (trimmed.isEmpty || _looksTechnical(trimmed)) {
      return 'Произошла ошибка. Попробуйте еще раз.';
    }
    if (trimmed.toLowerCase().startsWith('failed to ')) {
      return 'Не удалось выполнить запрос. Попробуйте еще раз.';
    }
    return trimmed;
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
  String toString() => message;
}
