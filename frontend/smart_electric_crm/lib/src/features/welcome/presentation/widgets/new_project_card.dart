import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';

import '../../../projects/presentation/screens/add_project_screen.dart';

class NewProjectCard extends StatefulWidget {
  const NewProjectCard({super.key});

  @override
  State<NewProjectCard> createState() => _NewProjectCardState();
}

class _NewProjectCardState extends State<NewProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);

    final bgGradient = isDark
        ? const [Color(0xFF1C2028), Color(0xFF171A21)]
        : [
            Colors.indigo.shade50.withOpacity(0.5),
            Colors.indigo.shade50.withOpacity(0.2),
          ];

    final titleColor = scheme.onSurface;
    final subtitleColor = isDark
        ? scheme.onSurfaceVariant.withOpacity(0.9)
        : Colors.grey.shade600;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppDesignTokens.cardBorder(
              context,
              hovered: _isHovered,
            ),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(
                context,
                hovered: _isHovered,
              ),
              blurRadius: _isHovered ? 18 : 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const AddProjectDialog(),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF4E67CF), Color(0xFF3A4FA8)]
                            : [Colors.indigo.shade600, Colors.indigo.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(isDark ? 0.24 : 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      color: scheme.onPrimary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Новый объект',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Создать смету и инженерную карту',
                          style: TextStyle(
                            fontSize: 14,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark
                        ? scheme.onSurfaceVariant.withOpacity(0.8)
                        : Colors.indigo.withOpacity(0.5),
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
