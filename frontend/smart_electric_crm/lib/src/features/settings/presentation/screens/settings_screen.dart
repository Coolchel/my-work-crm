import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../application/app_settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Настройки',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Тема приложения',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Светлая'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Тёмная'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Системная'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) {
                    settingsNotifier.setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: settings.showCatalog,
          title: const Text('Показывать пункт меню «Справочник»'),
          onChanged: (value) => settingsNotifier.setShowCatalog(value),
        ),
        SwitchListTile(
          value: settings.showWelcome,
          title: const Text('Показывать «Начальный экран»'),
          onChanged: (value) => settingsNotifier.setShowWelcome(value),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
          },
          label: const Text('Выйти'),
        ),
      ],
    );
  }
}
