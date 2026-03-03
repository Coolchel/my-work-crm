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
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final themeSegments = <ButtonSegment<ThemeMode>>[
      const ButtonSegment(
        value: ThemeMode.light,
        icon: Icon(Icons.light_mode_outlined),
      ),
      const ButtonSegment(
        value: ThemeMode.dark,
        icon: Icon(Icons.dark_mode_outlined),
      ),
      const ButtonSegment(
        value: ThemeMode.system,
        label: Text('Авто'),
      ),
    ];

    return Scaffold(
      appBar: CompactSectionAppBar(
        leading: IconButton(
          tooltip: 'РќР°Р·Р°Рґ',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (onBackPressed != null) {
              onBackPressed!();
              return;
            }
            Navigator.of(context).maybePop();
          },
        ),
        title: 'РќР°СЃС‚СЂРѕР№РєРё',
        icon: Icons.settings_rounded,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Р’РЅРµС€РЅРёР№ РІРёРґ'),
          _HoverSettingsCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'РўРµРјР° РїСЂРёР»РѕР¶РµРЅРёСЏ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: themeSegments,
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: isMobile
                            ? VisualDensity.compact
                            : VisualDensity.standard,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isMobile ? 8 : 10,
                          ),
                        ),
                      ),
                      selected: {settings.themeMode},
                      onSelectionChanged: (selection) {
                        settingsNotifier.setThemeMode(selection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HoverSettingsCard(
            child:
                _buildStartScreenSection(context, settings, settingsNotifier),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('РРЅСЃС‚СЂСѓРјРµРЅС‚С‹'),
          _HoverSettingsCard(
            child: ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.indigo),
              title: const Text('РЎРїСЂР°РІРѕС‡РЅРёРє'),
              subtitle: const Text(
                  'РљР°С‚РµРіРѕСЂРёРё, СЂР°СЃС†РµРЅРєРё Рё С€Р°Р±Р»РѕРЅС‹'),
              trailing: const Icon(Icons.chevron_right),
              hoverColor: AppDesignTokens.hoverOverlay(context),
              onTap: () => _showReferenceWarning(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('РђРєРєР°СѓРЅС‚'),
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
                                user['username'] ?? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
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
                    title: const Text('РћС€РёР±РєР° РїСЂРѕС„РёР»СЏ'),
                    subtitle: Text(e.toString()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_reset, color: Colors.indigo),
                  title: const Text('РЈРїСЂР°РІР»РµРЅРёРµ РїР°СЂРѕР»РµРј'),
                  subtitle:
                      const Text('РЎРјРµРЅРёС‚СЊ С‚РµРєСѓС‰РёР№ РїР°СЂРѕР»СЊ'),
                  hoverColor: AppDesignTokens.hoverOverlay(context),
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Р’С‹Р№С‚Рё РёР· СЃРёСЃС‚РµРјС‹',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text(
                      'Р—Р°РІРµСЂС€РёС‚СЊ С‚РµРєСѓС‰РёР№ СЃРµР°РЅСЃ'),
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
                                      'Р’С‹С…РѕРґ',
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
                                  'Р’С‹ РґРµР№СЃС‚РІРёС‚РµР»СЊРЅРѕ С…РѕС‚РёС‚Рµ РІС‹Р№С‚Рё РёР· СЃРёСЃС‚РµРјС‹?',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('РћС‚РјРµРЅР°'),
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
                                      child: const Text('Р’С‹Р№С‚Рё'),
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

  Widget _buildStartScreenSection(
    BuildContext context,
    AppSettingsState settings,
    AppSettingsNotifier settingsNotifier,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.waving_hand_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '\u041d\u0430\u0447\u0430\u043b\u044c\u043d\u044b\u0439 \u044d\u043a\u0440\u0430\u043d',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: settings.showWelcome,
                onChanged: (value) => settingsNotifier.setShowWelcome(value),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Text(
            '\u041f\u0440\u0438\u0432\u0435\u0442\u0441\u0442\u0432\u0438\u0435 \u0438 \u0431\u044b\u0441\u0442\u0440\u044b\u0439 \u043f\u043e\u0438\u0441\u043a. '
            '\u0415\u0441\u043b\u0438 \u044d\u043a\u0440\u0430\u043d \u0432\u044b\u043a\u043b\u044e\u0447\u0435\u043d, \u0432\u043a\u043b\u0430\u0434\u043a\u0430 \u043d\u0430\u0441\u0442\u0440\u043e\u0435\u043a \u043f\u043e\u044f\u0432\u0438\u0442\u0441\u044f \u0432\u043d\u0438\u0437\u0443, '
            '\u0430 \u043a\u043d\u043e\u043f\u043a\u0430 \u00ab\u0413\u043b\u0430\u0432\u043d\u0430\u044f\u00bb \u0432 \u0433\u043b\u0443\u0431\u043e\u043a\u0438\u0445 \u0440\u0430\u0437\u0434\u0435\u043b\u0430\u0445 \u0441\u043a\u0440\u044b\u0432\u0430\u0435\u0442\u0441\u044f.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
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
                          'РћРїР°СЃРЅР°СЏ Р·РѕРЅР°',
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
                    'Р’С‹ РІС…РѕРґРёС‚Рµ РІ СЂР°Р·РґРµР» СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёСЏ СЃРїСЂР°РІРѕС‡РЅРёРєР°. Р›СЋР±С‹Рµ РёР·РјРµРЅРµРЅРёСЏ Р·РґРµСЃСЊ РїРѕРІР»РёСЏСЋС‚ РЅР° СЂР°СЃС‡РµС‚С‹ РІРѕ РІСЃРµС… РїСЂРѕРµРєС‚Р°С…. Р‘СѓРґСЊС‚Рµ РѕСЃС‚РѕСЂРѕР¶РЅС‹!',
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
                      labelText:
                          'РџР°СЂРѕР»СЊ С‚РµРєСѓС‰РµРіРѕ Р°РєРєР°СѓРЅС‚Р°',
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
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                        child: const Text('РћС‚РјРµРЅР°'),
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
                                        'Р’РІРµРґРёС‚Рµ РїР°СЂРѕР»СЊ РґР»СЏ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ';
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
                                        'РќРµ СѓРґР°Р»РѕСЃСЊ РїРѕР»СѓС‡РёС‚СЊ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ');
                                  }

                                  final isValid =
                                      await repo.verifyCurrentPassword(
                                    username: username,
                                    password: password,
                                  );

                                  if (!isValid) {
                                    setDialogState(() {
                                      isLoading = false;
                                      passwordError =
                                          'РќРµРІРµСЂРЅС‹Р№ РїР°СЂРѕР»СЊ';
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
                                        'РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё. РџРѕРїСЂРѕР±СѓР№С‚Рµ РµС‰Рµ СЂР°Р·.';
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
                            : const Text('РЇ РїРѕРЅРёРјР°СЋ'),
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
                          'РЎРјРµРЅР° РїР°СЂРѕР»СЏ',
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
                          'РўРµРєСѓС‰РёР№ РїР°СЂРѕР»СЊ',
                          isEnabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        _buildDialogField(
                          newPasswordController,
                          'РќРѕРІС‹Р№ РїР°СЂРѕР»СЊ',
                          isEnabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        _buildDialogField(
                          confirmPasswordController,
                          'РџРѕРґС‚РІРµСЂР¶РґРµРЅРёРµ',
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
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed:
                              isLoading ? null : () => Navigator.pop(context),
                          child: const Text('РћС‚РјРµРЅР°'),
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
                                      confirmError =
                                          'РџР°СЂРѕР»Рё РЅРµ СЃРѕРІРїР°РґР°СЋС‚';
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
                                          content: Text(
                                              'РџР°СЂРѕР»СЊ СѓСЃРїРµС€РЅРѕ РёР·РјРµРЅРµРЅ'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() {
                                      isLoading = false;
                                      if (e is DioException &&
                                          e.response?.statusCode == 400) {
                                        errorMessage =
                                            'РќРµРІРµСЂРЅС‹Р№ СЃС‚Р°СЂС‹Р№ РїР°СЂРѕР»СЊ РёР»Рё РЅРµРґРѕРїСѓСЃС‚РёРјС‹Р№ РЅРѕРІС‹Р№ РїР°СЂРѕР»СЊ';
                                      } else {
                                        errorMessage =
                                            'РћС€РёР±РєР°: ${e.toString()}';
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
                              : const Text('РЎРѕС…СЂР°РЅРёС‚СЊ'),
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
