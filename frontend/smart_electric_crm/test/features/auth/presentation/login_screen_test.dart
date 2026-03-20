import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'LoginScreen shows only inline friendly message for invalid credentials',
    (tester) async {
      await _pumpLoginScreen(
        tester,
        width: 800,
        height: 600,
        platform: TargetPlatform.windows,
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test_user',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test_password',
      );

      final submitButton = find.byType(FilledButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text(ApiException.invalidCredentialsMessage),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets('LoginScreen toggles password visibility', (tester) async {
    await _pumpLoginScreen(
      tester,
      width: 390,
      height: 844,
      platform: TargetPlatform.android,
    );

    final passwordField = tester.widget<EditableText>(
      find.byType(EditableText).at(1),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    final revealedPasswordField = tester.widget<EditableText>(
      find.byType(EditableText).at(1),
    );
    expect(revealedPasswordField.obscureText, isFalse);
  });

  testWidgets('LoginScreen shows desktop support panel on wide layout',
      (tester) async {
    await _pumpLoginScreen(
      tester,
      width: 1280,
      height: 900,
      platform: TargetPlatform.windows,
    );

    expect(find.text('Что понадобится для входа'), findsOneWidget);
    expect(find.text('Рабочий логин'), findsOneWidget);
    expect(find.text('Пароль'), findsNWidgets(2));
  });

  testWidgets('LoginScreen keeps compact mobile layout focused on the form',
      (tester) async {
    await _pumpLoginScreen(
      tester,
      width: 390,
      height: 844,
      platform: TargetPlatform.android,
    );

    expect(find.text('Вход в систему'), findsOneWidget);
    expect(find.text('Что понадобится для входа'), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}

Future<void> _pumpLoginScreen(
  WidgetTester tester, {
  required double width,
  required double height,
  required TargetPlatform platform,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_FailingAuthNotifier.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light().copyWith(platform: platform),
        home: const LoginScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}
