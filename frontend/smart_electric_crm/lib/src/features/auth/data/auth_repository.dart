import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/base_dio.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final Dio _dio;
  final SharedPreferences _prefs;
  Future<bool>? _ongoingRefresh;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  AuthRepository(this._dio, this._prefs);

  Never _throwApiError(
    Object error,
    StackTrace stackTrace, {
    required String fallbackMessage,
  }) {
    if (error is DioException) {
      throw ApiException.fromDio(error, fallbackMessage: fallbackMessage);
    }
    Error.throwWithStackTrace(error, stackTrace);
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/token/',
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data;
      await _saveTokens(data['access'], data['refresh']);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to login');
    }
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _prefs.setString(_accessTokenKey, access);
    await _prefs.setString(_refreshTokenKey, refresh);
  }

  Future<void> logout() async {
    _ongoingRefresh = null;
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }

  Future<Map<String, dynamic>> getUser() async {
    try {
      final token = getAccessToken();
      final response = await _dio.get(
        '/auth/me/',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      return response.data;
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to fetch user profile');
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final token = getAccessToken();
      await _dio.post(
        '/auth/change-password/',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to change password');
    }
  }

  Future<bool> verifyCurrentPassword({
    required String username,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/auth/token/',
        data: {
          'username': username,
          'password': password,
        },
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return false;
      }
      throw ApiException.fromDio(
        e,
        fallbackMessage: 'Failed to verify current password',
      );
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  String? getAccessToken() {
    return _prefs.getString(_accessTokenKey);
  }

  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<bool> refreshToken() async {
    final pendingRefresh = _ongoingRefresh;
    if (pendingRefresh != null) {
      return pendingRefresh;
    }

    final refreshFuture = _refreshTokenInternal();
    _ongoingRefresh = refreshFuture;
    try {
      return await refreshFuture;
    } finally {
      if (identical(_ongoingRefresh, refreshFuture)) {
        _ongoingRefresh = null;
      }
    }
  }

  Future<bool> _refreshTokenInternal() async {
    final refresh = getRefreshToken();
    if (refresh == null) return false;

    try {
      final response = await _dio.post(
        '/auth/refresh/',
        data: {'refresh': refresh},
      );

      final access = response.data['access'];
      // Some simple implementations just return access, some return both.
      // Usually simple jwt refresh returns access.
      // If the backend returns a new refresh token, we should save it too.
      // But purely based on standard simplejwt:
      await _prefs.setString(_accessTokenKey, access);

      // If the backend allows refresh rotation and returns a new refresh token:
      if (response.data.containsKey('refresh')) {
        await _prefs.setString(_refreshTokenKey, response.data['refresh']);
      }

      return true;
    } catch (e, st) {
      // A rejected refresh token should be invalidated immediately, otherwise
      // multiple listeners/interceptors can keep hammering /auth/refresh/.
      await logout();
      debugPrint('AuthRepository.refreshToken failed: $e\n$st');
      return false;
    }
  }

  bool get isAuthenticated => getAccessToken() != null;
}

@riverpod
Future<AuthRepository> authRepository(Ref ref) async {
  final dio = ref.watch(baseDioProvider);
  final prefs = await SharedPreferences.getInstance();
  return AuthRepository(dio, prefs);
}
