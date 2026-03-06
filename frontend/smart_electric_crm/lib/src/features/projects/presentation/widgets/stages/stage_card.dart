import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import '../../../data/models/stage_model.dart';

class StageCard extends StatefulWidget {
  final StageModel stage;
  final VoidCallback onTap;
  final Function(String) onStatusChanged;
  final VoidCallback onDelete;

  const StageCard({
    super.key,
    required this.stage,
    required this.onTap,
    required this.onStatusChanged,
    required this.onDelete,
  });

  static String getStageTitleDisplay(String title) {
    const map = {
      'precalc': 'Предпросчет',
      'stage_1': 'Этап 1 (Черновой)',
      'stage_1_2': 'Этап 1+2 (Черновой)',
      'stage_2': 'Этап 2 (Черновой)',
      'stage_3': 'Этап 3 (Чистовой)',
      'extra': 'Доп. работы',
      'other': 'Другое',
    };
    return map[title] ?? title;
  }

  @override
  State<StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<StageCard> {
  bool _isHovered = false;

  // Helpers for display
  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Color _getStageColor(String title) {
    switch (title) {
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
      case 'other':
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _getStageColor(widget.stage.title);
    final createdAt = widget.stage.createdAt;
    final updatedAt = widget.stage.updatedAt;
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    // Check if updated date is different from created date (threshold 10 seconds to avoid drift)
    final isEdited = createdAt != null &&
        updatedAt != null &&
        updatedAt.difference(createdAt).abs().inSeconds > 10;
    final createdLabel =
        createdAt != null ? 'Создан: ${_formatDate(createdAt)}' : null;
    final updatedLabel = isEdited ? 'Изменен: ${_formatDate(updatedAt)}' : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 100),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(context, hovered: _isHovered),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppDesignTokens.cardBorder(context, hovered: _isHovered)),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context, hovered: _isHovered),
              blurRadius: _isHovered ? 12 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            hoverColor: Colors.transparent,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accent Stripe
                  Container(
                    width: 5,
                    color: stageColor,
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header with Title and Delete Button
                          isCompact
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                StageCard.getStageTitleDisplay(
                                                    widget.stage.title),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Delete Button (Cross)
                                        SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: IconButton(
                                            icon: Icon(Icons.close,
                                                size: 18,
                                                color: Colors.grey.shade400),
                                            padding: EdgeInsets.zero,
                                            onPressed: widget.onDelete,
                                            tooltip:
                                                "\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u044d\u0442\u0430\u043f",
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.stage.isPaid) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: Colors.green
                                                    .withOpacity(0.2)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle_rounded,
                                                  size: 10,
                                                  color: Colors.green),
                                              SizedBox(width: 3),
                                              Text(
                                                '\u041e\u041f\u041b\u0410\u0427\u0415\u041d\u041e',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            StageCard.getStageTitleDisplay(
                                                widget.stage.title),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (widget.stage.isPaid) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.green
                                                  .withOpacity(0.2)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle_rounded,
                                                size: 10, color: Colors.green),
                                            SizedBox(width: 3),
                                            Text(
                                              'ОПЛАЧЕНО',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    // Delete Button (Cross)
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: IconButton(
                                        icon: Icon(Icons.close,
                                            size: 18,
                                            color: Colors.grey.shade400),
                                        padding: EdgeInsets.zero,
                                        onPressed: widget.onDelete,
                                        tooltip: "Удалить этап",
                                      ),
                                    ),
                                  ],
                                ),

                          const SizedBox(height: 16),

                          // Stats Rows
                          isCompact
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatItem(
                                            icon: Icons.handyman_outlined,
                                            label:
                                                '\u0420\u0430\u0431\u043e\u0442\u044b',
                                            value:
                                                '${widget.stage.totalAmountUsd.toStringAsFixed(0)} \$',
                                            color: Colors.green,
                                            compact: true,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatItem(
                                            icon: Icons.inventory_2_outlined,
                                            label:
                                                '\u041c\u0430\u0442\u0435\u0440\u0438\u0430\u043b\u044b',
                                            value:
                                                '${widget.stage.totalAmountMaterialsUsd.toStringAsFixed(0)} \$',
                                            color: Colors.blue,
                                            compact: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (createdLabel != null) ...[
                                      const SizedBox(height: 12),
                                      _buildMobileDateSection(
                                        createdLabel: createdLabel,
                                        updatedLabel: updatedLabel,
                                      ),
                                    ],
                                  ],
                                )
                              : Row(
                                  children: [
                                    _buildStatItem(
                                      icon: Icons.handyman_outlined,
                                      label: 'Работы',
                                      value:
                                          '${widget.stage.totalAmountUsd.toStringAsFixed(0)} \$',
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 24),
                                    _buildStatItem(
                                      icon: Icons.inventory_2_outlined,
                                      label: 'Материалы',
                                      value:
                                          '${widget.stage.totalAmountMaterialsUsd.toStringAsFixed(0)} \$',
                                      color: Colors.blue,
                                    ),
                                    const Spacer(),
                                    if (createdLabel != null)
                                      _buildDateColumn(
                                        createdLabel: createdLabel,
                                        updatedLabel: updatedLabel,
                                      ),
                                  ],
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool compact = false,
  }) {
    final iconPadding = compact ? 6.0 : 8.0;
    final iconSize = compact ? 16.0 : 18.0;
    final labelSize = compact ? 10.0 : 11.0;
    final valueSize = compact ? 13.0 : 14.0;
    final spacing = compact ? 8.0 : 12.0;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: iconSize, color: color),
        ),
        SizedBox(width: spacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: labelSize,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateColumn({
    required String createdLabel,
    String? updatedLabel,
  }) {
    final hasUpdated = updatedLabel != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            hasUpdated ? MainAxisAlignment.start : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            createdLabel,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasUpdated)
            Text(
              updatedLabel,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileDateSection({
    required String createdLabel,
    String? updatedLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.18),
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: _buildDateColumn(
          createdLabel: createdLabel,
          updatedLabel: updatedLabel,
        ),
      ),
    );
  }
}
