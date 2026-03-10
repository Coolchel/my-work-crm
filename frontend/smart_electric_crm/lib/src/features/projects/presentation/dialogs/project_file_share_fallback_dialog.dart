import 'package:flutter/material.dart';

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

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Поделиться файлом'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message ??
                    'Автоматическое действие не сработало. Используйте ссылку ниже вручную.',
              ),
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
            child: const Text('Скопировать'),
          ),
          TextButton(
            onPressed: () {
              openUrlInBrowser(url);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Открыть'),
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
            child: const Text('Скачать'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      );
    },
  );
}
