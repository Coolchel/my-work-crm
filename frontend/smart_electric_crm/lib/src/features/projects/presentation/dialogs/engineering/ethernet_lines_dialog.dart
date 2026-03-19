import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_dialog_scrollbar.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/shared/presentation/utils/error_feedback.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';
import '../../utils/shield_ui_palette.dart';

class EthernetLinesDialog extends StatefulWidget {
  final String projectId;
  final int shieldId;
  final int currentLinesCount;
  final Color themeColor;

  const EthernetLinesDialog({
    required this.projectId,
    required this.shieldId,
    required this.currentLinesCount,
    required this.themeColor,
    super.key,
  });

  @override
  State<EthernetLinesDialog> createState() => _EthernetLinesDialogState();
}

class _EthernetLinesDialogState extends State<EthernetLinesDialog> {
  static const List<int> _quickValues = [1, 2, 4, 6, 8, 10];

  late TextEditingController _linesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _linesController = TextEditingController(
        text: widget.currentLinesCount > 0
            ? widget.currentLinesCount.toString()
            : '');
  }

  @override
  void dispose() {
    _linesController.dispose();
    super.dispose();
  }

  void _selectQuickValue(int value) {
    _linesController.text = value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.themeColor;
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      child: Text(
                        "Ethernet линии",
                        style: textStyles.dialogTitle.copyWith(
                          color: scheme.onSurface,
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

              // Content
              Flexible(
                child: AppDialogScrollbar.builder(
                  builder: (scrollController) => SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(
                        left: 24, right: 24, top: 24, bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Выберите типовое значение или введите свое количество ниже.",
                          style: textStyles.secondaryBody.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickValues.map((value) {
                            return SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                onPressed: () => _selectQuickValue(value),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  side: BorderSide(
                                    color: ShieldUiPalette.blendAccentBorder(
                                      context,
                                      themeColor,
                                      lightOpacity: 0.22,
                                      darkOpacity: 0.34,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '$value',
                                  style: textStyles.bodyStrong.copyWith(
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _linesController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: "Количество линий UTP-5e",
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            hintText: "Например: 12",
                            hintStyle: textStyles.secondaryBody.copyWith(
                              color: scheme.onSurfaceVariant.withOpacity(0.72),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    ShieldUiPalette.neutralFieldBorder(context),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    ShieldUiPalette.neutralFieldBorder(context),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.only(
                    left: 24, right: 24, bottom: 24, top: 8),
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
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                try {
                                  final linesCount =
                                      int.tryParse(_linesController.text) ?? 0;
                                  await ref
                                      .read(engineeringRepositoryProvider)
                                      .updateShield(widget.shieldId, {
                                    'internet_lines_count': linesCount,
                                  });
                                  ref.invalidate(projectListProvider);
                                  ref.invalidate(
                                      projectByIdProvider(widget.projectId));
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e, st) {
                                  if (context.mounted) {
                                    debugPrint(
                                        'EthernetLinesDialog save failed: $e\n$st');
                                    await ErrorFeedback.show(
                                      context,
                                      e,
                                      fallbackMessage:
                                          'Не удалось сохранить количество линий.',
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSaving = false);
                                  }
                                }
                              },
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
                            : const Text('Сохранить'),
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
}
