import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_dialog_scrollbar.dart';
import 'package:smart_electric_crm/src/shared/presentation/utils/error_feedback.dart';
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
  final ScrollController _scrollController = ScrollController();
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
    _scrollController.dispose();
    _addressController.dispose();
    _intercomController.dispose();
    _clientInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;
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
        }
      }
    } catch (e, st) {
      if (mounted) {
        debugPrint('AddProjectDialog._submitForm failed: $e\n$st');
        await ErrorFeedback.show(
          context,
          e,
          fallbackMessage: _isEditing
              ? 'Не удалось сохранить объект. Попробуйте снова.'
              : 'Не удалось создать объект. Попробуйте снова.',
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Colors.indigo;
    final isDark = AppDesignTokens.isDark(context);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: themeColor),
      ),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 450,
                maxHeight: constraints.maxHeight * 0.86,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.34)
                          : Colors.black.withOpacity(0.12),
                      blurRadius: isDark ? 12 : 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
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
                              _isEditing
                                  ? 'Редактировать объект'
                                  : 'Новый объект',
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
                                icon:
                                    const Icon(Icons.close, color: themeColor),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Flexible(
                        child: AppDialogScrollbar(
                          controller: _scrollController,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. Address
                                  _buildTextField(
                                    controller: _addressController,
                                    label: 'Адрес объекта',
                                    hint: 'ул. Примерная, д. 1, кв. 1',
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Введите адрес'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // 2. Intercom code
                                  _buildTextField(
                                    controller: _intercomController,
                                    label: 'Код домофона',
                                    hint: '123',
                                  ),
                                  const SizedBox(height: 16),

                                  // 3. Client
                                  _buildTextField(
                                    controller: _clientInfoController,
                                    label: 'Заказчик',
                                    hint: 'Имя, телефон...',
                                  ),
                                  const SizedBox(height: 16),

                                  // 4. Object type
                                  _buildFieldLabel('Тип объекта'),
                                  _buildPopupBtn(
                                    _objectTypes[_objectType] ?? _objectType,
                                    _objectTypes.entries
                                        .map((e) => PopupMenuItem(
                                              value: e.key,
                                              height: 40,
                                              padding: EdgeInsets.zero,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      _objectTypeIcons[e.key] ??
                                                          Icons.domain,
                                                      color: Colors
                                                          .indigo.shade400,
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

                                  // 5. Source
                                  _buildFieldLabel('Источник'),
                                  _buildPopupBtn(
                                    _source,
                                    _sourceItems
                                        .map((s) => PopupMenuItem(
                                              value: s,
                                              height: 40,
                                              padding: EdgeInsets.zero,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      _sourceIcons[s] ??
                                                          Icons.person,
                                                      color: Colors
                                                          .indigo.shade400,
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

                                  // Stages selection (creation only) - toggle chips
                                  if (!_isEditing) ...[
                                    const SizedBox(height: 20),
                                    _buildFieldLabel('Начальные этапы'),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          _stageLabels.entries.map((entry) {
                                        final isSelected =
                                            _selectedStages[entry.key] ?? false;
                                        return _StageToggleChip(
                                          label: entry.value,
                                          icon: _stageIcons[entry.key] ??
                                              Icons.layers_outlined,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setState(() {
                                              _selectedStages[entry.key] =
                                                  !isSelected;
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
                      ),
                    // Footer
                    if (!_isLoading)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onSurface),
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
    final isDark = AppDesignTokens.isDark(context);
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.75)),
        fillColor: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainer.withOpacity(0.4),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppDesignTokens.softBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppDesignTokens.softBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: themeColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    final textStyles = context.appTextStyles;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: textStyles.fieldLabel.copyWith(
          fontSize: 12.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPopupBtn(String label, List<PopupMenuEntry<String>> items,
      ValueChanged<String> onSelected) {
    const bg = Colors.indigo;
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final popupBackgroundColor =
        isDark ? AppDesignTokens.surface2(context) : scheme.surfaceContainer;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppDesignTokens.surface2(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppDesignTokens.softBorder(context)),
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
                  shadowColor: AppDesignTokens.cardShadow(context),
                  surfaceTintColor: Colors.transparent,
                  color: popupBackgroundColor,
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
              hoverColor: bg.shade700.withOpacity(isDark ? 0.12 : 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? scheme.onSurface : bg.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down,
                        color: isDark ? scheme.onSurfaceVariant : bg.shade800,
                        size: 24),
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

// Stage Toggle Chip

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
    final isDark = AppDesignTokens.isDark(context);
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
                : (_isHovered
                    ? (isDark
                        ? Theme.of(context).colorScheme.surfaceContainerHigh
                        : Colors.grey.shade100)
                    : (isDark
                        ? Theme.of(context).colorScheme.surfaceContainer
                        : Colors.grey.shade50)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? themeColor.withOpacity(0.4)
                  : AppDesignTokens.softBorder(context),
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
