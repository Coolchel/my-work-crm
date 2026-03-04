import 'package:flutter/material.dart';

class HelpTooltipIcon extends StatelessWidget {
  final String message;
  final double size;

  const HelpTooltipIcon({
    super.key,
    required this.message,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textScale = MediaQuery.maybeOf(context)?.textScaleFactor ?? 1.0;
    final scale = textScale.clamp(1.0, 1.25).toDouble();
    final iconSize = (size * scale).clamp(12.0, 20.0);

    return Tooltip(
      message: message,
      textAlign: TextAlign.center,
      child: SizedBox.square(
        dimension: iconSize + 2,
        child: Center(
          child: Icon(
            Icons.question_mark_rounded,
            size: iconSize,
            color: scheme.onSurfaceVariant.withOpacity(isDark ? 0.30 : 0.24),
          ),
        ),
      ),
    );
  }
}
