import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/errors/user_friendly_error_mapper.dart';

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
    String title = 'Ошибка',
  }) async {
    if (!context.mounted) return;

    if (ModalRoute.of(context) is PopupRoute<dynamic>) {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          final isNetworkIssue =
              message.toLowerCase().contains('нет подключения');
          final isFailure = title.toLowerCase().contains('ошибка') ||
              message.toLowerCase().contains('не удалось') ||
              message.toLowerCase().contains('ошибка');
          final themeColor = isFailure
              ? Colors.red
              : isNetworkIssue
                  ? Colors.deepOrange
                  : Colors.indigo;
          final isDark = AppDesignTokens.isDark(dialogContext);

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Theme.of(dialogContext).colorScheme.surface,
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
                          isFailure
                              ? Icons.error_outline
                              : isNetworkIssue
                                  ? Icons.wifi_off_rounded
                                  : Icons.info_outline,
                          color: themeColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(dialogContext).colorScheme.onSurface,
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
                        label: const Text('Понятно'),
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
