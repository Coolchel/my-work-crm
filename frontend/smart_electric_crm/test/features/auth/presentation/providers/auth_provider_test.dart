import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import 'package:smart_electric_crm/src/features/auth/data/auth_repository.dart';
import 'package:smart_electric_crm/src/features/auth/presentation/providers/auth_provider.dart';

class _FailingAuthRepository extends AuthRepository {
  _FailingAuthRepository(super.dio, super.prefs, this._error);

  final Object _error;

  @override
  Future<void> login(String username, String password) async {
    throw _error;
  }
}

void main() {
  test('Auth.login sets AuthStatus.error and rethrows error', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const expectedError = ApiException(
      message: 'Invalid credentials',
      statusCode: 401,
      raw: 'test',
    );
    final fakeRepository = _FailingAuthRepository(
      Dio(BaseOptions(baseUrl: 'http://test.local')),
      prefs,
      expectedError,
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((ref) async => fakeRepository),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      () => container.read(authProvider.notifier).login('user', 'pass'),
      throwsA(isA<ApiException>()),
    );

    expect(container.read(authProvider), AuthStatus.error);
  });
}
