import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../../data/models/project_model.dart';

/// Premium Dialog for creating/editing a project.
/// Style consistent with AddShieldDialog.
class AddProjectDialog extends ConsumerStatefulWidget {
  final ProjectModel? project;

  const AddProjectDialog({super.key, this.project});

  @override
  ConsumerState<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends ConsumerState<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _addressController = TextEditingController();
  final _intercomController = TextEditingController();
  final _clientInfoController = TextEditingController();
  String _objectType = 'new_building';
  String _source = 'Владимир';

  // Toggleable stages for creation
  final Map<String, bool> _selectedStages = {
    'precalc': false,
    'stage_1': false,
    'stage_1_2': false,
    'stage_2': false,
    'stage_3': false,
    'extra': false,
  };

  static const _stageLabels = {
    'precalc': 'Предпросчет',
    'stage_1': 'Этап 1',
    'stage_1_2': 'Этап 1+2',
    'stage_2': 'Этап 2',
    'stage_3': 'Этап 3',
    'extra': 'Доп.',
  };

  static const _stageIcons = {
    'precalc': Icons.calculate_outlined,
    'stage_1': Icons.looks_one_outlined,
    'stage_1_2': Icons.join_full_outlined,
    'stage_2': Icons.looks_two_outlined,
    'stage_3': Icons.looks_3_outlined,
    'extra': Icons.add_circle_outline,
  };

  static const _objectTypes = {
    'new_building': 'Новостройка',
    'secondary': 'Вторичка',
    'cottage': 'Коттедж',
    'office': 'Офис',
    'other': 'Другое',
  };

  static const _objectTypeIcons = {
    'new_building': Icons.apartment,
    'secondary': Icons.home,
    'cottage': Icons.villa,
    'office': Icons.business,
    'other': Icons.category,
  };

  static const _sourceItems = ['Владимир', 'Другое'];
  static const _sourceIcons = {
    'Владимир': Icons.person,
    'Другое': Icons.group,
  };

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      final p = widget.project!;
      _addressController.text = p.address;
      _intercomController.text = p.intercomCode;
      _clientInfoController.text = p.clientInfo;
      _objectType = p.objectType;
      if (p.source.isNotEmpty) _source = p.source;
    }
  }

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
      if (!_isEditing) {
        final initStages = _selectedStages.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

        final data = {
          'address': _addressController.text,
          'object_type': _objectType,
          'intercom_code': _intercomController.text,
          'client_info': _clientInfoController.text,
          'source': _source,
          'init_stages': initStages,
        };

        await ref.read(projectOperationsProvider.notifier).addProject(data);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Объект успешно создан')),
          );
        }
      } else {
        final data = {
          'address': _addressController.text,
          'object_type': _objectType,
          'intercom_code': _intercomController.text,
          'client_info': _clientInfoController.text,
          'source': _source,
        };

        await ref.read(projectOperationsProvider.notifier).updateProject(
              widget.project!.id.toString(),
              data,
            );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Изменения сохранены')),
          );
        }
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
    const themeColor = Colors.indigo;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: themeColor),
      ),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ───
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        _isEditing ? 'Редактировать объект' : 'Новый объект',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Tooltip(
                        message: 'Закрыть',
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: themeColor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Content ───
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Адрес
                          _buildTextField(
                            controller: _addressController,
                            label: 'Адрес объекта',
                            hint: 'ул. Примерная, д. 1, кв. 1',
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Введите адрес'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // 2. Код домофона
                          _buildTextField(
                            controller: _intercomController,
                            label: 'Код домофона',
                            hint: '123',
                          ),
                          const SizedBox(height: 16),

                          // 3. Заказчик
                          _buildTextField(
                            controller: _clientInfoController,
                            label: 'Заказчик',
                            hint: 'Имя, телефон...',
                          ),
                          const SizedBox(height: 16),

                          // 4. Тип объекта
                          _buildFieldLabel('Тип объекта'),
                          _buildPopupBtn(
                            _objectTypes[_objectType] ?? _objectType,
                            _objectTypes.entries
                                .map((e) => PopupMenuItem(
                                      value: e.key,
                                      height: 40,
                                      padding: EdgeInsets.zero,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _objectTypeIcons[e.key] ??
                                                  Icons.domain,
                                              color: Colors.indigo.shade400,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(e.value,
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                            (v) => setState(() => _objectType = v),
                          ),
                          const SizedBox(height: 16),

                          // 5. Источник
                          _buildFieldLabel('Источник'),
                          _buildPopupBtn(
                            _source,
                            _sourceItems
                                .map((s) => PopupMenuItem(
                                      value: s,
                                      height: 40,
                                      padding: EdgeInsets.zero,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _sourceIcons[s] ?? Icons.person,
                                              color: Colors.indigo.shade400,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(s,
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                            (v) => setState(() => _source = v),
                          ),

                          // Stages selection (creation only) — toggle chips
                          if (!_isEditing) ...[
                            const SizedBox(height: 20),
                            _buildFieldLabel('Начальные этапы'),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _stageLabels.entries.map((entry) {
                                final isSelected =
                                    _selectedStages[entry.key] ?? false;
                                return _StageToggleChip(
                                  label: entry.value,
                                  icon: _stageIcons[entry.key] ??
                                      Icons.layers_outlined,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedStages[entry.key] = !isSelected;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // ─── Footer ───
              if (!_isLoading)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.black87),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submitForm,
                        style: FilledButton.styleFrom(
                          backgroundColor: themeColor,
                          minimumSize: const Size(120, 44),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(_isEditing ? 'Сохранить' : 'Создать'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    const themeColor = Colors.indigo;
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.35)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: themeColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.indigo.shade700,
        ),
      ),
    );
  }

  Widget _buildPopupBtn(String label, List<PopupMenuEntry<String>> items,
      ValueChanged<String> onSelected) {
    const bg = Colors.indigo;
    final fieldColor = Colors.indigo.shade50;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bg.withOpacity(0.15)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset position = box.localToGlobal(Offset.zero);
                final Size size = box.size;

                showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    position.dx,
                    position.dy + size.height + 4,
                    position.dx + size.width,
                    position.dy + size.height + 300,
                  ),
                  items: items,
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  surfaceTintColor: Colors.transparent,
                  color: fieldColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  constraints: BoxConstraints(
                    minWidth: size.width,
                    maxWidth: size.width,
                  ),
                ).then((value) {
                  if (value != null) onSelected(value);
                });
              },
              borderRadius: BorderRadius.circular(12),
              mouseCursor: SystemMouseCursors.click,
              hoverColor: bg.shade700.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: bg.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: bg.shade800, size: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Stage Toggle Chip ─────────────────────────────────────────

class _StageToggleChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StageToggleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StageToggleChip> createState() => _StageToggleChipState();
}

class _StageToggleChipState extends State<_StageToggleChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const themeColor = Colors.indigo;
    final isSelected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? themeColor.withOpacity(0.12)
                : (_isHovered ? Colors.grey.shade100 : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? themeColor.withOpacity(0.4)
                  : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: isSelected ? themeColor : Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected ? themeColor.shade700 : Colors.grey.shade600,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check, size: 14, color: themeColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
