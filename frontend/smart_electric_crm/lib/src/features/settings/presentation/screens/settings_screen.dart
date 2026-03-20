import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/route_bootstrap_storage.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/compact_section_app_bar.dart';
import '../../../../shared/presentation/widgets/desktop_web_frame.dart';
import '../../../../shared/presentation/widgets/app_section_header.dart';
import '../../application/app_settings_controller.dart';
import '../../../../core/theme/app_design_tokens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const SettingsScreen({
    this.onBackPressed,
    super.key,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final SectionAppBarCollapseController _appBarCollapseController =
      SectionAppBarCollapseController();
  Object? _scrollAttachment;

  @override
  void initState() {
    super.initState();
    _appBarCollapseController.bind(_scrollController);
    _scrollAttachment =
        AppNavigation.settingsScrollController.attach(_scrollToTop);
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.settingsScrollController.detach(scrollAttachment);
    }
    _appBarCollapseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToTop({bool animated = true}) async {
    if (!_scrollController.hasClients) {
      return;
    }
    if (animated) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    void handleBack() {
      if (widget.onBackPressed != null) {
        widget.onBackPressed!();
        return;
      }
      Navigator.of(context).maybePop();
    }

    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final userAsync = ref.watch(userProfileProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isDesktopWeb = DesktopWebFrame.isDesktop(context, minWidth: 1180);
    final horizontalContentPadding = DesktopWebFrame.contentHorizontalPadding(
      context,
      desktop: 16,
    );
    final shellSidebarInset = DesktopWebFrame.persistentShellContentInset(
      context,
    );
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

    return ListenableBuilder(
      listenable: _appBarCollapseController,
      builder: (context, child) {
        return Scaffold(
          appBar: CompactSectionAppBar(
            collapseProgress: CompactSectionAppBar.resolveCollapseProgress(
              context,
              _appBarCollapseController.progress,
            ),
            leading: IconButton(
              tooltip: 'Назад',
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: handleBack,
            ),
            title: 'Настройки',
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (!isDesktopWeb) {
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(left: shellSidebarInset),
                  child: child!,
                );
              }

              return AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(left: shellSidebarInset),
                child: DesktopWebPageFrame(
                  maxWidth: 1160,
                  padding: EdgeInsets.symmetric(
                    horizontal: DesktopWebFrame.contentHorizontalPadding(
                      context,
                      desktop: 20,
                    ),
                  ),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: child!,
                  ),
                ),
              );
            },
          ),
        );
      },
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          horizontalContentPadding,
          isDesktopWeb ? 24 : 16,
          horizontalContentPadding,
          16,
        ),
        children: [
          _buildSectionHeader(context, 'Внешний вид'),
          _HoverSettingsCard(
            child: _buildThemeSection(
              context,
              settings,
              settingsNotifier,
              themeSegments,
              isMobile,
            ),
          ),
          const SizedBox(height: 12),
          _HoverSettingsCard(
            child:
                _buildStartScreenSection(context, settings, settingsNotifier),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Инструменты'),
          _HoverSettingsCard(
            child: InkWell(
              hoverColor: AppDesignTokens.hoverOverlay(context),
              onTap: () => _showReferenceWarning(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSettingsSectionRow(
                  context: context,
                  icon: Icons.menu_book_outlined,
                  title:
                      '\u0421\u043f\u0440\u0430\u0432\u043e\u0447\u043d\u0438\u043a',
                  subtitle:
                      '\u041a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u0438, \u0440\u0430\u0441\u0446\u0435\u043d\u043a\u0438 \u0438 \u0448\u0430\u0431\u043b\u043e\u043d\u044b',
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Аккаунт'),
          _HoverSettingsCard(
            child: Column(
              children: [
                userAsync.when(
                  data: (user) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSettingsSectionRow(
                      context: context,
                      icon: Icons.badge_outlined,
                      title: user['username'] ??
                          '\u041f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044c',
                      subtitle: user['email'] != null &&
                              user['email'].toString().isNotEmpty
                          ? user['email']
                          : '\u0410\u043a\u043a\u0430\u0443\u043d\u0442 \u043f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u044f',
                    ),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSettingsSectionRow(
                      context: context,
                      icon: Icons.error_outline,
                      title:
                          '\u041e\u0448\u0438\u0431\u043a\u0430 \u043f\u0440\u043e\u0444\u0438\u043b\u044f',
                      subtitle: e.toString(),
                      accentColor: Colors.redAccent,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1),
                ),
                InkWell(
                  hoverColor: AppDesignTokens.hoverOverlay(context),
                  onTap: () => _showChangePasswordDialog(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSettingsSectionRow(
                      context: context,
                      icon: Icons.lock_outline_rounded,
                      title:
                          '\u0423\u043f\u0440\u0430\u0432\u043b\u0435\u043d\u0438\u0435 \u043f\u0430\u0440\u043e\u043b\u0435\u043c',
                      subtitle:
                          '\u0421\u043c\u0435\u043d\u0438\u0442\u044c \u0442\u0435\u043a\u0443\u0449\u0438\u0439 \u043f\u0430\u0440\u043e\u043b\u044c',
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1),
                ),
                InkWell(
                  hoverColor: AppDesignTokens.hoverOverlay(context),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        final textStyles = context.appTextStyles;
                        return Dialog(
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
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout,
                                          color: Colors.red),
                                      const SizedBox(width: 12),
                                      Text(
                                        '\u0412\u044b\u0445\u043e\u0434',
                                        style: textStyles.dialogTitle.copyWith(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    '\u0412\u044b \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0442\u0435\u043b\u044c\u043d\u043e \u0445\u043e\u0442\u0438\u0442\u0435 \u0432\u044b\u0439\u0442\u0438 \u0438\u0437 \u0441\u0438\u0441\u0442\u0435\u043c\u044b?',
                                    style:
                                        textStyles.body.copyWith(fontSize: 15),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                  child: Wrap(
                                    alignment: WrapAlignment.end,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text(
                                          '\u041e\u0442\u043c\u0435\u043d\u0430',
                                        ),
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
                                        child: const Text(
                                          '\u0412\u044b\u0439\u0442\u0438',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                    if (confirmed == true) {
                      RouteBootstrapStorage.clearPendingRedirect();
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(AppNavigation.loginPath);
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSettingsSectionRow(
                      context: context,
                      icon: Icons.logout_outlined,
                      title:
                          '\u0412\u044b\u0439\u0442\u0438 \u0438\u0437 \u0441\u0438\u0441\u0442\u0435\u043c\u044b',
                      subtitle:
                          '\u0417\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u044c \u0442\u0435\u043a\u0443\u0449\u0438\u0439 \u0441\u0435\u0430\u043d\u0441',
                      trailing: const Icon(Icons.chevron_right),
                      accentColor: Colors.redAccent,
                      titleColor: Colors.red,
                    ),
                  ),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildSettingsSectionRow(
        context: context,
        icon: Icons.space_dashboard_outlined,
        title:
            '\u041d\u0430\u0447\u0430\u043b\u044c\u043d\u044b\u0439 \u044d\u043a\u0440\u0430\u043d',
        subtitle:
            '\u041f\u0440\u0438\u0432\u0435\u0442\u0441\u0442\u0432\u0438\u0435 \u0438 \u0431\u044b\u0441\u0442\u0440\u044b\u0439 \u043f\u043e\u0438\u0441\u043a. '
            '\u0415\u0441\u043b\u0438 \u044d\u043a\u0440\u0430\u043d \u0432\u044b\u043a\u043b\u044e\u0447\u0435\u043d, \u0432\u043a\u043b\u0430\u0434\u043a\u0430 \u043d\u0430\u0441\u0442\u0440\u043e\u0435\u043a \u043f\u043e\u044f\u0432\u0438\u0442\u0441\u044f \u0432\u043d\u0438\u0437\u0443, '
            '\u0430 \u043a\u043d\u043e\u043f\u043a\u0430 \u00ab\u0413\u043b\u0430\u0432\u043d\u0430\u044f\u00bb \u0432 \u0433\u043b\u0443\u0431\u043e\u043a\u0438\u0445 \u0440\u0430\u0437\u0434\u0435\u043b\u0430\u0445 \u0441\u043a\u0440\u044b\u0432\u0430\u0435\u0442\u0441\u044f.',
        centerAccessoryVertically: true,
        trailing: Switch(
          value: settings.showWelcome,
          onChanged: (value) => settingsNotifier.setShowWelcome(value),
        ),
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    AppSettingsState settings,
    AppSettingsNotifier settingsNotifier,
    List<ButtonSegment<ThemeMode>> themeSegments,
    bool isMobile,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSectionRow(
            context: context,
            icon: Icons.palette_outlined,
            title:
                '\u0422\u0435\u043c\u0430 \u043f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u044f',
            subtitle:
                '\u0421\u0432\u0435\u0442\u043b\u0430\u044f, \u0442\u0435\u043c\u043d\u0430\u044f \u0438\u043b\u0438 \u0430\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0430\u044f \u0442\u0435\u043c\u0430 \u0432 \u0437\u0430\u0432\u0438\u0441\u0438\u043c\u043e\u0441\u0442\u0438 \u043e\u0442 \u0441\u0438\u0441\u0442\u0435\u043c\u044b.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: themeSegments,
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity:
                    isMobile ? VisualDensity.compact : VisualDensity.standard,
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
    );
  }

  Widget _buildSettingsSectionRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color accentColor = Colors.indigo,
    Color? titleColor,
    Color? subtitleColor,
    bool centerAccessoryVertically = false,
  }) {
    final theme = Theme.of(context);
    final textStyles = context.appTextStyles;
    final isWindowsDesktop =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final titleStyle =
        (isWindowsDesktop ? textStyles.cardTitle : textStyles.cardTitle)
            .copyWith(fontWeight: FontWeight.w600);
    final subtitleStyle = (isWindowsDesktop
            ? textStyles.caption.copyWith(fontSize: 11.5)
            : textStyles.caption)
        .copyWith(
      color: subtitleColor ?? theme.colorScheme.onSurfaceVariant,
      height: 1.35,
    );

    return Row(
      crossAxisAlignment: centerAccessoryVertically
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: accentColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    EdgeInsets.only(top: centerAccessoryVertically ? 0 : 2),
                child: Text(
                  title,
                  style: titleStyle.copyWith(
                    color: titleColor ?? theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: subtitleStyle),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(top: centerAccessoryVertically ? 0 : 2),
            child: trailing,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppEyebrowLabel(
      text: title,
      color: Color.lerp(
        scheme.onSurfaceVariant,
        scheme.primary,
        isDark ? 0.24 : 0.16,
      ),
      padding: const EdgeInsets.only(left: 4, bottom: 6),
    );
  }

  void _showReferenceWarning(BuildContext context, WidgetRef ref) {
    final screenContext = context;
    const themeColor = Colors.red;
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? passwordError;

    showDialog(
      context: screenContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final textStyles = dialogContext.appTextStyles;
          final isMobileWeb =
              DesktopWebFrame.isMobileWeb(dialogContext, maxWidth: 560);
          final baseInset = EdgeInsets.symmetric(
            horizontal: isMobileWeb ? 10 : 16,
            vertical: isMobileWeb ? 8 : 12,
          );
          final contentPadding = EdgeInsets.fromLTRB(
            isMobileWeb ? 16 : 24,
            isMobileWeb ? 18 : 24,
            isMobileWeb ? 16 : 24,
            12,
          );
          final footerPadding = EdgeInsets.fromLTRB(
            isMobileWeb ? 16 : 24,
            0,
            isMobileWeb ? 16 : 24,
            isMobileWeb ? 16 : 24,
          );

          return Dialog(
            insetPadding: baseInset,
            insetAnimationDuration: const Duration(milliseconds: 180),
            insetAnimationCurve: Curves.easeOut,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: themeColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Опасная зона',
                              style: textStyles.dialogTitle.copyWith(
                                color: themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: contentPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Вы входите в раздел редактирования справочника. Любые изменения здесь повлияют на расчеты во всех проектах. Будьте осторожны!',
                            style: textStyles.body.copyWith(
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
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
                        ],
                      ),
                    ),
                    Padding(
                      padding: footerPadding,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: const Text('Отмена'),
                          ),
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
                                      final repo = await ref.read(
                                        authRepositoryProvider.future,
                                      );
                                      final user = await repo.getUser();
                                      final username = (user['username'] ?? '')
                                          .toString()
                                          .trim();

                                      if (username.isEmpty) {
                                        throw Exception(
                                          'Не удалось получить пользователя',
                                        );
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

                                      if (!screenContext.mounted) return;
                                      Navigator.pop(dialogContext);
                                      AppNavigation.openCatalog(screenContext);
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
                                      color:
                                          Theme.of(context).colorScheme.surface,
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
          );
        },
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
          final textStyles = context.appTextStyles;
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
                        Text(
                          'Смена пароля',
                          style: textStyles.dialogTitle.copyWith(
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
                                    style: textStyles.secondaryBody.copyWith(
                                      color: Colors.red,
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
        errorStyle: Theme.of(context)
            .inputDecorationTheme
            .errorStyle
            ?.copyWith(height: 0.8),
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
