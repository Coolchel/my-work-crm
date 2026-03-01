import 'package:flutter/material.dart';

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

    if (!context.mounted) {
      return;
    }

    if (ModalRoute.of(context) is PopupRoute<dynamic>) {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Ошибка'),
            content: Text(userMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Понятно'),
              ),
            ],
          );
        },
      );
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(userMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
