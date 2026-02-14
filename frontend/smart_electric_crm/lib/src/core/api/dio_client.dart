import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/data/auth_repository.dart';
import 'base_dio.dart'; // Import baseDio

part 'dio_client.g.dart';

// Main Dio for the app (with Auth Interceptor)
@riverpod
Dio dio(Ref ref) {
  final dio = ref.watch(baseDioProvider); // Start with base config

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
