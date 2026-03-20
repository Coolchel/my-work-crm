import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_electric_crm/src/core/errors/user_friendly_error_mapper.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';

import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const double _desktopBreakpoint = 980;
  static const double _compactBreakpoint = 720;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
      // Navigation is handled by auth state in main.dart.
    } catch (e, st) {
      final message = UserFriendlyErrorMapper.map(
        e,
        fallbackMessage: 'Не удалось войти. Попробуйте еще раз.',
      );
      debugPrint('Login failed: $e\n$st');

      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktopLayout = width >= _desktopBreakpoint;
          final isCompact = width < _compactBreakpoint;
          final horizontalPadding = isCompact ? 16.0 : 28.0;
          final verticalPadding = isCompact ? 16.0 : 24.0;
          final contentMinHeight = constraints.maxHeight > (verticalPadding * 2)
              ? constraints.maxHeight - (verticalPadding * 2)
              : 0.0;

          return DecoratedBox(
            decoration: _buildBackgroundDecoration(context),
            child: Stack(
              children: [
                _buildBackgroundAccent(
                  context,
                  alignment: Alignment.topLeft,
                  size: isDesktopLayout ? 320 : 220,
                  offset: const Offset(-72, -64),
                  opacity: 0.10,
                ),
                _buildBackgroundAccent(
                  context,
                  alignment: Alignment.bottomRight,
                  size: isDesktopLayout ? 360 : 240,
                  offset: const Offset(84, 96),
                  opacity: 0.08,
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      verticalPadding +
                          MediaQuery.of(context).viewInsets.bottom * 0.12,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: contentMinHeight.toDouble(),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDesktopLayout ? 1120 : 560,
                          ),
                          child: isDesktopLayout
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: _buildIntroPanel(
                                        context,
                                        isDesktopLayout: true,
                                        isCompact: false,
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    SizedBox(
                                      width: 440,
                                      child: _buildLoginCard(
                                        context,
                                        isCompact: false,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildIntroPanel(
                                      context,
                                      isDesktopLayout: false,
                                      isCompact: isCompact,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildLoginCard(
                                      context,
                                      isCompact: isCompact,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scaffoldColor = theme.scaffoldBackgroundColor;
    final leadingTint = Color.alphaBlend(
      scheme.primary
          .withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.08),
      scaffoldColor,
    );
    final trailingTint = Color.alphaBlend(
      scheme.primary
          .withOpacity(theme.brightness == Brightness.dark ? 0.08 : 0.03),
      AppDesignTokens.surface1(context),
    );

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          leadingTint,
          scaffoldColor,
          trailingTint,
        ],
      ),
    );
  }

  Widget _buildBackgroundAccent(
    BuildContext context, {
    required Alignment alignment,
    required double size,
    required Offset offset,
    required double opacity,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  scheme.primary.withOpacity(opacity),
                  scheme.primary.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroPanel(
    BuildContext context, {
    required bool isDesktopLayout,
    required bool isCompact,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;

    return Padding(
      padding: EdgeInsets.only(right: isDesktopLayout ? 8 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppDesignTokens.surface2(context),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppDesignTokens.softBorder(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Electric CRM',
                  style: textStyles.captionStrong.copyWith(
                    color: scheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isCompact ? 18 : 28),
          Text(
            isDesktopLayout ? 'Вход в рабочее пространство' : 'Вход в систему',
            style: (isDesktopLayout
                    ? textStyles.heroTitle.copyWith(fontSize: 38)
                    : textStyles.pageTitle.copyWith(fontSize: 28))
                .copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktopLayout ? 460 : 520),
            child: Text(
              'Используйте рабочий логин и пароль, чтобы продолжить работу с проектами, сметами и документами.',
              style: textStyles.body.copyWith(
                fontSize: isDesktopLayout ? 15 : 14,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (isDesktopLayout) ...[
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppDesignTokens.surface1(context).withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusM),
                border: Border.all(color: AppDesignTokens.softBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: AppDesignTokens.cardShadow(context),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Что понадобится для входа',
                    style: textStyles.cardTitle.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHintRow(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: 'Рабочий логин',
                    description: 'Введите логин сотрудника или учетной записи.',
                  ),
                  const SizedBox(height: 14),
                  _buildHintRow(
                    context,
                    icon: Icons.lock_outline_rounded,
                    title: 'Пароль',
                    description:
                        'Если данные неверны, сообщение об ошибке появится прямо под полями.',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHintRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppDesignTokens.surface2(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textStyles.bodyStrong.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textStyles.secondaryBody.copyWith(
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(
    BuildContext context, {
    required bool isCompact,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;

    return Container(
      decoration: BoxDecoration(
        color: AppDesignTokens.surface1(context).withOpacity(0.96),
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        border: Border.all(color: AppDesignTokens.softBorder(context)),
        boxShadow: [
          BoxShadow(
            color: AppDesignTokens.cardShadow(context),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 20 : 28),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppDesignTokens.surface2(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.lock_person_rounded,
                    color: scheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Войти',
                  style: textStyles.dialogTitle.copyWith(
                    fontSize: isCompact ? 22 : 24,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Введите логин и пароль для доступа к системе.',
                  style: textStyles.body.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: 'Логин',
                    hintText: 'Введите логин',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите логин';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  obscureText: _obscurePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    hintText: 'Введите пароль',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Показать пароль'
                          : 'Скрыть пароль',
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _isLoading ? null : _login(),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _errorMessage == null
                      ? const SizedBox(key: ValueKey('login-error-empty'))
                      : Container(
                          key: ValueKey(_errorMessage),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: scheme.error.withOpacity(0.16),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: scheme.onErrorContainer,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: textStyles.body.copyWith(
                                    color: scheme.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _login,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _isLoading
                          ? Row(
                              key: const ValueKey('login-loading'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Входим...',
                                  style: textStyles.button.copyWith(
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              key: const ValueKey('login-idle'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.login_rounded, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  'Войти',
                                  style: textStyles.button.copyWith(
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
