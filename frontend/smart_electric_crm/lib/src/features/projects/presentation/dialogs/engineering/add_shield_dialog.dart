import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';

class AddShieldDialog extends StatefulWidget {
  final String projectId;
  const AddShieldDialog({required this.projectId, super.key});

  @override
  State<AddShieldDialog> createState() => _AddShieldDialogState();
}

class _AddShieldDialogState extends State<AddShieldDialog> {
  final _nameController = TextEditingController();
  String _type = 'power';
  String _mounting = 'internal';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить щит'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Название щита'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            items: const [
              DropdownMenuItem(value: 'power', child: Text('Силовой')),
              DropdownMenuItem(value: 'led', child: Text('LED')),
              DropdownMenuItem(value: 'multimedia', child: Text('Слаботочка')),
            ],
            onChanged: (v) => setState(() => _type = v!),
            decoration: const InputDecoration(labelText: 'Тип'),
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
                          .addShield(widget.projectId, {
                        'name': _nameController.text,
                        'shield_type': _type,
                        'mounting': _mounting,
                      });
                      ref.invalidate(projectListProvider);
                      ref.invalidate(projectByIdProvider(widget.projectId));
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      // Error
                    }
                  },
                  child: const Text('Создать'),
                );
              }),
            ),
          ],
        )
      ],
    );
  }
}
