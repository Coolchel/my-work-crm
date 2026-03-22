import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/desktop_dialog_foundation.dart';
import 'package:smart_electric_crm/src/shared/presentation/utils/error_feedback.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_dialog_scrollbar.dart';

import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';
import '../../utils/shield_ui_palette.dart';

class ShieldNotesDialog extends StatefulWidget {
  final String projectId;
  final int shieldId;
  final String currentNotes;
  final Color themeColor;

  const ShieldNotesDialog({
    required this.projectId,
    required this.shieldId,
    required this.currentNotes,
    required this.themeColor,
    super.key,
  });

  @override
  State<ShieldNotesDialog> createState() => _ShieldNotesDialogState();
}

class _ShieldNotesDialogState extends State<ShieldNotesDialog> {
  late TextEditingController _notesController;
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.currentNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save(WidgetRef ref) async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(engineeringRepositoryProvider).updateShield(
        widget.shieldId,
        {'notes': _notesController.text.trim()},
      );
      ref.invalidate(projectListProvider);
      ref.invalidate(projectByIdProvider(widget.projectId));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      if (mounted) {
        debugPrint('ShieldNotesDialog save failed: $e\n$st');
        await ErrorFeedback.show(
          context,
          e,
          fallbackMessage: 'Не удалось сохранить заметку.',
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
    final themeColor = widget.themeColor;
    final isDark = AppDesignTokens.isDark(context);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: themeColor),
      ),
      child: usesDesktopDialogFoundation(context)
          ? _buildDesktopDialog(context, themeColor)
          : _buildMobileDialog(context, themeColor, isDark),
    );
  }

  Widget _buildDesktopDialog(BuildContext context, Color themeColor) {
    return DesktopDialogShell(
      title: 'Заметки щита',
      accentColor: themeColor,
      maxWidth: 540,
      onClose: () => Navigator.of(context).pop(),
      scrollController: _scrollController,
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
      child: TextField(
        controller: _notesController,
        autofocus: true,
        maxLines: 8,
        minLines: 5,
        decoration: desktopDialogInputDecoration(
          context,
          label: 'Заметки',
          hint: 'Введите заметку для этого щита...',
          accentColor: themeColor,
          alignLabelWithHint: true,
          contentPadding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        ),
      ),
    );
  }

  Widget _buildMobileDialog(
    BuildContext context,
    Color themeColor,
    bool isDark,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
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
                color: ShieldUiPalette.blendAccentSurface(
                  context,
                  themeColor,
                  baseColor: Theme.of(context).colorScheme.surface,
                  lightOpacity: 0.06,
                  darkOpacity: 0.16,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_alt_outlined,
                            size: 20, color: themeColor),
                        const SizedBox(width: 8),
                        Text(
                          'Заметка',
                          style: textStyles.dialogTitle.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
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
            Flexible(
              child: AppDialogScrollbar.builder(
                builder: (scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: TextField(
                    controller: _notesController,
                    autofocus: true,
                    maxLines: 6,
                    minLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Введите заметку для этого щита...',
                      hintStyle: textStyles.secondaryBody.copyWith(
                        color: scheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ShieldUiPalette.neutralFieldBorder(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ShieldUiPalette.neutralFieldBorder(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ShieldUiPalette.blendAccentBorder(
                            context,
                            themeColor,
                            lightOpacity: 0.34,
                            darkOpacity: 0.44,
                          ),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? scheme.surfaceContainerHigh
                          : Colors.grey.shade50,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 24,
                top: 8,
              ),
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
                        backgroundColor:
                            ShieldUiPalette.primaryActionBackground(
                          context,
                          themeColor,
                        ),
                        foregroundColor:
                            ShieldUiPalette.primaryActionForeground(context),
                        side: BorderSide(
                          color: ShieldUiPalette.blendAccentBorder(
                            context,
                            themeColor,
                            lightOpacity: 0.20,
                            darkOpacity: 0.34,
                          ),
                        ),
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
}
