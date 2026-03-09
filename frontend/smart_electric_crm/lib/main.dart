import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'src/core/navigation/app_router.dart';
import 'src/core/network/network_recovery_bootstrap.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/presentation/providers/auth_provider.dart';
import 'src/features/settings/application/app_settings_controller.dart';
import 'src/shared/services/temp_file_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await initializeDateFormatting('ru', null);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(networkRecoveryBootstrapProvider);
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Smart Electric CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      builder: (context, child) {
        return AppLifecycleManager(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onExitRequested: _onExitRequested,
      onDetach: _onDetach,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  Future<AppExitResponse> _onExitRequested() async {
    await _cleanup();
    return AppExitResponse.exit;
  }

  void _onDetach() => _cleanup();

  Future<void> _cleanup() async {
    await TempFileService().disposeAll();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
