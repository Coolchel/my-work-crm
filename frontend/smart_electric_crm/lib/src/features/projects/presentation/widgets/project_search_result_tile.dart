import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';

import '../../data/models/project_model.dart';

class ProjectSearchResultTile extends StatefulWidget {
  const ProjectSearchResultTile({
    required this.project,
    required this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    super.key,
  });

  final ProjectModel project;
  final VoidCallback onTap;
  final EdgeInsets margin;

  @override
  State<ProjectSearchResultTile> createState() =>
      _ProjectSearchResultTileState();
}

class _ProjectSearchResultTileState extends State<ProjectSearchResultTile> {
  static const double _tileMinHeight = 82;
  static const double _dateColumnWidth = 86;
  static const double _contentDateGap = 6;

  bool _isHovered = false;

  IconData _getIcon(String type) {
    switch (type) {
      case 'new_building':
        return Icons.apartment;
      case 'secondary':
        return Icons.home;
      case 'cottage':
        return Icons.villa;
      case 'office':
        return Icons.business;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Сегодня';
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String? _buildClientLine(ProjectModel project) {
    final client = project.clientInfo.trim();
    return client.isEmpty ? null : client;
  }

  String? _buildIntercomLine(ProjectModel project) {
    final intercom = project.intercomCode.trim();
    if (intercom.isEmpty) {
      return null;
    }
    return 'Домофон: $intercom';
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final scheme = Theme.of(context).colorScheme;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    final activityDate = project.updatedAt ?? project.createdAt;
    final clientLine = _buildClientLine(project);
    final intercomLine = _buildIntercomLine(project);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: widget.margin,
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(context, hovered: _isHovered),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppDesignTokens.cardBorder(context, hovered: _isHovered),
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppDesignTokens.cardShadow(context, hovered: true),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const [],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _tileMinHeight),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppDesignTokens.isDark(context)
                                  ? scheme.surfaceContainerHigh
                                  : Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getIcon(project.objectType),
                              size: 20,
                              color: Colors.indigo.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: _dateColumnWidth + _contentDateGap,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          height: 1.1,
                                        ),
                                      ),
                                      if (clientLine != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          clientLine,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.1,
                                            color: onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      if (intercomLine != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          intercomLine,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.1,
                                            color: onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: SizedBox(
                                width: _dateColumnWidth,
                                child: Text(
                                  _formatDate(activityDate),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              bottom: 0,
                              right: 0,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: _isHovered
                                      ? scheme.onSurfaceVariant
                                      : scheme.onSurfaceVariant.withOpacity(
                                          0.7,
                                        ),
                                ),
                              ),
                            ),
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
      ),
    );
  }
}
