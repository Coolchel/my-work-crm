import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';

import '../../data/models/project_model.dart';

class ProjectSearchResultTile extends StatefulWidget {
  const ProjectSearchResultTile({
    required this.project,
    required this.onTap,
    super.key,
  });

  final ProjectModel project;
  final VoidCallback onTap;

  @override
  State<ProjectSearchResultTile> createState() =>
      _ProjectSearchResultTileState();
}

class _ProjectSearchResultTileState extends State<ProjectSearchResultTile> {
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

  String _buildMetaLine(ProjectModel project) {
    final client = project.clientInfo.trim();
    final intercom = project.intercomCode.trim();

    if (client.isNotEmpty && intercom.isNotEmpty) {
      return '$client • Домофон: $intercom';
    }
    if (client.isNotEmpty) {
      return client;
    }
    if (intercom.isNotEmpty) {
      return 'Домофон: $intercom';
    }
    return 'Без данных по клиенту';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metaLine = _buildMetaLine(widget.project);
    final onSurfaceVariant = scheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    offset: const Offset(0, 0),
                  ),
                ]
              : const [],
        ),
        child: SizedBox(
          height: 58,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
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
                        _getIcon(widget.project.objectType),
                        size: 20,
                        color: Colors.indigo.shade400,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metaLine,
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
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: _isHovered
                          ? scheme.onSurfaceVariant
                          : scheme.onSurfaceVariant.withOpacity(0.7),
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
