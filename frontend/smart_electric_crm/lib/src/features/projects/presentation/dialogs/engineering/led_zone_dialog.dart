import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/led_zone_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';

class LedZoneDialog extends StatefulWidget {
  final String projectId;
  final int shieldId;
  final LedZoneModel? zone;

  const LedZoneDialog(
      {required this.projectId, required this.shieldId, this.zone, super.key});

  @override
  State<LedZoneDialog> createState() => _LedZoneDialogState();
}

class _LedZoneDialogState extends State<LedZoneDialog> {
  late TextEditingController _transformerController;
  late TextEditingController _zoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _transformerController =
        TextEditingController(text: widget.zone?.transformer ?? '');
    _zoneController = TextEditingController(text: widget.zone?.zone ?? '');
  }

  @override
  void dispose() {
    _transformerController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.zone != null;
    return AlertDialog(
      title: Text(isEdit ? 'Редактировать LED зону' : 'Добавить LED зону'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _transformerController,
              decoration: const InputDecoration(
                labelText: 'Трансформатор / Блок питания',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _zoneController,
              decoration: const InputDecoration(
                labelText: 'Зона подсветки / Лента',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ],
        ),
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
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          try {
                            final data = {
                              'transformer': _transformerController.text,
                              'zone': _zoneController.text,
                            };
                            if (isEdit) {
                              await ref
                                  .read(engineeringRepositoryProvider)
                                  .updateLedZone(widget.zone!.id, data);
                            } else {
                              await ref
                                  .read(engineeringRepositoryProvider)
                                  .addLedZone(widget.shieldId, data);
                            }
                            ref.invalidate(projectListProvider);
                            ref.invalidate(
                                projectByIdProvider(widget.projectId));
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')));
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Сохранить'),
                );
              }),
            ),
          ],
        )
      ],
    );
  }
}
