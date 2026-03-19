import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';

/// A styled header for grouping estimate items by category
class GroupHeader extends StatelessWidget {
  final String title;
  final Color color;
  final int? itemCount;
  final EdgeInsetsGeometry padding;
  final int maxLines;

  const GroupHeader({
    super.key,
    required this.title,
    required this.color,
    this.itemCount,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    final titleStyle = textStyles.captionStrong.copyWith(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: color.withOpacity(0.9),
      height: 1.2,
      letterSpacing: 0.2,
    );
    final countText = itemCount?.toString();

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final countStyle = textStyles.captionStrong.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.95),
          );
          final countPainter = countText == null
              ? null
              : (TextPainter(
                  text: TextSpan(text: countText, style: countStyle),
                  textDirection: Directionality.of(context),
                  maxLines: 1,
                )..layout());
          final countWidth =
              countText == null ? 0.0 : (countPainter!.width + 22);
          const markerWidth = 3.0;
          const markerGap = 8.0;
          const dividerGap = 8.0;
          const countGap = 8.0;
          final maxTitleWidth = (constraints.maxWidth -
                  markerWidth -
                  markerGap -
                  dividerGap -
                  countGap -
                  countWidth)
              .clamp(0.0, double.infinity);
          final titlePainter = TextPainter(
            text: TextSpan(text: title, style: titleStyle),
            textDirection: Directionality.of(context),
            maxLines: maxLines,
            ellipsis: '…',
          )..layout(maxWidth: maxTitleWidth);
          final lineMetrics = titlePainter.computeLineMetrics();
          final lineCount = lineMetrics.isEmpty ? 1 : lineMetrics.length;
          final markerHeight =
              (titlePainter.preferredLineHeight * lineCount).clamp(13.0, 28.0);
          final dividerTop = titlePainter.preferredLineHeight * 0.58;
          final shouldShowDivider = constraints.maxWidth -
                  markerWidth -
                  markerGap -
                  titlePainter.width -
                  countWidth >
              dividerGap + countGap + 6;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: markerWidth,
                height: markerHeight,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: markerGap),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTitleWidth),
                child: Text(
                  title,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              if (shouldShowDivider) ...[
                const SizedBox(width: dividerGap),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: dividerTop),
                    child: Divider(
                      color: color.withOpacity(0.12),
                      thickness: 0.9,
                      height: 1,
                    ),
                  ),
                ),
              ],
              if (countText != null) ...[
                const SizedBox(width: countGap),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text(countText, style: countStyle),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
