import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/desktop_dialog_foundation.dart';
import 'package:smart_electric_crm/src/shared/presentation/utils/error_feedback.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_popup_select_field.dart';

import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';

class EditShieldDialog extends StatefulWidget {
  final ShieldModel shield;
  final String projectId;

  const EditShieldDialog({
    required this.shield,
    required this.projectId,
    super.key,
  });

  @override
  State<EditShieldDialog> createState() => _EditShieldDialogState();
}

class _EditShieldDialogState extends State<EditShieldDialog> {
  late TextEditingController _nameController;
  late String _mounting;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shield.name);
    _mounting = widget.shield.mounting;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(WidgetRef ref) async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    final shieldName =
        _nameController.text.isEmpty ? 'Щит квартирный' : _nameController.text;

    try {
      await ref.read(engineeringRepositoryProvider).updateShield(
        widget.shield.id,
        {
          'name': shieldName,
          'mounting': _mounting,
        },
      );
      ref.invalidate(projectListProvider);
      ref.invalidate(projectByIdProvider(widget.projectId));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      if (mounted) {
        debugPrint('EditShieldDialog save failed: $e\n$st');
        await ErrorFeedback.show(
          context,
          e,
          fallbackMessage: 'Не удалось сохранить изменения щита.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
        hoverColor: themeColor.withOpacity(isDark ? 0.24 : 0.10),
        highlightColor: themeColor.withOpacity(isDark ? 0.18 : 0.08),
      ),
      child: usesDesktopDialogFoundation(context)
          ? _buildDesktopDialog(context, themeColor)
          : _buildMobileDialog(context, themeColor),
    );
  }

  Widget _buildDesktopDialog(BuildContext context, Color themeColor) {
    return DesktopDialogShell(
      title: 'Редактировать щит',
      accentColor: themeColor,
      maxWidth: 460,
      onClose: () => Navigator.of(context).pop(),
      actions: [
        DesktopDialogSecondaryButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          label: 'Отмена',
          accentColor: themeColor,
        ),
        Consumer(
          builder: (context, ref, _) => DesktopDialogPrimaryButton(
            onPressed: _isSaving ? null : () => _save(ref),
            accentColor: themeColor,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Сохранить'),
          ),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesktopDialogTextField(
            controller: _nameController,
            label: 'Название щита',
            accentColor: themeColor,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          _buildMountingDropdown(themeColor),
        ],
      ),
    );
  }

  Widget _buildMobileDialog(BuildContext context, Color themeColor) {
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      'Редактировать щит',
                      style: textStyles.dialogTitle.copyWith(
                        color: themeColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: themeColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Название щита',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: 'Щит квартирный',
                      hintStyle: textStyles.secondaryBody.copyWith(
                        color: scheme.onSurfaceVariant.withOpacity(0.75),
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
                        borderSide: BorderSide(color: themeColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMountingDropdown(themeColor),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, _) => FilledButton(
                      onPressed: _isSaving ? null : () => _save(ref),
                      style: FilledButton.styleFrom(
                        backgroundColor: themeColor,
                        minimumSize: const Size(120, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMountingDropdown(Color themeColor) {
    return AppPopupSelectField<String>(
      fieldLabel: 'Монтаж',
      valueLabel: _getMountingLabel(_mounting),
      accentColor: themeColor,
      items: buildPopupMenuEntriesWithDividers([
        PopupMenuItem(
          value: 'internal',
          height: 40,
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.door_front_door,
                  color: Colors.indigo.shade400,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text('Внутренний', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: 'external',
          height: 40,
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.apartment,
                  color: Colors.indigo.shade400,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text('Наружный', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ]),
      onSelected: (value) => setState(() => _mounting = value),
    );
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
