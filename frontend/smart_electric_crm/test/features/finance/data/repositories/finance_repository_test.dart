import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import 'package:smart_electric_crm/src/features/finance/data/repositories/finance_repository.dart';

import '../../../../test_utils/stub_http_client_adapter.dart';

void main() {
  test('FinanceRepository maps DioException to ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    dio.httpClientAdapter = StubHttpClientAdapter((options, _, __) async {
      if (options.path == '/projects/unpaid_projects/') {
        return ResponseBody.fromString(
          jsonEncode({'detail': 'Finance API failed'}),
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

    final repository = FinanceRepository(dio: dio);

    await expectLater(
      () => repository.fetchUnpaidProjects(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'Finance API failed')
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.raw, 'raw', isA<DioException>()),
      ),
    );
  });
}
