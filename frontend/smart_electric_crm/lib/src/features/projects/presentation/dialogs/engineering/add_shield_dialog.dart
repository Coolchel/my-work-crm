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
                        "Добавить щит",
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
                        message: "Закрыть",
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

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Название щита",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: "Щит квартирный",
                        hintStyle: TextStyle(
                          color: Colors.grey.withOpacity(0.35),
                        ),
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
                          borderSide:
                              const BorderSide(color: themeColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Type Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            "Тип",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ),
                        _buildPopupBtn(
                          _getTypeLabel(_type),
                          [
                            PopupMenuItem(
                              value: 'power',
                              height: 40,
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(Icons.bolt,
                                        color: Colors.indigo.shade400,
                                        size: 20),
                                    const SizedBox(width: 12),
                                    const Text('Силовой',
                                        style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'multimedia',
                              height: 40,
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(Icons.router,
                                        color: Colors.indigo.shade400,
                                        size: 20),
                                    const SizedBox(width: 12),
                                    const Text('Слаботочный',
                                        style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'led',
                              height: 40,
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(Icons.lightbulb,
                                        color: Colors.indigo.shade400,
                                        size: 20),
                                    const SizedBox(width: 12),
                                    const Text('LED',
                                        style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          (value) => setState(() => _type = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Mounting Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            "Монтаж",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ),
                        _buildPopupBtn(
                          _getMountingLabel(_mounting),
                          [
                            PopupMenuItem(
                              value: 'internal',
                              height: 40,
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(Icons.door_front_door,
                                        color: Colors.indigo.shade400,
                                        size: 20),
                                    const SizedBox(width: 12),
                                    const Text('Внутренний',
                                        style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'external',
                              height: 40,
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(Icons.apartment,
                                        color: Colors.indigo.shade400,
                                        size: 20),
                                    const SizedBox(width: 12),
                                    const Text('Наружный',
                                        style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          (value) => setState(() => _mounting = value),
                        ),
                      ],
                    ),
                  ],
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
                        onPressed: () async {
                          // Use default name if field is empty
                          final shieldName = _nameController.text.isEmpty
                              ? 'Щит квартирный'
                              : _nameController.text;
                          try {
                            await ref
                                .read(engineeringRepositoryProvider)
                                .addShield(widget.projectId, {
                              'name': shieldName,
                              'shield_type': _type,
                              'mounting': _mounting,
                            });
                            ref.invalidate(projectListProvider);
                            ref.invalidate(
                                projectByIdProvider(widget.projectId));
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            // Error
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
                        child: const Text('Добавить'),
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'power':
        return 'Силовой';
      case 'led':
        return 'LED';
      case 'multimedia':
        return 'Слаботочный';
      default:
        return '';
    }
  }

  String _getMountingLabel(String mounting) {
    switch (mounting) {
      case 'internal':
        return 'Внутренний';
      case 'external':
        return 'Наружный';
      default:
        return '';
    }
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
