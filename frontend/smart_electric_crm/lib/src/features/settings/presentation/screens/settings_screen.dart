import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/presentation/category_list_screen.dart';
import '../../../../shared/presentation/widgets/compact_section_app_bar.dart';
import '../../application/app_settings_controller.dart';
import '../../../../core/theme/app_design_tokens.dart';

class SettingsScreen extends ConsumerWidget {
  final VoidCallback? onBackPressed;

  const SettingsScreen({
    this.onBackPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: CompactSectionAppBar(
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (onBackPressed != null) {
              onBackPressed!();
              return;
            }
            Navigator.of(context).maybePop();
          },
        ),
        title: 'Настройки',
        icon: Icons.settings_rounded,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Внешний вид'),
          _HoverSettingsCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Тема приложения',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Светлая'),
                              icon: Icon(Icons.light_mode_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Темная'),
                              icon: Icon(Icons.dark_mode_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('Авто'),
                              icon: Icon(Icons.settings_brightness_outlined),
                            ),
                          ],
                          selected: {settings.themeMode},
                          onSelectionChanged: (selection) {
                            settingsNotifier.setThemeMode(selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  hoverColor: AppDesignTokens.hoverOverlay(context),
                  secondary: const Icon(Icons.waving_hand_outlined),
                  title: const Text('Начальный экран'),
                  subtitle: const Text(
                    'Приветствие и быстрый поиск. '
                    'Если экран выключен, вкладка настроек появится внизу, '
                    'а кнопка «Главная» в глубоких разделах скрывается.',
                  ),
                  value: settings.showWelcome,
                  onChanged: (value) => settingsNotifier.setShowWelcome(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Инструменты'),
          _HoverSettingsCard(
            child: ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.indigo),
              title: const Text('Справочник'),
              subtitle: const Text('Категории, расценки и шаблоны'),
              trailing: const Icon(Icons.chevron_right),
              hoverColor: AppDesignTokens.hoverOverlay(context),
              onTap: () => _showReferenceWarning(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Аккаунт'),
          _HoverSettingsCard(
            child: Column(
              children: [
                userAsync.when(
                  data: (user) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          child: const Icon(
                            Icons.manage_accounts_outlined,
                            color: Colors.indigo,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['username'] ?? 'Пользователь',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (user['email'] != null &&
                                  user['email'].toString().isNotEmpty)
                                Text(
                                  user['email'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => ListTile(
                    title: const Text('Ошибка профиля'),
                    subtitle: Text(e.toString()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_reset, color: Colors.indigo),
                  title: const Text('Управление паролем'),
                  subtitle: const Text('Сменить текущий пароль'),
                  hoverColor: AppDesignTokens.hoverOverlay(context),
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Выйти из системы',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Завершить текущий сеанс'),
                  hoverColor: AppDesignTokens.hoverOverlay(context),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text(
                                      'Выход',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Вы действительно хотите выйти из системы?',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Отмена'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Выйти'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authProvider.notifier).logout();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.indigo.withOpacity(0.6),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showReferenceWarning(BuildContext context, WidgetRef ref) {
    const themeColor = Colors.red;
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? passwordError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: themeColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Опасная зона',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Text(
                    'Вы входите в раздел редактирования справочника. Любые изменения здесь повлияют на расчеты во всех проектах. Будьте осторожны!',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: TextField(
                    controller: passwordController,
                    enabled: !isLoading,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Пароль текущего аккаунта',
                      errorText: passwordError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor:
                              Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                final password = passwordController.text;
                                if (password.trim().isEmpty) {
                                  setDialogState(() {
                                    passwordError =
                                        'Введите пароль для подтверждения';
                                  });
                                  return;
                                }

                                setDialogState(() {
                                  isLoading = true;
                                  passwordError = null;
                                });

                                try {
                                  final repo = await ref
                                      .read(authRepositoryProvider.future);
                                  final user = await repo.getUser();
                                  final username = (user['username'] ?? '')
                                      .toString()
                                      .trim();

                                  if (username.isEmpty) {
                                    throw Exception(
                                        'Не удалось получить пользователя');
                                  }

                                  final isValid =
                                      await repo.verifyCurrentPassword(
                                    username: username,
                                    password: password,
                                  );

                                  if (!isValid) {
                                    setDialogState(() {
                                      isLoading = false;
                                      passwordError = 'Неверный пароль';
                                    });
                                    return;
                                  }

                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CategoryListScreen(),
                                    ),
                                  );
                                } catch (_) {
                                  setDialogState(() {
                                    isLoading = false;
                                    passwordError =
                                        'Ошибка проверки. Попробуйте еще раз.';
                                  });
                                }
                              },
                        child: isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                              )
                            : const Text('Я понимаю'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    const themeColor = Colors.indigo;

    bool isLoading = false;
    String? errorMessage;
    String? confirmError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Смена пароля',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: themeColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildDialogField(
                          oldPasswordController,
                          'Текущий пароль',
                          isEnabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        _buildDialogField(
                          newPasswordController,
                          'Новый пароль',
                          isEnabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        _buildDialogField(
                          confirmPasswordController,
                          'Подтверждение',
                          isEnabled: !isLoading,
                          errorText: confirmError,
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              isLoading ? null : () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor:
                                Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(120, 44),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (newPasswordController.text !=
                                      confirmPasswordController.text) {
                                    setDialogState(() {
                                      confirmError = 'Пароли не совпадают';
                                    });
                                    return;
                                  }

                                  setDialogState(() {
                                    isLoading = true;
                                    errorMessage = null;
                                    confirmError = null;
                                  });

                                  try {
                                    final repo = await ref
                                        .read(authRepositoryProvider.future);
                                    await repo.changePassword(
                                      oldPasswordController.text,
                                      newPasswordController.text,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Пароль успешно изменен'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() {
                                      isLoading = false;
                                      if (e is DioException &&
                                          e.response?.statusCode == 400) {
                                        errorMessage =
                                            'Неверный старый пароль или недопустимый новый пароль';
                                      } else {
                                        errorMessage =
                                            'Ошибка: ${e.toString()}';
                                      }
                                    });
                                  }
                                },
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                  ),
                                )
                              : const Text('Сохранить'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label, {
    bool isEnabled = true,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      enabled: isEnabled,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        errorStyle: const TextStyle(height: 0.8),
      ),
      obscureText: true,
    );
  }
}

class _HoverSettingsCard extends StatefulWidget {
  final Widget child;

  const _HoverSettingsCard({required this.child});

  @override
  State<_HoverSettingsCard> createState() => _HoverSettingsCardState();
}

class _HoverSettingsCardState extends State<_HoverSettingsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(context, hovered: _isHovered),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppDesignTokens.cardBorder(context, hovered: _isHovered)),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context, hovered: _isHovered),
              blurRadius: _isHovered ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}
