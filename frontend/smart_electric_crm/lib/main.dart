import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'src/features/home/presentation/screens/home_screen.dart';
import 'src/features/auth/presentation/login_screen.dart';
import 'src/features/auth/presentation/providers/auth_provider.dart';
import 'src/features/settings/application/app_settings_controller.dart';
import 'src/shared/services/temp_file_service.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/network/network_recovery_bootstrap.dart';
import 'src/core/navigation/app_navigation.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    // Check auth status on app start
    // We delay slightly to ensure provider is ready or just call it.
    // Actually calling it directly is fine.
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      return true;
    }

    await navigator.maybePop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authProvider);
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Smart Electric CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: AppLifecycleManager(
        child: switch (authStatus) {
          AuthStatus.authenticated => const HomeScreen(),
          AuthStatus.unauthenticated ||
          AuthStatus.error =>
            const _RootBackBlocker(
              child: LoginScreen(),
            ),
          AuthStatus.loading || AuthStatus.initial => const _RootBackBlocker(
              child: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            ),
        },
      ),
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
      // onResume: () {
      //   // Optional: Check auth on resume?
      // },
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

class _RootBackBlocker extends StatelessWidget {
  final Widget child;

  const _RootBackBlocker({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: child,
    );
  }
}
