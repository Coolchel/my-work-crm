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
  late TextEditingController _quantityController;
  String _selectedDeviceType = 'diff_breaker';
  String _selectedRating = '16A';
  String _selectedPoles = '1P';
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
      _selectedRating = widget.group?.rating ?? '16A';
      _selectedPoles = widget.group?.poles ?? '1P';
      _quantityController =
          TextEditingController(text: (widget.group?.quantity ?? 1).toString());
      if (widget.group != null) {
        debugPrint('Editing group: ${widget.group!.id}');
        _selectedDeviceType = widget.group!.deviceType;
      }
    } catch (e, stack) {
      debugPrint('Error in ShieldGroupDialog initState: $e\n$stack');
    }
  }

  @override
  void dispose() {
    _zoneController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.group != null;
    const themeColor = Colors.brown;

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
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                        isEdit ? "Редактировать группу" : "Добавить группу",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: themeColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Device Type Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              "Тип устройства",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.brown.shade700,
                              ),
                            ),
                          ),
                          _buildPopupBtn(
                            _deviceTypes[_selectedDeviceType] ?? 'Диф.автомат',
                            _deviceTypes.entries
                                .map((e) => PopupMenuItem<String>(
                                      value: e.key,
                                      height: 40,
                                      padding: EdgeInsets.zero,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        alignment: Alignment.centerLeft,
                                        child: Text(e.value,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ),
                                    ))
                                .toList(),
                            (value) =>
                                setState(() => _selectedDeviceType = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Rating and Poles Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    "Номинал",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.brown.shade700,
                                    ),
                                  ),
                                ),
                                _buildPopupBtn(
                                  _selectedRating,
                                  [
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
                                  ]
                                      .map((choice) => PopupMenuItem<String>(
                                            value: choice,
                                            height: 40,
                                            padding: EdgeInsets.zero,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.flash_on,
                                                      color: Colors
                                                          .orange.shade600,
                                                      size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(choice,
                                                      style: const TextStyle(
                                                          fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  (value) =>
                                      setState(() => _selectedRating = value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    "Полюса",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.brown.shade700,
                                    ),
                                  ),
                                ),
                                _buildPopupBtn(
                                  _selectedPoles,
                                  ['1P', '2P', '3P', '4P']
                                      .map((choice) => PopupMenuItem<String>(
                                            value: choice,
                                            height: 40,
                                            padding: EdgeInsets.zero,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.electric_bolt,
                                                      color:
                                                          Colors.blue.shade600,
                                                      size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(choice,
                                                      style: const TextStyle(
                                                          fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  (value) =>
                                      setState(() => _selectedPoles = value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _zoneController,
                        decoration: InputDecoration(
                          labelText: "Зона / Потребитель",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: "Например: Кухня",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: themeColor.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: themeColor.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Количество",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: "1",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: themeColor.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: themeColor.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.black87),
                      child: const Text("Отмена"),
                    ),
                    const SizedBox(width: 8),
                    Consumer(builder: (context, ref, _) {
                      return FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                try {
                                  final data = {
                                    'device_type': _selectedDeviceType,
                                    'rating': _selectedRating,
                                    'poles': _selectedPoles,
                                    'zone': _zoneController.text,
                                    'quantity': int.tryParse(
                                            _quantityController.text) ??
                                        1,
                                  };
                                  if (isEdit) {
                                    await ref
                                        .read(engineeringRepositoryProvider)
                                        .updateShieldGroup(
                                            widget.group!.id, data);
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
                                  if (mounted) {
                                    setState(() => _isSaving = false);
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: themeColor,
                          minimumSize: const Size(120, 44),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(isEdit ? 'Сохранить' : 'Добавить'),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupBtn(String label, List<PopupMenuEntry<String>> items,
      ValueChanged<String> onSelected) {
    const bg = Colors.brown;
    const fieldColor = Color(0xFFEFEBE9);

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

                // Configure Theme to remove dividers/decorations from showMenu
                showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    position.dx,
                    position.dy + size.height + 4, // 4px offset
                    position.dx + size.width,
                    position.dy + size.height + 300,
                  ),
                  items: items,
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  surfaceTintColor: Colors.transparent, // Disable M3 tint
                  color: fieldColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  constraints: BoxConstraints(
                    minWidth: size.width,
                    maxWidth: size.width,
                  ),
                ).then((value) {
                  if (value != null) {
                    onSelected(value);
                  }
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
