import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import 'package:smart_electric_crm/src/features/auth/presentation/login_screen.dart';
import 'package:smart_electric_crm/src/features/auth/presentation/providers/auth_provider.dart';

class _FailingAuthNotifier extends Auth {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  @override
  Future<void> checkAuth() async {}

  @override
  Future<void> login(String username, String password) async {
    state = AuthStatus.error;
    throw const ApiException(
      message: 'No active account found with the given credentials',
      statusCode: 401,
      raw: 'test',
    );
  }
}

void main() {
  testWidgets('LoginScreen shows friendly message for 401 invalid credentials',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_FailingAuthNotifier.new),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test_user',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'test_password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
          'Неверный логин или пароль. Проверьте данные и попробуйте снова.'),
      findsWidgets,
    );
  });
}
