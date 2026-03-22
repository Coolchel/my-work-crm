import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/desktop_dialog_foundation.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_dialog_scrollbar.dart';
import 'package:smart_electric_crm/src/shared/presentation/utils/error_feedback.dart';

import '../../providers/project_providers.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../shared/presentation/widgets/friendly_empty_state.dart';

class AddStageDialog extends ConsumerStatefulWidget {
  final String projectId;
  final List<String> existingStageKeys;

  const AddStageDialog({
    super.key,
    required this.projectId,
    required this.existingStageKeys,
  });

  @override
  ConsumerState<AddStageDialog> createState() => _AddStageDialogState();
}

class _AddStageDialogState extends ConsumerState<AddStageDialog> {
  bool _isLoading = false;

  final Map<String, String> _allStages = {
    'precalc': 'Предпросчет',
    'stage_1': 'Этап 1 (Черновой)',
    'stage_1_2': 'Этап 1+2 (Черновой)',
    'stage_2': 'Этап 2 (Черновой)',
    'stage_3': 'Этап 3 (Чистовой)',
    'extra': 'Доп. работы',
    'other': 'Другое',
  };

  Map<String, String> get _availableStages {
    final available = Map<String, String>.from(_allStages);
    for (final key in widget.existingStageKeys) {
      if (key != 'extra' &&
          key != 'other' &&
          key != 'precalc' &&
          key != 'stage_1_2' &&
          key != 'stage_3') {
        available.remove(key);
      }
    }
    return available;
  }

  Future<void> _addStage(String stageKey) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(projectOperationsProvider.notifier)
          .addStage(widget.projectId, stageKey);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Этап успешно добавлен')),
        );
      }
    } catch (e, st) {
      if (mounted) {
        debugPrint('AddStageDialog._addStage failed: $e\n$st');
        await ErrorFeedback.show(
          context,
          e,
          fallbackMessage: 'Не удалось добавить этап. Попробуйте снова.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (usesDesktopDialogFoundation(context)) {
      return _buildDesktopDialog(context);
    }
    return _buildMobileDialog(context);
  }

  Widget _buildDesktopDialog(BuildContext context) {
    final stages = _availableStages;
    const themeColor = Colors.indigo;

    return DesktopDialogShell(
      title: 'Добавить этап',
      accentColor: themeColor,
      maxWidth: 440,
      onClose: () => Navigator.of(context).pop(),
      actions: _isLoading
          ? const []
          : [
              DesktopDialogSecondaryButton(
                onPressed: () => Navigator.of(context).pop(),
                label: stages.isEmpty ? 'Закрыть' : 'Отмена',
                accentColor: themeColor,
              ),
            ],
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 56),
              child: Center(child: CircularProgressIndicator()),
            )
          : stages.isEmpty
              ? const FriendlyEmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Все основные этапы уже созданы',
                  subtitle: 'При необходимости добавьте дополнительный этап.',
                  accentColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 12),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in stages.entries) ...[
                      _StageChoiceTile(
                        title: entry.value,
                        color: _resolveStageColor(entry.key),
                        onTap: () => _addStage(entry.key),
                      ),
                      if (entry.key != stages.entries.last.key)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
    );
  }

  Widget _buildMobileDialog(BuildContext context) {
    final stages = _availableStages;
    const themeColor = Colors.indigo;
    final textStyles = context.appTextStyles;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppDesignTokens.cardBorder(context)),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: themeColor.withOpacity(0.1)),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Выберите этап',
                    style: textStyles.dialogTitle.copyWith(
                      color: themeColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(
                                AppDesignTokens.isDark(context) ? 0.22 : 0.5,
                              ),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: themeColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (stages.isEmpty)
              const FriendlyEmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Все основные этапы уже созданы',
                subtitle: 'При необходимости добавьте дополнительный этап.',
                accentColor: Colors.green,
                padding: EdgeInsets.all(20),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: AppDialogScrollbar.builder(
                  builder: (scrollController) => ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount: stages.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = stages.entries.elementAt(index);
                      return _StageChoiceTile(
                        title: entry.value,
                        color: _resolveStageColor(entry.key),
                        onTap: () => _addStage(entry.key),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _resolveStageColor(String stageKey) {
    switch (stageKey) {
      case 'precalc':
        return Colors.blueGrey;
      case 'stage_1':
      case 'stage_1_2':
      case 'stage_2':
        return Colors.blue;
      case 'stage_3':
        return Colors.green;
      case 'extra':
        return Colors.purple;
      default:
        return Colors.amber;
    }
  }
}

class _StageChoiceTile extends StatefulWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _StageChoiceTile({
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  State<_StageChoiceTile> createState() => _StageChoiceTileState();
}

class _StageChoiceTileState extends State<_StageChoiceTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    final isDesktopDialog = usesDesktopDialogFoundation(context);
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = isDesktopDialog
        ? widget.color.withOpacity(_isHovered ? 0.10 : 0.05)
        : AppDesignTokens.cardBackground(context, hovered: _isHovered);
    final borderColor = isDesktopDialog
        ? widget.color.withOpacity(_isHovered ? 0.32 : 0.18)
        : AppDesignTokens.cardBorder(context, hovered: _isHovered);
    final iconBackground = isDesktopDialog
        ? widget.color.withOpacity(0.12)
        : widget.color.withOpacity(0.08);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
          ),
          boxShadow: isDesktopDialog
              ? null
              : [
                  BoxShadow(
                    color: AppDesignTokens.cardShadow(context,
                        hovered: _isHovered),
                    blurRadius: _isHovered ? 10 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            hoverColor: isDesktopDialog
                ? widget.color.withOpacity(0.04)
                : Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isDesktopDialog ? 12 : 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: (isDesktopDialog
                              ? textStyles.body
                              : textStyles.cardTitle)
                          .copyWith(
                        fontSize: 14,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, size: 18, color: widget.color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
