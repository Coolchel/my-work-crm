import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_group_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';

class ShieldGroupDialog extends StatefulWidget {
  final String projectId;
  final int shieldId;
  final ShieldGroupModel? group;

  const ShieldGroupDialog(
      {required this.projectId, required this.shieldId, this.group, super.key});

  @override
  State<ShieldGroupDialog> createState() => _ShieldGroupDialogState();
}

class _ShieldGroupDialogState extends State<ShieldGroupDialog> {
  late TextEditingController _zoneController;
  late TextEditingController _ratingController;
  late TextEditingController _polesController;
  late TextEditingController _quantityController;
  String _selectedDeviceType = 'circuit_breaker';
  bool _isSaving = false;

  final Map<String, String> _deviceTypes = {
    'circuit_breaker': 'Автомат',
    'diff_breaker': 'Диф.автомат',
    'rcd': 'УЗО',
    'relay': 'Реле напряжения',
    'contactor': 'Контактор',
    'load_switch': 'Выключатель нагрузки',
    'other': 'Другое',
  };

  @override
  void initState() {
    super.initState();
    debugPrint('ShieldGroupDialog: initState');
    try {
      _zoneController = TextEditingController(text: widget.group?.zone ?? '');
      _ratingController =
          TextEditingController(text: widget.group?.rating ?? '16A');
      _polesController =
          TextEditingController(text: widget.group?.poles ?? '1P');
      _quantityController =
          TextEditingController(text: (widget.group?.quantity ?? 1).toString());
      if (widget.group != null) {
        debugPrint('Editing group: ${widget.group!.id}');
        _selectedDeviceType = widget.group!.deviceType;
      }

      // Add listeners for smart normalization
      _ratingController.addListener(_normalizeRating);
      _polesController.addListener(_normalizePoles);
    } catch (e, stack) {
      debugPrint('Error in ShieldGroupDialog initState: $e\n$stack');
    }
  }

  void _normalizeRating() {
    String text = _ratingController.text;
    String newText = text.replaceAll(RegExp(r'а|a', caseSensitive: false), 'A');
    if (text != newText) {
      _ratingController.value = _ratingController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void _normalizePoles() {
    String text = _polesController.text;
    String newText = text.replaceAll(RegExp(r'п|p', caseSensitive: false), 'P');
    if (text != newText) {
      _polesController.value = _polesController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  @override
  void dispose() {
    _zoneController.dispose();
    _ratingController.dispose();
    _polesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.group != null;
    return AlertDialog(
      title: Text(isEdit ? 'Редактировать группу' : 'Добавить группу'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _deviceTypes.containsKey(_selectedDeviceType)
                  ? _selectedDeviceType
                  : 'circuit_breaker',
              items: _deviceTypes.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDeviceType = v!),
              decoration: const InputDecoration(
                labelText: 'Тип устройства',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ratingController,
                    decoration: InputDecoration(
                      labelText: 'Номинал',
                      border: const OutlineInputBorder(),
                      suffixIcon: PopupMenuButton<String>(
                        tooltip: 'Показать',
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (String value) {
                          _ratingController.text = value;
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            '6A',
                            '10A',
                            '16A',
                            '20A',
                            '25A',
                            '32A',
                            '40A',
                            '50A',
                            '63A',
                            '80A'
                          ].map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _polesController,
                    decoration: InputDecoration(
                      labelText: 'Полюса',
                      border: const OutlineInputBorder(),
                      suffixIcon: PopupMenuButton<String>(
                        tooltip: 'Показать',
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (String value) {
                          _polesController.text = value;
                        },
                        itemBuilder: (BuildContext context) {
                          return ['1P', '2P', '3P', '4P'].map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _zoneController,
              decoration: const InputDecoration(
                labelText: 'Зона / Потребитель',
                hintText: 'Например: Кухня',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Количество',
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
                              'device_type': _selectedDeviceType,
                              'rating': _ratingController.text,
                              'poles': _polesController.text,
                              'zone': _zoneController.text,
                              'quantity':
                                  int.tryParse(_quantityController.text) ?? 1,
                            };
                            if (isEdit) {
                              await ref
                                  .read(engineeringRepositoryProvider)
                                  .updateShieldGroup(widget.group!.id, data);
                            } else {
                              await ref
                                  .read(engineeringRepositoryProvider)
                                  .addShieldGroup(widget.shieldId, data);
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
