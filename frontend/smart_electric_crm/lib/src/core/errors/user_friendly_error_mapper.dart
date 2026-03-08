import 'dart:io';

import 'package:dio/dio.dart';

import '../api/api_exception.dart';

class UserFriendlyErrorMapper {
  static const String invalidCredentialsMessage =
      ApiException.invalidCredentialsMessage;
  static const String networkErrorMessage = ApiException.networkErrorMessage;
  static const String genericErrorMessage = ApiException.genericErrorMessage;

  static String map(
    Object error, {
    String fallbackMessage = genericErrorMessage,
  }) {
    if (error is ApiException) {
      return _mapApiException(error, fallbackMessage: fallbackMessage);
    }

    if (error is DioException) {
      return _mapDioException(error, fallbackMessage: fallbackMessage);
    }

    if (error is SocketException) {
      return networkErrorMessage;
    }

    return fallbackMessage;
  }

  static String _mapApiException(
    ApiException error, {
    required String fallbackMessage,
  }) {
    if (error.statusCode == 401 ||
        _looksLikeInvalidCredentials(error.message)) {
      return invalidCredentialsMessage;
    }

    if (_looksLikeNetworkIssue(error.message)) {
      return networkErrorMessage;
    }

    return _sanitize(error.message, fallbackMessage: fallbackMessage);
  }

  static String _mapDioException(
    DioException error, {
    required String fallbackMessage,
  }) {
    if (error.response?.statusCode == 401) {
      return invalidCredentialsMessage;
    }

    if (_isNetworkError(error)) {
      return networkErrorMessage;
    }

    final message = _extractResponseMessage(error.response?.data);
    if (message != null) {
      if (_looksLikeInvalidCredentials(message)) {
        return invalidCredentialsMessage;
      }
      return _sanitize(message, fallbackMessage: fallbackMessage);
    }

    return fallbackMessage;
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

    if (error.error is SocketException) {
      return true;
    }

    final message = error.message;
    return message != null && _looksLikeNetworkIssue(message);
  }

  static bool _looksLikeInvalidCredentials(String value) {
    final text = value.toLowerCase();
    return text.contains('invalid credentials') ||
        text.contains('no active account') ||
        text.contains('\u043d\u0435\u0432\u0435\u0440\u043d') ||
        text.contains(
            '\u043d\u0435\u043f\u0440\u0430\u0432\u0438\u043b\u044c\u043d') ||
        text.contains('\u0443\u0447\u0435\u0442\u043d');
  }

  static bool _looksLikeNetworkIssue(String value) {
    final text = value.toLowerCase();
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection error') ||
        text.contains('connection timed out') ||
        text.contains('network is unreachable') ||
        text.contains('network request failed') ||
        text.contains('timed out') ||
        text.contains('\u043d\u0435\u0442 \u0441\u0435\u0442\u0438') ||
        text.contains(
          '\u043d\u0435\u0442 \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f',
        );
  }

  static String? _extractResponseMessage(dynamic data) {
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

  static String _sanitize(
    String message, {
    required String fallbackMessage,
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return fallbackMessage;
    }
    if (_looksLikeTechnicalMessage(trimmed)) {
      return fallbackMessage;
    }
    return trimmed;
  }

  static bool _looksLikeTechnicalMessage(String value) {
    final text = value.toLowerCase();
    return text.contains('dioexception') ||
        text.contains('socketexception') ||
        text.contains('xmlhttprequest') ||
        text.startsWith('failed to ');
  }
}
