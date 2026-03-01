import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/auth/data/auth_repository.dart';
import 'base_dio.dart'; // Import baseDio

part 'dio_client.g.dart';

// Main Dio for the app (with Auth Interceptor)
@riverpod
Dio dio(Ref ref) {
  final dio = ref.watch(baseDioProvider); // Start with base config

  dio.interceptors.add(SafeGetRetryInterceptor(ref));
  // Add Auth Interceptor
  dio.interceptors.add(AuthInterceptor(ref));

  return dio;
}

class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Determine if we need to add token
    // For now, add to all requests except auth/* which are handled by baseDio anyway if using AuthRepo correctly.
    // But since 'dio' wraps 'baseDio', if we use 'dio' for auth requests, we might have issues?
    // AuthRepository should use 'baseDio', so 'dio' shouldn't see login/refresh requests usually.
    // But if we do, we can filter.
    if (options.path.contains('/auth/')) {
      return handler.next(options);
    }

    // Get token from AuthRepository (or SharedPreferences directly if Repo is async/unavailable)
    // Accessing AuthRepo might trigger a build if we are not careful, but we are in a method.
    // 'authRepositoryProvider' is a FutureProvider.
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final token = repo.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // ignore or log
    }

    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try refresh
      try {
        final repo = await ref.read(authRepositoryProvider.future);
        final success = await repo.refreshToken();

        if (success) {
          final newToken = repo.getAccessToken();
          // Retry request
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';

          // We need a dio instance to retry.
          // We can use the one from err.requestOptions or create new.
          // BE CAREFUL: referencing 'ref.read(dioProvider)' might be recursive?
          // Use baseDio for retry? No, baseDio has no interceptor.
          // Actually, we can just use a new Dio or 'baseDio' but manually add header.

          final retryDio = Dio(BaseOptions(
            baseUrl: opts.baseUrl,
            headers: opts.headers, // Includes new token
          ));

          final response = await retryDio.request(
            opts.path,
            data: opts.data,
            queryParameters: opts.queryParameters,
            options: Options(
              method: opts.method,
              headers: opts.headers,
            ),
          );

          return handler.resolve(response);
        } else {
          // Refresh failed, logout
          await repo.logout();
        }
      } catch (e) {
        // processing error
      }
    }
    super.onError(err, handler);
  }
}

class SafeGetRetryInterceptor extends Interceptor {
  SafeGetRetryInterceptor(this.ref);

  final Ref ref;
  final Connectivity _connectivity = Connectivity();

  static const String _retryCountKey = 'safe_get_retry_count';
  static const int _maxRetries = 1;

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      return super.onError(err, handler);
    }

    final options = err.requestOptions;
    final retries = (options.extra[_retryCountKey] as int?) ?? 0;
    if (retries >= _maxRetries) {
      return super.onError(err, handler);
    }

    options.extra[_retryCountKey] = retries + 1;

    try {
      final hasConnection = await _waitForConnection();
      if (!hasConnection) {
        return super.onError(err, handler);
      }

      // Small delay to let socket stack stabilize after reconnect.
      await Future<void>.delayed(const Duration(milliseconds: 250));

      final retryDio = ref.read(baseDioProvider);
      final response = await retryDio.fetch(options);
      return handler.resolve(response);
    } catch (_) {
      return super.onError(err, handler);
    }
  }

  bool _shouldRetry(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    if (method != 'GET') {
      return false;
    }

    if (err.requestOptions.path.contains('/auth/')) {
      return false;
    }

    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;
  }

  Future<bool> _waitForConnection() async {
    final current = await _connectivity.checkConnectivity();
    if (_hasConnection(current)) {
      return true;
    }

    try {
      await _connectivity.onConnectivityChanged
          .firstWhere(_hasConnection)
          .timeout(const Duration(seconds: 20));
      return true;
    } on TimeoutException {
      return false;
    }
  }

  bool _hasConnection(dynamic value) {
    if (value is ConnectivityResult) {
      return value != ConnectivityResult.none;
    }
    if (value is List<ConnectivityResult>) {
      return value.any((item) => item != ConnectivityResult.none);
    }
    if (value is Iterable<ConnectivityResult>) {
      return value.any((item) => item != ConnectivityResult.none);
    }
    return false;
  }
}
