import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'src/features/home/presentation/screens/home_screen.dart';
import 'src/shared/services/temp_file_service.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Electric CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          surfaceTint: Colors.transparent, // Remove tint from surfaces
        ),
        // Customize NavigationBar to be less purple/tinted
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: Colors.indigo.withOpacity(0.12),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.indigo);
            }
            return IconThemeData(color: Colors.grey.shade600);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: Colors.indigo, fontWeight: FontWeight.w600);
            }
            return TextStyle(color: Colors.grey.shade600);
          }),
        ),
        // Customize FAB to be Indigo
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black12,
        ),
      ),
      home: const AppLifecycleManager(child: HomeScreen()),
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
