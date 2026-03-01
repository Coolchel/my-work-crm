import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';

void main() {
  group('ApiException.fromDio', () {
    DioException buildException({
      required int statusCode,
      required dynamic data,
    }) {
      final requestOptions = RequestOptions(path: '/test');
      final response = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: statusCode,
        data: data,
      );
      return DioException(
        requestOptions: requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }

    test('uses response.data.detail as message', () {
      final error = buildException(
        statusCode: 400,
        data: {'detail': 'Detail message', 'message': 'Fallback message'},
      );

      final result =
          ApiException.fromDio(error, fallbackMessage: 'Default message');

      expect(result.message, 'Detail message');
      expect(result.statusCode, 400);
      expect(result.raw, error);
    });

    test('uses response.data.message when detail is absent', () {
      final error = buildException(
        statusCode: 422,
        data: {'message': 'Message field'},
      );

      final result =
          ApiException.fromDio(error, fallbackMessage: 'Default message');

      expect(result.message, 'Message field');
      expect(result.statusCode, 422);
      expect(result.raw, error);
    });

    test('uses fallbackMessage when detail/message are absent', () {
      final error = buildException(
        statusCode: 500,
        data: {'error': 'Unknown'},
      );

      final result =
          ApiException.fromDio(error, fallbackMessage: 'Default message');

      expect(result.message, 'Default message');
      expect(result.statusCode, 500);
      expect(result.raw, error);
    });

    test('maps network error to friendly message', () {
      final requestOptions = RequestOptions(path: '/test');
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        message: 'Failed host lookup: test.local',
      );

      final result =
          ApiException.fromDio(error, fallbackMessage: 'Failed to fetch data');

      expect(
        result.message,
        'Нет подключения к интернету. Проверьте сеть и повторите попытку.',
      );
    });

    test('toString returns user message without technical details', () {
      const exception = ApiException(
        message: 'Понятная ошибка',
        raw: 'raw',
        statusCode: 500,
      );

      expect(exception.toString(), 'Понятная ошибка');
    });
  });
}
