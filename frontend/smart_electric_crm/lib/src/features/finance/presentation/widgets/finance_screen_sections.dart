part of '../screens/finance_screen.dart';

extension _FinanceScreenSections on _FinanceScreenState {
  Widget _buildProjectCard(UnpaidProjectModel project, int index) {
    final isExpanded = _expandedProjects[project.id] ?? false;
    final isHovered = _hoveredProjects[project.id] ?? false;
    final shouldHighlight = isHovered;
    final cardBackground = isExpanded
        ? (AppDesignTokens.isDark(context)
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Colors.grey.shade50)
        : AppDesignTokens.cardBackground(context, hovered: shouldHighlight);
    final isWideHeader = MediaQuery.of(context).size.width >= 1100;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setProjectHovered(project.id, true),
      onExit: (_) => _setProjectHovered(project.id, false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(_FinanceScreenState._cardRadius),
          border: Border.all(
            color: shouldHighlight
                ? _FinanceScreenState._financeAccent.withOpacity(0.24)
                : isExpanded
                    ? AppDesignTokens.cardBorder(context, hovered: true)
                    : AppDesignTokens.cardBorder(context),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: shouldHighlight
                  ? AppDesignTokens.cardShadow(context, hovered: true)
                  : AppDesignTokens.cardShadow(context),
              blurRadius: shouldHighlight ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_FinanceScreenState._cardRadius),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: _FinanceScreenState._financeAccent.withOpacity(0.72),
                ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _toggleProjectExpanded(project.id);
                      },
                      hoverColor: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _FinanceScreenState._financeAccent
                                        .withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$index',
                                    style: TextStyle(
                                      color: _FinanceScreenState._financeAccent
                                          .withOpacity(0.85),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isWideHeader)
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: _buildProjectAddressLine(
                                            address: project.address,
                                            source: project.source,
                                            singleLine: true,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildProjectMetaPill(
                                          icon: Icons.layers_outlined,
                                          text: '${project.stages.length}',
                                          active: true,
                                        ),
                                        const SizedBox(width: 10),
                                        _buildAmountDisplay(
                                          project.totalUsd,
                                          project.totalByn,
                                          fontSize: 11.5,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isExpanded
                                              ? Icons.expand_less_rounded
                                              : Icons.expand_more_rounded,
                                          color: Colors.grey.shade400,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: _buildProjectAddressLine(
                                                address: project.address,
                                                source: project.source,
                                                singleLine: false,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            _buildProjectMetaPill(
                                              icon: Icons.layers_outlined,
                                              text: '${project.stages.length}',
                                              active: true,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildAmountDisplay(
                                        project.totalUsd,
                                        project.totalByn,
                                        fontSize: 11.5,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      const SizedBox(height: 3),
                                      Icon(
                                        isExpanded
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded,
                                        color: Colors.grey.shade400,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isExpanded)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppDesignTokens.isDark(context)
                                    ? Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.52)
                                    : Colors.grey.shade100.withOpacity(0.9),
                                border: Border(
                                  top: BorderSide(
                                    color: AppDesignTokens.cardBorder(context,
                                        hovered: true),
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < project.stages.length;
                                      i++) ...[
                                    _buildStageRow(project, project.stages[i]),
                                    if (i < project.stages.length - 1)
                                      Divider(
                                        height: 4,
                                        thickness: 0.6,
                                        color: Colors.grey.shade200,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageRow(UnpaidProjectModel project, UnpaidStageModel stage) {
    final hasExternalAmount =
        stage.externalAmountUsd > 0 || stage.externalAmountByn > 0;
    final stageHoverKey = '${project.id}_${stage.id}';
    final isHovered = _hoveredStages[stageHoverKey] ?? false;
    final stageBackground =
        AppDesignTokens.cardBackground(context, hovered: isHovered);
    final stageBorderColor = isHovered
        ? _FinanceScreenState._financeAccent.withOpacity(0.24)
        : AppDesignTokens.cardBorder(context);
    final stageShadowColor = isHovered
        ? AppDesignTokens.cardShadow(context, hovered: true)
        : AppDesignTokens.cardShadow(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setStageHovered(stageHoverKey, true),
      onExit: (_) => _setStageHovered(stageHoverKey, false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: stageBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: stageBorderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: stageShadowColor,
              blurRadius: isHovered ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              final projects = ref.read(projectListProvider).valueOrNull;
              if (projects != null) {
                try {
                  final realProject =
                      projects.firstWhere((p) => p.id == project.id);
                  final realStage =
                      realProject.stages.firstWhere((s) => s.id == stage.id);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EstimateScreen(
                        projectId: realProject.id.toString(),
                        stage: realStage,
                      ),
                    ),
                  );
                } catch (e) {
                  debugPrint("Navigation error: $e");
                }
              }
            },
            borderRadius: BorderRadius.circular(10),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return AppDesignTokens.hoverOverlay(context);
              }
              if (states.contains(WidgetState.pressed)) {
                return AppDesignTokens.pressedOverlay(context);
              }
              return Colors.transparent;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color:
                          _FinanceScreenState._financeAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.engineering_outlined,
                      size: 12,
                      color:
                          _FinanceScreenState._financeAccent.withOpacity(0.8),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.titleDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (stage.updatedAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _getStageDateInfo(context, stage.updatedAt!).text,
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    _getStageDateInfo(context, stage.updatedAt!)
                                        .color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.end,
                        children: [
                          _buildStageAmountSummary(stage, hasExternalAmount),
                          _PayStageButton(
                            onPressed: () =>
                                _markStagePaid(stage.id, stage.titleDisplay),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageAmountSummary(
      UnpaidStageModel stage, bool hasExternalAmount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildAmountDisplay(stage.ourAmountUsd, stage.ourAmountByn,
            fontSize: 12),
        if (hasExternalAmount) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'из ${_formatExternalAmount(stage.ourAmountUsd + stage.externalAmountUsd, stage.ourAmountByn + stage.externalAmountByn)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 52,
            height: 3,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.grey[300]!, width: 0.5),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _calculateOurShareFactor(stage),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          _FinanceScreenState._financeAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceSuperscript(String text) {
    final isDark = AppDesignTokens.isDark(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppDesignTokens.cardBorder(context),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildProjectAddressLine({
    required String address,
    required String? source,
    required bool singleLine,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            address,
            maxLines: singleLine ? 1 : null,
            overflow: singleLine ? TextOverflow.ellipsis : TextOverflow.visible,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (source != null && source.isNotEmpty) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: _buildSourceSuperscript(source),
          ),
        ],
      ],
    );
  }

  Widget _buildProjectMetaPill({
    required IconData icon,
    required String text,
    required bool active,
    double? maxTextWidth,
  }) {
    final isDark = AppDesignTokens.isDark(context);
    final background = active
        ? _FinanceScreenState._financeAccent.withOpacity(isDark ? 0.22 : 0.1)
        : (isDark
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Colors.grey.shade100);
    final border = active
        ? _FinanceScreenState._financeAccent.withOpacity(isDark ? 0.40 : 0.28)
        : AppDesignTokens.cardBorder(context);
    final foreground =
        active ? _FinanceScreenState._financeAccent : Colors.grey.shade700;

    final label = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          if (maxTextWidth != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTextWidth),
              child: label,
            )
          else
            label,
        ],
      ),
    );
  }

  String _formatExternalAmount(double usd, double byn) {
    final parts = <String>[];
    if (usd > 0) parts.add('${usd.toStringAsFixed(0)}\$');
    if (byn > 0) parts.add('${byn.toStringAsFixed(0)}р');
    return parts.join(' + ');
  }

  _StageDateInfo _getStageDateInfo(BuildContext context, String dateString) {
    final scheme = Theme.of(context).colorScheme;
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return _StageDateInfo('Сегодня', scheme.onSurface);
      } else if (diff.inDays == 1) {
        return _StageDateInfo('Вчера', scheme.onSurfaceVariant);
      } else if (diff.inDays < 4) {
        return _StageDateInfo(
            '${diff.inDays} дн. назад', scheme.onSurfaceVariant);
      } else if (diff.inDays < 7) {
        return _StageDateInfo('${diff.inDays} дн. назад',
            scheme.onSurfaceVariant.withOpacity(0.9));
      } else {
        final formatted =
            '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
        return _StageDateInfo(
            formatted, scheme.onSurfaceVariant.withOpacity(0.9));
      }
    } catch (e) {
      return _StageDateInfo('', scheme.onSurfaceVariant);
    }
  }

  double _calculateOurShareFactor(UnpaidStageModel stage) {
    final totalUsd = stage.ourAmountUsd + stage.externalAmountUsd;
    final totalByn = stage.ourAmountByn + stage.externalAmountByn;

    if (totalUsd > 0) {
      return (stage.ourAmountUsd / totalUsd).clamp(0.0, 1.0);
    }
    if (totalByn > 0) {
      return (stage.ourAmountByn / totalByn).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  // Получить самую раннюю дату обновления из этапов проекта
  DateTime _getEarliestStageDate(UnpaidProjectModel project) {
    if (project.stages.isEmpty) {
      return DateTime.now();
    }

    DateTime earliest = DateTime.now();
    for (final stage in project.stages) {
      if (stage.updatedAt != null) {
        try {
          final date = DateTime.parse(stage.updatedAt!);
          if (date.isBefore(earliest)) {
            earliest = date;
          }
        } catch (e) {
          // Игнорируем ошибки парсинга
        }
      }
    }
    return earliest;
  }

  Widget _buildGlobalSettingsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(_FinanceScreenState._sectionHPadding,
          12, _FinanceScreenState._sectionHPadding, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(_FinanceScreenState._cardRadius),
        border: Border.all(color: AppDesignTokens.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: AppDesignTokens.cardShadow(context),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notes,
                size: 18,
                color: _FinanceScreenState._financeAccent,
              ),
              SizedBox(width: 8),
              Text(
                'Финансовые заметки',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          _buildInputField(
            label: 'Смета контрагента',
            controller: _estimateController,
            minLines: 1,
            maxLines: null,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            label: 'Заметки',
            controller: _notesController,
            minLines: 1,
            maxLines: null,
          ),
          if (_hasChanges) ...[
            InlineSaveActionsRow(
              actions: [
                InlineSaveButton(
                  accentColor: _FinanceScreenState._financeAccent,
                  label: 'Сохранить',
                  onPressed: _saveSettings,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    int minLines = 1,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType:
              maxLines == 1 ? TextInputType.text : TextInputType.multiline,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            fillColor: AppDesignTokens.isDark(context)
                ? Theme.of(context).colorScheme.surfaceContainerHigh
                : Colors.grey[50],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: _FinanceScreenState._financeAccent,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StageDateInfo {
  final String text;
  final Color color;
  _StageDateInfo(this.text, this.color);
}

class _PayStageButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _PayStageButton({required this.onPressed});

  @override
  State<_PayStageButton> createState() => _PayStageButtonState();
}

class _PayStageButtonState extends State<_PayStageButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const accent = _FinanceScreenState._financeAccent;
    final isDark = AppDesignTokens.isDark(context);
    final backgroundColor = _isHovered
        ? accent.withOpacity(isDark ? 0.22 : 0.14)
        : AppDesignTokens.cardBackground(context);
    final borderColor = _isHovered
        ? accent.withOpacity(0.45)
        : AppDesignTokens.cardBorder(context);
    final textColor = _isHovered
        ? (isDark ? accent.shade200 : accent.shade800)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 30),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? accent.withOpacity(0.12)
                  : AppDesignTokens.cardShadow(context),
              blurRadius: _isHovered ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(999),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? accent.withOpacity(0.18)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isHovered
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 12,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isHovered ? 'Оплачено' : 'Не оплачено',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textColor,
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
}
