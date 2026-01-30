import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';

class ApplyTemplateDialog extends ConsumerWidget {
  final String projectId;
  final int shieldId;
  final String type;

  const ApplyTemplateDialog(
      {required this.projectId,
      required this.shieldId,
      required this.type,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = type == 'shield'
        ? ref.watch(shieldTemplatesProvider)
        : ref.watch(ledTemplatesProvider);

    return AlertDialog(
      title: const Text('Применить шаблон'),
      content: templatesAsync.when(
        data: (templates) => SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                // Dynamic cast hack for brevity
                final t = templates[index] as dynamic;
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text(t.description),
                  onTap: () async {
                    Navigator.pop(context);
                    if (type == 'shield') {
                      await ref
                          .read(engineeringRepositoryProvider)
                          .applyShieldTemplate(shieldId, t.id);
                    } else {
                      await ref
                          .read(engineeringRepositoryProvider)
                          .applyLedTemplate(shieldId, t.id);
                    }
                    ref.invalidate(projectListProvider);
                  },
                );
              },
            )),
        loading: () => const SizedBox(
            height: 100, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Error: $e'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена')),
      ],
    );
  }
}
