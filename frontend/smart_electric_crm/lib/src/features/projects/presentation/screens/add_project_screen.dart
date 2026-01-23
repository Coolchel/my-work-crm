import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';

class AddProjectScreen extends ConsumerStatefulWidget {
  const AddProjectScreen({super.key});

  @override
  ConsumerState<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends ConsumerState<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Поля формы
  final _addressController = TextEditingController();
  final _intercomController = TextEditingController();
  final _clientInfoController = TextEditingController();
  String _objectType = 'new_building';
  String _source = 'Владимир';

  // Состояние чекбоксов для начальных этапов
  final Map<String, bool> _selectedStages = {
    'precalc': false,
    'stage_1': false,
    'stage_1_2': false,
    'stage_2': false,
    'stage_3': false,
    'extra': false,
  };

  // Маппинг для отображения названий чекбоксов
  final Map<String, String> _stageLabels = {
    'precalc': 'Предпросчет',
    'stage_1': 'Этап 1 (Черновой)',
    'stage_1_2': 'Этап 1+2 (Черновой)',
    'stage_2': 'Этап 2 (Черновой)',
    'stage_3': 'Этап 3 (Чистовой)',
    'extra': 'Доп. работы',
  };

  @override
  void dispose() {
    _addressController.dispose();
    _intercomController.dispose();
    _clientInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final initStages = _selectedStages.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final data = {
        'address': _addressController.text,
        'object_type': _objectType,
        'intercom_code': _intercomController.text,
        'client_info': _clientInfoController.text,
        'source': _source,
        'init_stages': initStages,
      };

      await ref.read(projectListProvider.notifier).addProject(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Объект успешно создан')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый объект'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Адрес объекта *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Введите адрес';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownMenu<String>(
                              width: constraints.maxWidth,
                              initialSelection: _objectType,
                              label: const Text('Тип объекта'),
                              dropdownMenuEntries: const [
                                DropdownMenuEntry(
                                    value: 'new_building',
                                    label: 'Новостройка'),
                                DropdownMenuEntry(
                                    value: 'secondary', label: 'Вторичка'),
                                DropdownMenuEntry(
                                    value: 'cottage', label: 'Коттедж'),
                                DropdownMenuEntry(
                                    value: 'office', label: 'Офис'),
                                DropdownMenuEntry(
                                    value: 'other', label: 'Другое'),
                              ],
                              onSelected: (value) {
                                if (value != null) {
                                  setState(() => _objectType = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _intercomController,
                              decoration: const InputDecoration(
                                labelText: 'Код домофона',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _clientInfoController,
                              decoration: const InputDecoration(
                                labelText: 'Заказчик',
                                border: OutlineInputBorder(),
                                hintText: 'Имя, телефон...',
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 16),
                            DropdownMenu<String>(
                              width: constraints.maxWidth,
                              initialSelection: _source,
                              label: const Text('Источник'),
                              dropdownMenuEntries: const [
                                DropdownMenuEntry(
                                    value: 'Владимир', label: 'Владимир'),
                                DropdownMenuEntry(
                                    value: 'Другое', label: 'Другое'),
                              ],
                              onSelected: (value) {
                                if (value != null) {
                                  setState(() => _source = value);
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Создать начальные этапы:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Column(
                                children: _stageLabels.keys.map((key) {
                                  return CheckboxListTile(
                                    title: Text(_stageLabels[key]!),
                                    value: _selectedStages[key],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _selectedStages[key] = value ?? false;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: SizedBox(
                                width: 250,
                                child: FilledButton(
                                  onPressed: _submitForm,
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12.0),
                                    child: Text('Создать объект'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}
