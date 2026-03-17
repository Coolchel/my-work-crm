import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';

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
    final textStyles = context.appTextStyles;
    final isMobileWeb = DesktopWebFrame.isMobileWeb(context, maxWidth: 560);
    final borderHovered = isDark ? false : _isHovered;
    final lightBaseCardBackground = AppDesignTokens.cardBackground(context);

    final bgGradient = isDark
        ? _isHovered
            ? const [Color(0xFF252C37), Color(0xFF1D232D)]
            : const [Color(0xFF1C2028), Color(0xFF171A21)]
        : _isHovered
            ? [
                Colors.indigo.shade100.withOpacity(0.5),
                Colors.indigo.shade50.withOpacity(0.4),
              ]
            : [
                lightBaseCardBackground,
                lightBaseCardBackground,
              ];

    final titleColor = scheme.onSurface;
    final subtitleColor = isDark
        ? scheme.onSurfaceVariant.withOpacity(_isHovered ? 0.98 : 0.9)
        : Colors.grey.shade600;
    final radius = isMobileWeb ? 18.0 : 24.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: AppDesignTokens.cardBorder(
              context,
              hovered: borderHovered,
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
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return AppDesignTokens.pressedOverlay(context);
              }
              return Colors.transparent;
            }),
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobileWeb ? 16 : 24,
                vertical: isMobileWeb ? 16 : 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Row(
                children: [
                  Container(
                    width: isMobileWeb ? 48 : 56,
                    height: isMobileWeb ? 48 : 56,
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
                      size: isMobileWeb ? 24 : 30,
                    ),
                  ),
                  SizedBox(width: isMobileWeb ? 14 : 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Новый объект',
                          style: textStyles.sectionTitle.copyWith(
                            fontSize: isMobileWeb ? 16 : 18,
                            color: titleColor,
                          ),
                        ),
                        SizedBox(height: isMobileWeb ? 2 : 4),
                        Text(
                          'Создать смету и инженерную карту',
                          style: textStyles.secondaryBody.copyWith(
                            fontSize: isMobileWeb ? 13 : 14,
                            color: subtitleColor,
                          ),
                          maxLines: isMobileWeb ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isMobileWeb)
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
