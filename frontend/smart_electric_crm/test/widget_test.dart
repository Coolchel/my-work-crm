// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_electric_crm/main.dart';
import 'package:smart_electric_crm/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_electric_crm/src/features/auth/presentation/login_screen.dart';

class _TestAuthNotifier extends Auth {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  @override
  Future<void> checkAuth() async {}
}

void main() {
  testWidgets('App opens login screen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_TestAuthNotifier.new),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
