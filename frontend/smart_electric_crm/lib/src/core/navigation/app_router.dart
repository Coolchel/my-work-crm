import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/catalog/presentation/category_list_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/projects/presentation/providers/project_providers.dart';
import '../../features/projects/presentation/screens/estimate_screen.dart';
import '../../features/projects/presentation/screens/file_viewer_screen.dart';
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/projects/presentation/screens/project_list_screen.dart';
import '../../features/settings/application/app_settings_controller.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import 'app_navigation.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen<AuthStatus>(authProvider, (_, __) => refreshNotifier.refresh());
  ref.listen<AppSettingsState>(
    appSettingsProvider,
    (_, __) => refreshNotifier.refresh(),
  );
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: AppNavigation.homePath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authStatus = ref.read(authProvider);
      final settings = ref.read(appSettingsProvider);
      final location = state.uri.toString();
      final matchedLocation = state.matchedLocation;
      final isAuthRoute = matchedLocation == AppNavigation.loginPath ||
          matchedLocation == AppNavigation.loadingPath;

      if (authStatus == AuthStatus.initial ||
          authStatus == AuthStatus.loading) {
        if (matchedLocation == AppNavigation.loadingPath) {
          return null;
        }
        return _withFrom(
          AppNavigation.loadingPath,
          location,
        );
      }

      if (authStatus == AuthStatus.unauthenticated ||
          authStatus == AuthStatus.error) {
        if (matchedLocation == AppNavigation.loginPath) {
          return null;
        }
        final requestedLocation = state.uri.queryParameters['from'] ?? location;
        return _withFrom(
          AppNavigation.loginPath,
          requestedLocation,
        );
      }

      if (isAuthRoute) {
        final from = state.uri.queryParameters['from'];
        return _sanitizeAuthenticatedTarget(from, settings);
      }

      if (!settings.showWelcome && matchedLocation == AppNavigation.homePath) {
        return AppNavigation.projectsPath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppNavigation.loadingPath,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: _BlockedRootScreen(
            child: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppNavigation.loginPath,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: _BlockedRootScreen(child: LoginScreen()),
        ),
      ),
      GoRoute(
        path: '${AppNavigation.projectsPath}/:projectId/estimate/:stageId',
        pageBuilder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          final stageId = int.tryParse(state.pathParameters['stageId']!);
          final from = state.uri.queryParameters['from'];
          final initialTab = AppNavigation.estimateSectionFromName(
            state.uri.queryParameters['tab'],
          );

          return NoTransitionPage<void>(
            key: ValueKey(
                'estimate:$projectId:${state.pathParameters['stageId']}'),
            child: _EstimateRouteScreen(
              projectId: projectId,
              stageId: stageId,
              from: from,
              initialTab: initialTab,
            ),
          );
        },
      ),
      GoRoute(
        path: '${AppNavigation.projectsPath}/:projectId',
        pageBuilder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          final from = state.uri.queryParameters['from'];
          final initialTab = AppNavigation.projectDetailSectionFromName(
            state.uri.queryParameters['tab'],
          );

          return NoTransitionPage<void>(
            key: ValueKey('project:$projectId'),
            child: _ProjectDetailRouteScreen(
              projectId: projectId,
              from: from,
              initialTab: initialTab,
            ),
          );
        },
      ),
      GoRoute(
        path: AppNavigation.catalogPath,
        pageBuilder: (context, state) {
          final from = state.uri.queryParameters['from'];
          final initialTab = AppNavigation.catalogSectionFromName(
            state.uri.queryParameters['tab'],
          );

          return NoTransitionPage<void>(
            key: const ValueKey('catalog'),
            child: _CatalogRouteScreen(
              from: from,
              initialTab: initialTab,
            ),
          );
        },
      ),
      GoRoute(
        path: AppNavigation.fileViewerPath,
        pageBuilder: (context, state) {
          final url = state.uri.queryParameters['url'];
          final title = state.uri.queryParameters['title'];
          final from = state.uri.queryParameters['from'];

          return NoTransitionPage<void>(
            key: ValueKey('file-viewer:${url ?? ''}:${title ?? ''}'),
            child: _FileViewerRouteScreen(
              url: url,
              title: title,
              from: from,
            ),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppNavigation.homePath,
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: _WelcomeBranchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppNavigation.projectsPath,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: _ProjectsBranchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppNavigation.financePath,
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: _FinanceBranchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppNavigation.statisticsPath,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: _StatisticsBranchScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppNavigation.settingsPath,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: _SettingsBranchScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Страница не найдена: ${state.uri}'),
          ),
        ),
      );
    },
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

String _withFrom(String path, String from) {
  return Uri(
    path: path,
    queryParameters: <String, String>{'from': from},
  ).toString();
}

String _sanitizeAuthenticatedTarget(
  String? from,
  AppSettingsState settings,
) {
  final fallback = settings.showWelcome
      ? AppNavigation.homePath
      : AppNavigation.projectsPath;
  if (from == null || from.isEmpty) {
    return fallback;
  }

  final uri = Uri.tryParse(from);
  if (uri == null) {
    return fallback;
  }

  final targetPath = uri.path.isEmpty ? AppNavigation.homePath : uri.path;
  if (targetPath == AppNavigation.loginPath ||
      targetPath == AppNavigation.loadingPath) {
    return fallback;
  }

  if (!settings.showWelcome && targetPath == AppNavigation.homePath) {
    return AppNavigation.projectsPath;
  }

  return uri.toString();
}

String _settingsBackLocation(bool showWelcome) {
  final lastSection = AppNavigation.lastNonSettingsSection;
  if (!showWelcome && lastSection == AppShellSection.home) {
    return AppNavigation.projectsPath;
  }
  return AppNavigation.locationForShellSection(lastSection);
}

class _BlockedRootScreen extends StatelessWidget {
  const _BlockedRootScreen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: child,
    );
  }
}

class _WelcomeBranchScreen extends StatelessWidget {
  const _WelcomeBranchScreen();

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      onSettingsPressed: () =>
          AppNavigation.goToShellSection(context, AppShellSection.settings),
      scrollController: AppNavigation.homeScrollController,
    );
  }
}

class _ProjectsBranchScreen extends ConsumerWidget {
  const _ProjectsBranchScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showWelcome = ref.watch(
      appSettingsProvider.select((value) => value.showWelcome),
    );

    return ProjectListScreen(
      onBackPressed:
          showWelcome ? () => AppNavigation.goHome(scrollToTop: false) : null,
    );
  }
}

class _FinanceBranchScreen extends ConsumerWidget {
  const _FinanceBranchScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showWelcome = ref.watch(
      appSettingsProvider.select((value) => value.showWelcome),
    );

    return FinanceScreen(
      onBackPressed:
          showWelcome ? () => AppNavigation.goHome(scrollToTop: false) : null,
    );
  }
}

class _StatisticsBranchScreen extends ConsumerWidget {
  const _StatisticsBranchScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showWelcome = ref.watch(
      appSettingsProvider.select((value) => value.showWelcome),
    );

    return StatisticsScreen(
      onBackPressed:
          showWelcome ? () => AppNavigation.goHome(scrollToTop: false) : null,
    );
  }
}

class _SettingsBranchScreen extends ConsumerWidget {
  const _SettingsBranchScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showWelcome = ref.watch(
      appSettingsProvider.select((value) => value.showWelcome),
    );

    return SettingsScreen(
      onBackPressed: () => context.go(_settingsBackLocation(showWelcome)),
    );
  }
}

class _ProjectDetailRouteScreen extends StatelessWidget {
  const _ProjectDetailRouteScreen({
    required this.projectId,
    required this.from,
    required this.initialTab,
  });

  final String projectId;
  final String? from;
  final ProjectDetailSection initialTab;

  @override
  Widget build(BuildContext context) {
    return ProjectDetailScreen(
      projectId: projectId,
      initialTab: initialTab,
      onBackPressed: () => context.go(from ?? AppNavigation.projectsPath),
      onTabChanged: (tab) {
        context.go(
          AppNavigation.projectLocation(
            projectId,
            tab: tab,
            from: from,
          ),
        );
      },
    );
  }
}

class _EstimateRouteScreen extends ConsumerWidget {
  const _EstimateRouteScreen({
    required this.projectId,
    required this.stageId,
    required this.from,
    required this.initialTab,
  });

  final String projectId;
  final int? stageId;
  final String? from;
  final EstimateSection initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stageId == null) {
      return const _RouteErrorScreen(
          message: 'Некорректный идентификатор этапа.');
    }

    final stageAsync = ref.watch(stageByIdProvider(stageId!));
    return stageAsync.when(
      data: (stage) => EstimateScreen(
        projectId: projectId,
        stage: stage,
        initialTab: initialTab,
        onBackPressed: () => context.go(
          from ?? AppNavigation.projectLocation(projectId),
        ),
        onTabChanged: (tab) {
          context.go(
            AppNavigation.estimateLocation(
              projectId: projectId,
              stageId: stageId!.toString(),
              tab: tab,
              from: from,
            ),
          );
        },
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => _RouteErrorScreen(message: '$error'),
    );
  }
}

class _CatalogRouteScreen extends StatelessWidget {
  const _CatalogRouteScreen({
    required this.from,
    required this.initialTab,
  });

  final String? from;
  final CatalogSection initialTab;

  @override
  Widget build(BuildContext context) {
    return CategoryListScreen(
      initialTab: initialTab,
      onBackPressed: () => context.go(from ??
          AppNavigation.locationForShellSection(AppShellSection.settings)),
      onTabChanged: (tab) {
        context.go(
          AppNavigation.catalogLocation(
            tab: tab,
            from: from,
          ),
        );
      },
    );
  }
}

class _FileViewerRouteScreen extends StatelessWidget {
  const _FileViewerRouteScreen({
    required this.url,
    required this.title,
    required this.from,
  });

  final String? url;
  final String? title;
  final String? from;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty || title == null || title!.isEmpty) {
      return const _RouteErrorScreen(message: 'Не удалось открыть файл.');
    }

    return FileViewerScreen(
      url: url!,
      title: title!,
      onBackPressed: () => context.go(from ?? AppNavigation.projectsPath),
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
