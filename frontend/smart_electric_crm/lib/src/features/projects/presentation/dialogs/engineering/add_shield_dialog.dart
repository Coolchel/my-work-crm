import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_dialog_scrollbar.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_popup_select_field.dart';
import 'package:smart_electric_crm/src/shared/presentation/utils/error_feedback.dart';
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
  final ScrollController _scrollController = ScrollController();
  String _type = 'power';
  String _mounting = 'internal';

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Colors.indigo;
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: themeColor),
        hoverColor: themeColor.withOpacity(isDark ? 0.24 : 0.10),
        highlightColor: themeColor.withOpacity(isDark ? 0.18 : 0.08),
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
                    )
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
                              "Добавить щит",
                              style: textStyles.dialogTitle.copyWith(
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
                    Flexible(
                      child: AppDialogScrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: "Название щита",
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  hintText: "Щит квартирный",
                                  hintStyle: textStyles.secondaryBody.copyWith(
                                    color: scheme.onSurfaceVariant
                                        .withOpacity(0.75),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: themeColor.withOpacity(0.2)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: themeColor.withOpacity(0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: themeColor, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Type Dropdown
                              AppPopupSelectField<String>(
                                fieldLabel: "Тип",
                                valueLabel: _getTypeLabel(_type),
                                items: buildPopupMenuEntriesWithDividers([
                                  PopupMenuItem(
                                    value: 'power',
                                    height: 40,
                                    mouseCursor: SystemMouseCursors.click,
                                    padding: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
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
                                  PopupMenuItem(
                                    value: 'multimedia',
                                    height: 40,
                                    mouseCursor: SystemMouseCursors.click,
                                    padding: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
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
                                  PopupMenuItem(
                                    value: 'led',
                                    height: 40,
                                    mouseCursor: SystemMouseCursors.click,
                                    padding: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
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
                                ]),
                                onSelected: (value) =>
                                    setState(() => _type = value),
                              ),
                              const SizedBox(height: 16),
                              // Mounting Dropdown
                              AppPopupSelectField<String>(
                                fieldLabel: "Монтаж",
                                valueLabel: _getMountingLabel(_mounting),
                                items: buildPopupMenuEntriesWithDividers([
                                  PopupMenuItem(
                                    value: 'internal',
                                    height: 40,
                                    mouseCursor: SystemMouseCursors.click,
                                    padding: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
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
                                  PopupMenuItem(
                                    value: 'external',
                                    height: 40,
                                    mouseCursor: SystemMouseCursors.click,
                                    padding: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
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
                                ]),
                                onSelected: (value) =>
                                    setState(() => _mounting = value),
                              ),
                            ],
                          ),
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
                            style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.onSurface),
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
                                } catch (e, st) {
                                  if (context.mounted) {
                                    debugPrint(
                                        'AddShieldDialog save failed: $e\n$st');
                                    await ErrorFeedback.show(
                                      context,
                                      e,
                                      fallbackMessage:
                                          'Не удалось добавить щит. Попробуйте снова.',
                                    );
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
}
