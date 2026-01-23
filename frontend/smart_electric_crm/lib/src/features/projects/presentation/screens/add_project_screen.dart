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
  final _clientInfoController = TextEditingController();
  final _sourceController = TextEditingController();
  String _objectType = 'new_building';

  // Состояние чекбоксов для начальных этапов
  final Map<String, bool> _selectedStages = {
    'stage_1': false,
    'stage_2': false,
    'stage_3': false,
    'extra': false,
  };

  // Маппинг для отображения названий чекбоксов
  final Map<String, String> _stageLabels = {
    'stage_1': 'Этап 1 (Черновой)',
    'stage_2': 'Этап 2 (Черновой)',
    'stage_3': 'Этап 3 (Чистовой)',
    'extra': 'Доп. работы',
  };

  @override
  void dispose() {
    _addressController.dispose();
    _clientInfoController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Собираем список ключей выбранных этапов для init_stages
      // Пример: если выбраны stage_1 и extra, получим ['stage_1', 'extra']
      final initStages = _selectedStages.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final data = {
        'address': _addressController.text,
        'object_type': _objectType,
        'client_info': _clientInfoController.text,
        'source': _sourceController.text,
        'init_stages': initStages, // Отправляем список этапов на бэкенд
      };

      await ref.read(projectListProvider.notifier).addProject(data);

      if (mounted) {
        Navigator.pop(context); // Возвращаемся назад
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
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Адрес
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

                    // Тип объекта
                    DropdownButtonFormField<String>(
                      value: _objectType,
                      decoration: const InputDecoration(
                        labelText: 'Тип объекта',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'new_building', child: Text('Новостройка')),
                        DropdownMenuItem(
                            value: 'secondary', child: Text('Вторичка')),
                        DropdownMenuItem(
                            value: 'cottage', child: Text('Коттедж')),
                        DropdownMenuItem(value: 'office', child: Text('Офис')),
                        DropdownMenuItem(value: 'other', child: Text('Другое')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _objectType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Контактные данные
                    TextFormField(
                      controller: _clientInfoController,
                      decoration: const InputDecoration(
                        labelText: 'Контактные данные',
                        border: OutlineInputBorder(),
                        hintText: 'Имя, телефон...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Источник
                    TextFormField(
                      controller: _sourceController,
                      decoration: const InputDecoration(
                        labelText: 'Источник',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Чекбоксы этапов
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

                    // Кнопка создания
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitForm,
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Создать объект'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
