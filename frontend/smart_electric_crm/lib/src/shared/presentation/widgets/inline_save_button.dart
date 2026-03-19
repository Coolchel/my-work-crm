import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_typography.dart';

class InlineSaveButton extends StatelessWidget {
  const InlineSaveButton({
    required this.accentColor,
    required this.label,
    required this.onPressed,
    this.saving = false,
    this.savingLabel,
    this.enabled = true,
    this.compact = false,
    super.key,
  });

  final Color accentColor;
  final String label;
  final String? savingLabel;
  final VoidCallback? onPressed;
  final bool saving;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyles = context.appTextStyles;
    final isDark = AppDesignTokens.isDark(context);
    final isInteractive = enabled && !saving && onPressed != null;
    final baseSurface = isDark ? scheme.surfaceContainerHigh : scheme.surface;
    final backgroundColor = Color.alphaBlend(
      (isInteractive ? accentColor : scheme.onSurface)
          .withOpacity(isInteractive ? (isDark ? 0.20 : 0.10) : 0.04),
      baseSurface,
    );
    final borderColor = isInteractive
        ? accentColor.withOpacity(isDark ? 0.34 : 0.20)
        : scheme.outlineVariant.withOpacity(isDark ? 0.38 : 0.72);
    final badgeColor = isInteractive
        ? accentColor
        : scheme.onSurfaceVariant.withOpacity(isDark ? 0.42 : 0.30);
    final textColor =
        isInteractive ? scheme.onSurface : scheme.onSurfaceVariant;
    final shadowColor = isInteractive
        ? accentColor.withOpacity(isDark ? 0.12 : 0.10)
        : Colors.black.withOpacity(isDark ? 0.0 : 0.02);
    final effectiveLabel = saving ? (savingLabel ?? label) : label;
    final borderRadius = compact ? 14.0 : 16.0;
    final badgeSize = compact ? 20.0 : 24.0;
    final iconSize = compact ? 13.0 : 15.0;
    final badgeSpinnerSize = compact ? 10.0 : 12.0;
    final contentPadding = compact
        ? const EdgeInsets.fromLTRB(8, 6, 10, 6)
        : const EdgeInsets.fromLTRB(10, 8, 14, 8);
    final textStyle = compact
        ? textStyles.button.copyWith(
            color: textColor,
            fontSize: 13,
            height: 1.0,
          )
        : textStyles.button.copyWith(color: textColor);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      opacity: enabled ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: compact
                      ? (isInteractive ? 10 : 6)
                      : (isInteractive ? 14 : 8),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: contentPadding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: saving
                          ? SizedBox(
                              width: badgeSpinnerSize,
                              height: badgeSpinnerSize,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward_rounded,
                              size: iconSize,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  Text(
                    effectiveLabel,
                    style: textStyle,
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

class InlineSaveActionsRow extends StatelessWidget {
  const InlineSaveActionsRow({
    required this.actions,
    this.topPadding = 12,
    this.spacing = 10,
    super.key,
  });

  final List<Widget> actions;
  final double topPadding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: actions,
        ),
      ),
    );
  }
}
