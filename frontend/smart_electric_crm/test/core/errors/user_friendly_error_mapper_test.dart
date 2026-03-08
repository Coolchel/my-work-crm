import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import 'package:smart_electric_crm/src/core/errors/user_friendly_error_mapper.dart';

void main() {
  group('UserFriendlyErrorMapper', () {
    test('maps 401 ApiException to invalid credentials', () {
      const error = ApiException(
        message: 'No active account found with the given credentials',
        statusCode: 401,
        raw: 'test',
      );

      final message = UserFriendlyErrorMapper.map(error);

      expect(message, ApiException.invalidCredentialsMessage);
    });

    test('maps Dio 401 to invalid credentials before network heuristics', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/auth/token/'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/token/'),
          statusCode: 401,
          data: {
            'detail': 'No active account found with the given credentials',
          },
        ),
        type: DioExceptionType.connectionError,
        error: 'connection error',
        message: 'connection error',
      );

      final message = UserFriendlyErrorMapper.map(error);

      expect(message, ApiException.invalidCredentialsMessage);
    });
  });
}
