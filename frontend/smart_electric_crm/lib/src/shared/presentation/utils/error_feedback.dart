import 'package:flutter/material.dart';

import '../../../core/errors/user_friendly_error_mapper.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../dialogs/desktop_dialog_foundation.dart';

class ErrorFeedback {
  static Future<void> show(
    BuildContext context,
    Object error, {
    String fallbackMessage = UserFriendlyErrorMapper.genericErrorMessage,
  }) async {
    final userMessage = UserFriendlyErrorMapper.map(
      error,
      fallbackMessage: fallbackMessage,
    );
    debugPrint('ErrorFeedback.show: $error');
    await showMessage(context, userMessage);
  }

  static void showSnackBar(
    BuildContext context,
    Object error, {
    String fallbackMessage = UserFriendlyErrorMapper.genericErrorMessage,
  }) {
    final userMessage = UserFriendlyErrorMapper.map(
      error,
      fallbackMessage: fallbackMessage,
    );
    debugPrint('ErrorFeedback.showSnackBar: $error');
    showSnackBarMessage(context, userMessage);
  }

  static Future<void> showMessage(
    BuildContext context,
    String message, {
    String title = '\u041e\u0448\u0438\u0431\u043a\u0430',
  }) async {
    if (!context.mounted) return;

    if (ModalRoute.of(context) is PopupRoute<dynamic>) {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          final isNetworkIssue = message.toLowerCase().contains(
              '\u043d\u0435\u0442 \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f');
          final isFailure = title
                  .toLowerCase()
                  .contains('\u043e\u0448\u0438\u0431\u043a\u0430') ||
              message.toLowerCase().contains(
                  '\u043d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c') ||
              message
                  .toLowerCase()
                  .contains('\u043e\u0448\u0438\u0431\u043a\u0430');
          final themeColor = isFailure
              ? Colors.red
              : isNetworkIssue
                  ? Colors.deepOrange
                  : Colors.indigo;
          final icon = isFailure
              ? Icons.error_outline
              : isNetworkIssue
                  ? Icons.wifi_off_rounded
                  : Icons.info_outline;

          if (usesDesktopDialogFoundation(dialogContext)) {
            return DesktopMessageDialog(
              title: title,
              message: message,
              accentColor: themeColor,
              icon: icon,
            );
          }

          final scheme = Theme.of(dialogContext).colorScheme;
          final textStyles = dialogContext.appTextStyles;
          final isDark = AppDesignTokens.isDark(dialogContext);

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.34)
                        : Colors.black.withOpacity(0.14),
                    blurRadius: isDark ? 12 : 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.14),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: themeColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: textStyles.dialogTitle.copyWith(
                              color: themeColor.withOpacity(0.95),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Text(
                      message,
                      style: textStyles.body.copyWith(
                        color: scheme.onSurface,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                            '\u041f\u043e\u043d\u044f\u0442\u043d\u043e'),
                        style: FilledButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    _showFixedSnackBar(messenger, message);
  }

  static void showSnackBarMessage(
    BuildContext context,
    String message,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    _showFixedSnackBar(messenger, message);
  }

  static void _showFixedSnackBar(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}
