import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/app_dialog_scrollbar.dart';
import '../widgets/desktop_web_frame.dart';

const double desktopDialogMaxWidth = 560;
const double desktopDialogSingleLineFieldHeight = 56;
const double desktopDialogActionButtonWidth = 132;
const double desktopDialogActionButtonHeight = 40;

bool usesDesktopDialogFoundation(
  BuildContext context, {
  double mobileWidthBreakpoint = 700,
}) {
  return !DesktopWebFrame.usesMobileContentPadding(
    context,
    maxWidth: mobileWidthBreakpoint,
  );
}

class DesktopDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  final Color accentColor;
  final VoidCallback? onClose;
  final ScrollController? scrollController;
  final double maxWidth;
  final EdgeInsets insetPadding;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry actionsPadding;

  const DesktopDialogShell({
    required this.title,
    required this.child,
    required this.actions,
    super.key,
    this.accentColor = Colors.indigo,
    this.onClose,
    this.scrollController,
    this.maxWidth = desktopDialogMaxWidth,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 24,
    ),
    this.contentPadding = const EdgeInsets.fromLTRB(20, 16, 20, 8),
    this.actionsPadding = const EdgeInsets.fromLTRB(20, 8, 20, 18),
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);

    return Dialog(
      insetPadding: insetPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusL),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: constraints.maxHeight * 0.82,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusL),
                border: Border.all(color: AppDesignTokens.softBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.22 : 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDesignTokens.radiusL),
                        topRight: Radius.circular(AppDesignTokens.radiusL),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Text(
                            title,
                            style: textStyles.dialogTitle.copyWith(
                              color: accentColor.withOpacity(0.84),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Tooltip(
                            message: MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                            child: IconButton(
                              onPressed:
                                  onClose ?? () => Navigator.of(context).pop(),
                              icon: Icon(Icons.close, color: accentColor),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 18,
                              iconSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: AppDialogScrollbar.builder(
                      controller: scrollController,
                      builder: (resolvedController) => SingleChildScrollView(
                        controller: resolvedController,
                        padding: contentPadding,
                        child: child,
                      ),
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: actionsPadding,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: actions,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DesktopDialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color accentColor;
  final bool enabled;
  final bool obscureText;
  final bool autofocus;
  final String? errorText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const DesktopDialogTextField({
    required this.controller,
    required this.label,
    required this.accentColor,
    super.key,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
    this.errorText,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    final isSingleLine = maxLines == 1;

    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      autofocus: autofocus,
      maxLines: maxLines,
      onChanged: onChanged,
      textAlignVertical:
          isSingleLine ? TextAlignVertical.center : TextAlignVertical.top,
      style: textStyles.input,
      decoration: desktopDialogInputDecoration(
        context,
        label: label,
        accentColor: accentColor,
        errorText: errorText,
        alignLabelWithHint: !isSingleLine,
        constraints: isSingleLine
            ? const BoxConstraints(
                minHeight: desktopDialogSingleLineFieldHeight,
                maxHeight: desktopDialogSingleLineFieldHeight,
              )
            : null,
      ),
    );
  }
}

class DesktopDialogSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color accentColor;
  final double width;

  const DesktopDialogSecondaryButton({
    required this.onPressed,
    required this.label,
    required this.accentColor,
    super.key,
    this.width = desktopDialogActionButtonWidth,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: accentColor.withOpacity(0.92),
          disabledForegroundColor: scheme.onSurface.withOpacity(0.38),
          minimumSize: const Size(
            desktopDialogActionButtonWidth,
            desktopDialogActionButtonHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          side: BorderSide(color: accentColor.withOpacity(0.55), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class DesktopDialogPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color accentColor;
  final double width;

  const DesktopDialogPrimaryButton({
    required this.onPressed,
    required this.child,
    required this.accentColor,
    super.key,
    this.width = desktopDialogActionButtonWidth,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: FilledButton(
        onPressed: onPressed,
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(scheme.onPrimary),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return accentColor.withOpacity(0.42);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return accentColor;
            }
            return accentColor.withOpacity(0.82);
          }),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(
              desktopDialogActionButtonWidth,
              desktopDialogActionButtonHeight,
            ),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class DesktopMessageDialog extends StatelessWidget {
  final String title;
  final String message;
  final String actionText;
  final Color accentColor;
  final IconData icon;
  final VoidCallback? onClose;
  final double maxWidth;

  const DesktopMessageDialog({
    required this.title,
    required this.message,
    super.key,
    this.actionText = '\u041f\u043e\u043d\u044f\u0442\u043d\u043e',
    this.accentColor = Colors.indigo,
    this.icon = Icons.info_outline,
    this.onClose,
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DesktopDialogShell(
      title: title,
      accentColor: accentColor,
      onClose: onClose ?? () => Navigator.of(context).pop(),
      maxWidth: maxWidth,
      actions: [
        FilledButton.icon(
          onPressed: onClose ?? () => Navigator.of(context).pop(),
          icon: Icon(icon, size: 18),
          label: Text(actionText),
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: scheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: context.appTextStyles.body.copyWith(
                color: scheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color desktopDialogFieldFillColor(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return AppDesignTokens.isDark(context)
      ? scheme.surfaceContainerHigh
      : scheme.surfaceContainer.withOpacity(0.4);
}

InputDecoration desktopDialogInputDecoration(
  BuildContext context, {
  required String label,
  required Color accentColor,
  String? hint,
  String? errorText,
  bool alignLabelWithHint = false,
  BoxConstraints? constraints,
  EdgeInsetsGeometry? contentPadding,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final textStyles = context.appTextStyles;
  final labelStyle = textStyles.fieldLabel.copyWith(
    fontSize: 12.5,
    color: accentColor.withOpacity(0.82),
  );

  return InputDecoration(
    labelText: label,
    labelStyle: labelStyle,
    floatingLabelStyle: labelStyle,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    alignLabelWithHint: alignLabelWithHint,
    constraints: constraints,
    errorText: errorText,
    isDense: true,
    filled: true,
    fillColor: desktopDialogFieldFillColor(context),
    hintText: hint,
    hintStyle: textStyles.secondaryBody.copyWith(
      color: scheme.onSurfaceVariant.withOpacity(0.75),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppDesignTokens.softBorder(context),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppDesignTokens.softBorder(context),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: accentColor.withOpacity(0.9), width: 1.25),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 1.25),
    ),
    errorStyle: theme.inputDecorationTheme.errorStyle,
    contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(16, 18, 16, 10),
  );
}
