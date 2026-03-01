import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import 'package:smart_electric_crm/src/core/errors/user_friendly_error_mapper.dart';

void main() {
  group('UserFriendlyErrorMapper', () {
    test('maps 401 invalid credentials to a friendly message', () {
      const error = ApiException(
        message: 'No active account found with the given credentials',
        statusCode: 401,
        raw: 'test',
      );

      final message = UserFriendlyErrorMapper.map(error);

      expect(message, UserFriendlyErrorMapper.invalidCredentialsMessage);
    });

    test('maps network DioException to a friendly message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/projects/'),
        type: DioExceptionType.connectionError,
        error: const SocketException('Failed host lookup: example.local'),
        message: 'Failed host lookup: example.local',
      );

      final message = UserFriendlyErrorMapper.map(error);

      expect(message, UserFriendlyErrorMapper.networkErrorMessage);
    });
  });
}
