import 'dart:io';

import 'package:dio/dio.dart';

import '../api/api_exception.dart';

class UserFriendlyErrorMapper {
  static const String invalidCredentialsMessage =
      'Неверный логин или пароль. Проверьте данные и попробуйте снова.';
  static const String networkErrorMessage =
      'Нет подключения к интернету. Проверьте сеть и повторите попытку.';
  static const String genericErrorMessage =
      'Произошла ошибка. Попробуйте еще раз.';

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
    if (_isNetworkError(error)) {
      return networkErrorMessage;
    }

    if (error.response?.statusCode == 401) {
      return invalidCredentialsMessage;
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
        text.contains('неверн') ||
        text.contains('неправильн') ||
        text.contains('учетн');
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
        text.contains('нет сети') ||
        text.contains('нет подключения');
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
