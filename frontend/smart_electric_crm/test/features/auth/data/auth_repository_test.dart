import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import 'package:smart_electric_crm/src/features/auth/data/auth_repository.dart';

import '../../../test_utils/stub_http_client_adapter.dart';

void main() {
  group('AuthRepository.verifyCurrentPassword', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns false on 401', () async {
      final prefs = await SharedPreferences.getInstance();
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = StubHttpClientAdapter((options, _, __) async {
        if (options.path == '/auth/token/') {
          return ResponseBody.fromString(
            jsonEncode({'detail': 'Unauthorized'}),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          '{}',
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final repository = AuthRepository(dio, prefs);
      final result = await repository.verifyCurrentPassword(
        username: 'user',
        password: 'pass',
      );

      expect(result, isFalse);
    });

    test('throws ApiException on non-401 DioException', () async {
      final prefs = await SharedPreferences.getInstance();
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = StubHttpClientAdapter((options, _, __) async {
        if (options.path == '/auth/token/') {
          return ResponseBody.fromString(
            jsonEncode({'detail': 'Server error'}),
            500,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          '{}',
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final repository = AuthRepository(dio, prefs);

      await expectLater(
        () => repository.verifyCurrentPassword(
          username: 'user',
          password: 'pass',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', 'Server error'),
        ),
      );
    });
  });

  group('AuthRepository.refreshToken', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'access_token': 'expired-access',
        'refresh_token': 'expired-refresh',
      });
    });

    test('clears tokens when refresh is rejected', () async {
      final prefs = await SharedPreferences.getInstance();
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      var refreshCalls = 0;
      dio.httpClientAdapter = StubHttpClientAdapter((options, _, __) async {
        if (options.path == '/auth/refresh/') {
          refreshCalls++;
          return ResponseBody.fromString(
            jsonEncode({'detail': 'Token is invalid or expired'}),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          '{}',
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final repository = AuthRepository(dio, prefs);
      final refreshed = await repository.refreshToken();

      expect(refreshed, isFalse);
      expect(refreshCalls, 1);
      expect(repository.getAccessToken(), isNull);
      expect(repository.getRefreshToken(), isNull);
    });

    test('reuses a single in-flight refresh request', () async {
      final prefs = await SharedPreferences.getInstance();
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      var refreshCalls = 0;
      final completer = Completer<ResponseBody>();
      dio.httpClientAdapter = StubHttpClientAdapter((options, _, __) async {
        if (options.path == '/auth/refresh/') {
          refreshCalls++;
          return completer.future;
        }
        return ResponseBody.fromString(
          '{}',
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final repository = AuthRepository(dio, prefs);
      final futureA = repository.refreshToken();
      final futureB = repository.refreshToken();

      completer.complete(
        ResponseBody.fromString(
          jsonEncode({'access': 'fresh-access'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      final results = await Future.wait([futureA, futureB]);

      expect(results, everyElement(isTrue));
      expect(refreshCalls, 1);
      expect(repository.getAccessToken(), 'fresh-access');
      expect(repository.getRefreshToken(), 'expired-refresh');
    });
  });
}
