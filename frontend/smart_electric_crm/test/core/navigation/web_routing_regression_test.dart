import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_electric_crm/main.dart';
import 'package:smart_electric_crm/src/core/navigation/app_router.dart';
import 'package:smart_electric_crm/src/features/auth/data/auth_repository.dart';
import 'package:smart_electric_crm/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/stages/stage_card.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_side_menu.dart';

class _AuthenticatedAuthNotifier extends Auth {
  @override
  AuthStatus build() => AuthStatus.authenticated;

  @override
  Future<void> checkAuth() async {}
}

class _BootstrapAuthNotifier extends Auth {
  @override
  AuthStatus build() => AuthStatus.initial;

  @override
  Future<void> checkAuth() async {
    state = AuthStatus.loading;
    await Future<void>.delayed(Duration.zero);
    state = AuthStatus.authenticated;
  }
}

class _SuccessfulAuthRepository extends AuthRepository {
  // ignore: use_super_parameters
  _SuccessfulAuthRepository(Dio dio, SharedPreferences prefs)
      : _prefs = prefs,
        super(dio, prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> login(String username, String password) async {
    await _prefs.setString('access_token', 'test-access-token');
  }

  @override
  Future<Map<String, dynamic>> getUser() async {
    return <String, dynamic>{'username': 'test-user'};
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  final stage = StageModel(
    id: 10,
    title: 'stage_1',
    status: 'in_progress',
    isPaid: false,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
    showPrices: true,
  );

  final project = ProjectModel(
    id: 1,
    address: 'Test object',
    objectType: 'new_building',
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
    stages: [stage],
  );

  Future<void> pumpWithViewport(
    WidgetTester tester, {
    required Widget child,
    required Size size,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(child);
  }

  testWidgets('keeps project detail route on startup with deep link',
      (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/projects/1?tab=stages&from=%2Fprojects';
    addTearDown(
      () => tester.binding.platformDispatcher.clearAllTestValues(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_AuthenticatedAuthNotifier.new),
          projectByIdProvider('1').overrideWith((ref) async => project),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test object'), findsAtLeastNWidgets(2));
    expect(find.text('Этапы'), findsWidgets);
  });

  testWidgets('keeps global bottom shell on project deep route for Android',
      (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/projects/1';
    addTearDown(
      () => tester.binding.platformDispatcher.clearAllTestValues(),
    );

    await pumpWithViewport(
      tester,
      size: const Size(390, 844),
      child: ProviderScope(
        overrides: [
          authProvider.overrideWith(_AuthenticatedAuthNotifier.new),
          projectListProvider.overrideWith((ref) async => [project]),
          projectByIdProvider('1').overrideWith((ref) async => project),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const ValueKey('project_local_nav')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('project_local_nav_stages')),
      findsOneWidget,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('keeps global desktop shell on project deep route for Windows',
      (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/projects/1';
    addTearDown(
      () => tester.binding.platformDispatcher.clearAllTestValues(),
    );

    await pumpWithViewport(
      tester,
      size: const Size(1440, 1024),
      child: ProviderScope(
        overrides: [
          authProvider.overrideWith(_AuthenticatedAuthNotifier.new),
          projectListProvider.overrideWith((ref) async => [project]),
          projectByIdProvider('1').overrideWith((ref) async => project),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(DesktopSideMenu), findsOneWidget);
    expect(find.byKey(const ValueKey('project_local_nav')), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('updates URL and history for project deep navigation',
      (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/projects';
    addTearDown(
      () => tester.binding.platformDispatcher.clearAllTestValues(),
    );

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_AuthenticatedAuthNotifier.new),
        projectListProvider.overrideWith((ref) async => [project]),
        projectByIdProvider('1').overrideWith((ref) async => project),
        stageByIdProvider(10).overrideWith((ref) async => stage),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/projects');

    await tester.tap(find.text('Test object').first);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/projects/1');

    await tester.tap(find.text(StageCard.getStageTitleDisplay(stage.title)));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/projects/1/estimate/10',
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/projects/1');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/projects');
  });

  testWidgets('reselecting projects in shell returns deep route to branch root',
      (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/projects/1';
    addTearDown(
      () => tester.binding.platformDispatcher.clearAllTestValues(),
    );

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_AuthenticatedAuthNotifier.new),
        projectListProvider.overrideWith((ref) async => [project]),
        projectByIdProvider('1').overrideWith((ref) async => project),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    await pumpWithViewport(
      tester,
      size: const Size(390, 844),
      child: UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/projects/1');

    await tester.tap(find.byIcon(Icons.description).first);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/projects');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('estimate back returns from materials to works then to project',
      (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/projects';
    addTearDown(
      () => tester.binding.platformDispatcher.clearAllTestValues(),
    );

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_AuthenticatedAuthNotifier.new),
        projectListProvider.overrideWith((ref) async => [project]),
        projectByIdProvider('1').overrideWith((ref) async => project),
        stageByIdProvider(10).overrideWith((ref) async => stage),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    await pumpWithViewport(
      tester,
      size: const Size(390, 844),
      child: UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Test object').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(StageCard.getStageTitleDisplay(stage.title)));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        '/projects/1/estimate/10');

    await tester
        .tap(find.byKey(const ValueKey('estimate_local_nav_materials')));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/projects/1/estimate/10',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['tab'],
      'materials',
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path,
        '/projects/1/estimate/10');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/projects/1');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('successful login redirects to home when welcome is enabled',
      (tester) async {
    SharedPreferences.setMockInitialValues(
      <String, Object>{'show_welcome_screen': true},
    );
    final prefs = await SharedPreferences.getInstance();
    final repository = _SuccessfulAuthRepository(
      Dio(BaseOptions(baseUrl: 'http://test.local')),
      prefs,
    );

    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/projects/1?from=%2Fprojects';
    addTearDown(
      () => tester.binding.platformDispatcher.clearAllTestValues(),
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');

    await tester.enterText(find.byType(TextFormField).at(0), 'user');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    final submitButton = find.byType(FilledButton);
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets('successful login redirects to projects when welcome is disabled',
      (tester) async {
    SharedPreferences.setMockInitialValues(
      <String, Object>{'show_welcome_screen': false},
    );
    final prefs = await SharedPreferences.getInstance();
    final repository = _SuccessfulAuthRepository(
      Dio(BaseOptions(baseUrl: 'http://test.local')),
      prefs,
    );

    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/projects/1?from=%2Fprojects';
    addTearDown(
      () => tester.binding.platformDispatcher.clearAllTestValues(),
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');

    await tester.enterText(find.byType(TextFormField).at(0), 'user');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    final submitButton = find.byType(FilledButton);
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/projects');
  });

  testWidgets('keeps estimate route on startup with deep link', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/projects/1/estimate/10?tab=works&from=%2Fprojects%2F1';
    addTearDown(
      () => tester.binding.platformDispatcher.clearAllTestValues(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_AuthenticatedAuthNotifier.new),
          stageByIdProvider(10).overrideWith((ref) async => stage),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Смета'), findsOneWidget);
    expect(find.text('Работы'), findsWidgets);
  });

  testWidgets('keeps deep route after auth bootstrap redirect', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/projects/1/estimate/10?tab=works&from=%2Fprojects%2F1';
    addTearDown(
      () => tester.binding.platformDispatcher.clearAllTestValues(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_BootstrapAuthNotifier.new),
          stageByIdProvider(10).overrideWith((ref) async => stage),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Смета'), findsOneWidget);
    expect(find.text('Работы'), findsWidgets);
  });
}
