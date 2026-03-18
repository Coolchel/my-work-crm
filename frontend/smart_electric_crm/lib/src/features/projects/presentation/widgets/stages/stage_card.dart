import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/core/utils/app_number_formatter.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/card_meta_info_block.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';

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
  static const double _metaBlockSpacing = 12;
  static const double _mobileCardMinHeight = 168;
  static const double _mobileMetaSlotHeight = 42;
  static const double _mobileHeaderActionWidth = 32;

  bool _isHovered = false;

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
    final textStyles = context.appTextStyles;
    final isDesktopWeb =
        kIsWeb && DesktopWebFrame.isDesktop(context, minWidth: 1280);
    final isCompactMobileWeb = DesktopWebFrame.isMobileWeb(
      context,
      maxWidth: 520,
    );
    final isMobilePlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final useMobileLayout = isCompactMobileWeb ||
        isMobilePlatform ||
        MediaQuery.sizeOf(context).width < 480;
    final desktopCardHeight = isDesktopWeb ? 152.0 : 132.0;

    final isEdited = createdAt != null &&
        updatedAt != null &&
        updatedAt.difference(createdAt).abs().inSeconds > 10;
    final updatedValue = isEdited ? _formatDate(updatedAt) : null;
    final metaBlocks = _buildDesktopMetaBlocks(
      createdAt: createdAt,
      updatedValue: updatedValue,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: BoxConstraints(
          minHeight: useMobileLayout ? _mobileCardMinHeight : desktopCardHeight,
          maxHeight: useMobileLayout ? double.infinity : desktopCardHeight,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(context, hovered: _isHovered),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppDesignTokens.cardBorder(context, hovered: _isHovered),
          ),
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
                  Container(
                    width: 5,
                    color: stageColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        useMobileLayout ? 12 : 16,
                        useMobileLayout ? 20 : 0,
                        useMobileLayout ? 12 : 16,
                        useMobileLayout ? 12 : 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: useMobileLayout
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          useMobileLayout
                              ? _buildMobileHeader()
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        StageCard.getStageTitleDisplay(
                                          widget.stage.title,
                                        ),
                                        style: textStyles.sectionTitle.copyWith(
                                          fontSize: 17,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                    if (widget.stage.isPaid) ...[
                                      Transform.translate(
                                        offset: const Offset(0, -10),
                                        child: _buildPaidBadge(),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Transform.translate(
                                      offset: const Offset(0, -10),
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.grey.shade400,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: widget.onDelete,
                                          tooltip: 'Удалить этап',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          SizedBox(height: useMobileLayout ? 16 : 20),
                          useMobileLayout
                              ? _buildMobileMetaSection(
                                  createdAt: createdAt,
                                  updatedValue: updatedValue,
                                )
                              : _buildMetaSection(children: metaBlocks),
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

  Widget _buildMetaBlock({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool compact,
  }) {
    return CardMetaInfoBlock(
      icon: icon,
      label: label,
      value: value,
      color: color,
      compact: compact,
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.only(right: _mobileHeaderActionWidth),
                  child: Text(
                    StageCard.getStageTitleDisplay(widget.stage.title),
                    style: context.appTextStyles.sectionTitle.copyWith(
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -2),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: widget.onDelete,
                    tooltip: 'Удалить этап',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.stage.isPaid) ...[
          const SizedBox(height: 8),
          _buildPaidBadge(),
        ],
      ],
    );
  }

  List<Widget> _buildDesktopMetaBlocks({
    required DateTime? createdAt,
    required String? updatedValue,
  }) {
    final blocks = <Widget>[
      _buildMetaBlock(
        icon: Icons.handyman_outlined,
        label: 'Работы',
        value: '${AppNumberFormatter.integer(widget.stage.totalAmountUsd)} \$',
        color: Colors.green,
        compact: false,
      ),
      _buildMetaBlock(
        icon: Icons.inventory_2_outlined,
        label: 'Материалы',
        value:
            '${AppNumberFormatter.integer(widget.stage.totalAmountMaterialsUsd)} \$',
        color: Colors.blue,
        compact: false,
      ),
    ];

    if (createdAt != null) {
      blocks.add(
        _buildMetaBlock(
          icon: Icons.event_available_outlined,
          label: 'Создан',
          value: _formatDate(createdAt),
          color: Colors.indigo,
          compact: false,
        ),
      );
    }

    if (updatedValue != null) {
      blocks.add(
        _buildMetaBlock(
          icon: Icons.update_outlined,
          label: 'Изменен',
          value: updatedValue,
          color: Colors.blueGrey,
          compact: false,
        ),
      );
    }

    return blocks;
  }

  Widget _buildMobileMetaSection({
    required DateTime? createdAt,
    required String? updatedValue,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMobileMetaSlot(
                _buildMetaBlock(
                  icon: Icons.handyman_outlined,
                  label: 'Работы',
                  value:
                      '${AppNumberFormatter.integer(widget.stage.totalAmountUsd)} \$',
                  color: Colors.green,
                  compact: true,
                ),
              ),
            ),
            const SizedBox(width: _metaBlockSpacing),
            Expanded(
              child: _buildMobileMetaSlot(
                _buildMetaBlock(
                  icon: Icons.inventory_2_outlined,
                  label: 'Материалы',
                  value:
                      '${AppNumberFormatter.integer(widget.stage.totalAmountMaterialsUsd)} \$',
                  color: Colors.blue,
                  compact: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMobileMetaSlot(
                createdAt == null
                    ? null
                    : _buildMetaBlock(
                        icon: Icons.event_available_outlined,
                        label: 'Создан',
                        value: _formatDate(createdAt),
                        color: Colors.indigo,
                        compact: true,
                      ),
              ),
            ),
            const SizedBox(width: _metaBlockSpacing),
            Expanded(
              child: _buildMobileMetaSlot(
                updatedValue == null
                    ? null
                    : _buildMetaBlock(
                        icon: Icons.update_outlined,
                        label: 'Изменен',
                        value: updatedValue,
                        color: Colors.blueGrey,
                        compact: true,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileMetaSlot(Widget? child) {
    return SizedBox(
      height: _mobileMetaSlotHeight,
      child: child ?? const SizedBox.shrink(),
    );
  }

  Widget _buildMetaSection({
    required List<Widget> children,
  }) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <Widget>[];
    const columns = 4;

    for (var start = 0; start < children.length; start += columns) {
      final end = (start + columns < children.length)
          ? start + columns
          : children.length;
      final rowChildren = children.sublist(start, end);
      final trailingPlaceholders = columns - rowChildren.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < rowChildren.length; i++) ...[
              Expanded(child: rowChildren[i]),
              if (i < rowChildren.length - 1 || trailingPlaceholders > 0)
                const SizedBox(width: _metaBlockSpacing),
            ],
            for (var i = 0; i < trailingPlaceholders; i++) ...[
              const Expanded(child: SizedBox.shrink()),
              if (i < trailingPlaceholders - 1)
                const SizedBox(width: _metaBlockSpacing),
            ],
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPaidBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.green.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 10,
              color: Colors.green,
            ),
            const SizedBox(width: 3),
            Text(
              'ОПЛАЧЕНО',
              style: context.appTextStyles.captionStrong.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.green,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
