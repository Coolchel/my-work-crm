import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/api/base_dio.dart';

void main() {
  test('baseDio does not force json content-type for every request', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(baseDioProvider);

    expect(dio.options.headers['Accept'], 'application/json');
    expect(dio.options.headers.containsKey('Content-Type'), isFalse);
  });
}
