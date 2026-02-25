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
}
