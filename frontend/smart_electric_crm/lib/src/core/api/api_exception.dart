import 'package:dio/dio.dart';

class ApiException implements Exception {
  static const String networkErrorMessage =
      '\u041d\u0435\u0442 \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f \u043a \u0438\u043d\u0442\u0435\u0440\u043d\u0435\u0442\u0443. \u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0441\u0435\u0442\u044c \u0438 \u043f\u043e\u0432\u0442\u043e\u0440\u0438\u0442\u0435 \u043f\u043e\u043f\u044b\u0442\u043a\u0443.';
  static const String invalidCredentialsMessage =
      '\u041d\u0435\u0432\u0435\u0440\u043d\u044b\u0439 \u043b\u043e\u0433\u0438\u043d \u0438\u043b\u0438 \u043f\u0430\u0440\u043e\u043b\u044c. \u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0434\u0430\u043d\u043d\u044b\u0435 \u0438 \u043f\u043e\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 \u0441\u043d\u043e\u0432\u0430.';
  static const String genericErrorMessage =
      '\u041f\u0440\u043e\u0438\u0437\u043e\u0448\u043b\u0430 \u043e\u0448\u0438\u0431\u043a\u0430. \u041f\u043e\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 \u0435\u0449\u0435 \u0440\u0430\u0437.';
  static const String requestFailedMessage =
      '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0432\u044b\u043f\u043e\u043b\u043d\u0438\u0442\u044c \u0437\u0430\u043f\u0440\u043e\u0441. \u041f\u043e\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 \u0435\u0449\u0435 \u0440\u0430\u0437.';

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
    if (statusCode == 401) {
      if (_looksLikeInvalidCredentials(responseMessage) ||
          responseMessage == null ||
          responseMessage.trim().isEmpty) {
        return invalidCredentialsMessage;
      }

      final trimmed = responseMessage.trim();
      if (!_looksTechnical(trimmed)) {
        return trimmed;
      }
    }

    if (_isNetworkError(error)) {
      return networkErrorMessage;
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
    if (error.response != null) {
      return false;
    }

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
        text.contains('\u043d\u0435\u0432\u0435\u0440\u043d') ||
        text.contains(
            '\u043d\u0435\u043f\u0440\u0430\u0432\u0438\u043b\u044c\u043d') ||
        text.contains('\u0443\u0447\u0435\u0442\u043d');
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
      return genericErrorMessage;
    }
    if (trimmed.toLowerCase().startsWith('failed to ')) {
      return requestFailedMessage;
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
