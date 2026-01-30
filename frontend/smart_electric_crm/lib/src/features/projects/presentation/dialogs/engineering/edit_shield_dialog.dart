import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';

class EditShieldDialog extends StatefulWidget {
  final ShieldModel shield;
  final String projectId;
  const EditShieldDialog(
      {required this.shield, required this.projectId, super.key});

  @override
  State<EditShieldDialog> createState() => _EditShieldDialogState();
}

class _EditShieldDialogState extends State<EditShieldDialog> {
  late TextEditingController _nameController;
  late String _mounting;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shield.name);
    _mounting = widget.shield.mounting; // 'internal' or 'external'
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать щит'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Название щита'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _mounting,
            items: const [
              DropdownMenuItem(value: 'internal', child: Text('Внутренний')),
              DropdownMenuItem(value: 'external', child: Text('Наружный')),
            ],
            onChanged: (v) => setState(() => _mounting = v!),
            decoration: const InputDecoration(labelText: 'Монтаж'),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer(builder: (context, ref, _) {
                return FilledButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty) return;
                    try {
                      await ref
                          .read(engineeringRepositoryProvider)
                          .updateShield(widget.shield.id, {
                        'name': _nameController.text,
                        'mounting': _mounting,
                      });
                      ref.invalidate(projectListProvider);
                      // Force refresh project
                      ref.invalidate(projectByIdProvider(widget.projectId));
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка обновления: $e')));
                      }
                    }
                  },
                  child: const Text('Сохранить'),
                );
              }),
            ),
          ],
        )
      ],
    );
  }
}
