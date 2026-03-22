import 'package:flutter/material.dart';

import '../../../../shared/presentation/dialogs/desktop_dialog_foundation.dart';
import '../../services/project_file_browser_bridge.dart';
import '../../services/project_file_save_service.dart';
import '../../services/project_file_share_service.dart';

Future<void> showProjectFileShareFallbackDialog({
  required BuildContext context,
  required String url,
  required String displayName,
  required ProjectFileSaveService saveService,
  required ProjectFileShareService shareService,
  String? message,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  const fallbackMessage =
      '\u0410\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u043e\u0435 \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0435 \u043d\u0435 \u0441\u0440\u0430\u0431\u043e\u0442\u0430\u043b\u043e. \u0418\u0441\u043f\u043e\u043b\u044c\u0437\u0443\u0439\u0442\u0435 \u0441\u0441\u044b\u043b\u043a\u0443 \u043d\u0438\u0436\u0435 \u0432\u0440\u0443\u0447\u043d\u0443\u044e.';

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      if (usesDesktopDialogFoundation(dialogContext)) {
        final scheme = Theme.of(dialogContext).colorScheme;

        return DesktopDialogShell(
          title:
              '\u041f\u043e\u0434\u0435\u043b\u0438\u0442\u044c\u0441\u044f \u0444\u0430\u0439\u043b\u043e\u043c',
          accentColor: Colors.indigo,
          maxWidth: 520,
          actions: [
            TextButton(
              onPressed: () async {
                final result = await shareService.copyLink(url: url);
                if (!context.mounted) {
                  return;
                }
                if (result.isCopiedLink) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  messenger.showSnackBar(
                    SnackBar(content: Text(result.message)),
                  );
                  return;
                }
                messenger.showSnackBar(
                  SnackBar(content: Text(result.message)),
                );
              },
              child: const Text(
                  '\u0421\u043a\u043e\u043f\u0438\u0440\u043e\u0432\u0430\u0442\u044c'),
            ),
            TextButton(
              onPressed: () {
                openUrlInBrowser(url);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('\u041e\u0442\u043a\u0440\u044b\u0442\u044c'),
            ),
            TextButton(
              onPressed: () async {
                final result = await saveService.saveRemoteFile(
                  url: url,
                  displayName: displayName,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(result.message)),
                  );
                }
              },
              child: const Text('\u0421\u043a\u0430\u0447\u0430\u0442\u044c'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('\u0417\u0430\u043a\u0440\u044b\u0442\u044c'),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message ?? fallbackMessage,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: SelectableText(url),
              ),
            ],
          ),
        );
      }

      return AlertDialog(
        title: const Text(
            '\u041f\u043e\u0434\u0435\u043b\u0438\u0442\u044c\u0441\u044f \u0444\u0430\u0439\u043b\u043e\u043c'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message ?? fallbackMessage),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(url),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final result = await shareService.copyLink(url: url);
              if (!context.mounted) {
                return;
              }
              if (result.isCopiedLink) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                messenger.showSnackBar(
                  SnackBar(content: Text(result.message)),
                );
                return;
              }
              messenger.showSnackBar(
                SnackBar(content: Text(result.message)),
              );
            },
            child: const Text(
                '\u0421\u043a\u043e\u043f\u0438\u0440\u043e\u0432\u0430\u0442\u044c'),
          ),
          TextButton(
            onPressed: () {
              openUrlInBrowser(url);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('\u041e\u0442\u043a\u0440\u044b\u0442\u044c'),
          ),
          TextButton(
            onPressed: () async {
              final result = await saveService.saveRemoteFile(
                url: url,
                displayName: displayName,
              );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(result.message)),
                );
              }
            },
            child: const Text('\u0421\u043a\u0430\u0447\u0430\u0442\u044c'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('\u0417\u0430\u043a\u0440\u044b\u0442\u044c'),
          ),
        ],
      );
    },
  );
}
