import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/features/statistics/data/models/statistics_model.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

class WorkDynamicsChart extends StatefulWidget {
  final List<WorkDynamicsData> data;
  final bool isMonthly; // If true, data is grouped by YYYY-MM
  final String currencyLabel; // e.g., "USD" or "BYN"
  final String currencySymbol; // e.g., "$" or "р"
  final bool isUsd; // To determine which field to use and which color

  const WorkDynamicsChart({
    super.key,
    required this.data,
    this.isMonthly = false,
    this.currencyLabel = "USD",
    this.currencySymbol = "\$",
    this.isUsd = true,
  });

  @override
  State<WorkDynamicsChart> createState() => _WorkDynamicsChartState();
}

class _WorkDynamicsChartState extends State<WorkDynamicsChart> {
  // Show USD by default, maybe toggle later if needed?
  // For now, let's show stacked or just USD lines.
  // Requirement: "beautiful chart". Line chart with 2 lines (USD/BYN) or just main currency?
  // Let's show USD as primary (Green/Blue) and BYN as secondary (Orange/Red) if present.

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    if (widget.data.isEmpty) {
      return const FriendlyEmptyState(
        icon: Icons.show_chart_rounded,
        title: 'Нет данных',
        subtitle: 'График появится, когда накопятся данные за период.',
        accentColor: Colors.indigo,
        iconSize: 62,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    }

    // Colors based on currency
    final mainColor = widget.isUsd ? Colors.green : Colors.indigo;
    final accentColor = widget.isUsd ? Colors.green : Colors.indigoAccent;

    final spots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < widget.data.length; i++) {
      final item = widget.data[i];
      final value = widget.isUsd ? item.usd : item.byn;

      spots.add(FlSpot(i.toDouble(), value));

      if (value > maxY) maxY = value;
    }

    // Add some padding to top
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildLegendItem(
              '${widget.currencyLabel} (${widget.currencySymbol})',
              mainColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              right: 22,
              left: 8,
              top: 10,
              bottom: 4,
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxY / 5,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.05),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: _calculateInterval(widget.data.length),
                      getTitlesWidget: (value, meta) {
                        return _bottomTitleWidgets(
                            value, meta, widget.data, widget.isMonthly);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 5,
                      getTitlesWidget: _leftTitleWidgets,
                      reservedSize: isCompact ? 54 : 48,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                      color: const Color(0xff37434d).withOpacity(0.05)),
                ),
                minX: 0,
                maxX: (widget.data.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        mainColor,
                      ],
                    ),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.15),
                          mainColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final index = touchedSpot.x.toInt();
                        if (index < 0 || index >= widget.data.length) {
                          return LineTooltipItem(
                            '',
                            textStyles.chartLabel,
                          );
                        }

                        final data = widget.data[index];
                        String formattedDate = data.date;
                        try {
                          String cleanDate = data.date.replaceAll(' ', '-');
                          if (cleanDate.length == 10) {
                            final date =
                                DateFormat("yyyy-MM-dd").parse(cleanDate);
                            formattedDate =
                                DateFormat("dd.MM.yyyy").format(date);
                          } else if (cleanDate.length == 7) {
                            final date = DateFormat("yyyy-MM").parse(cleanDate);
                            formattedDate = DateFormat("MM.yyyy").format(date);
                          }
                        } catch (_) {}

                        final value = widget.isUsd ? data.usd : data.byn;

                        return LineTooltipItem(
                          '$formattedDate\n',
                          textStyles.chartLabel.copyWith(
                            color: scheme.surface,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${_formatAmount(value)} ${widget.currencySymbol}',
                              style: textStyles.chartLabel.copyWith(
                                color: widget.isUsd
                                    ? Colors.green
                                    : Colors.indigoAccent.shade100,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                    tooltipPadding: const EdgeInsets.all(6),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyles = context.appTextStyles;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(
          isDark ? 0.55 : 0.75,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(isDark ? 0.45 : 0.75),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyles.chartLabel.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta,
      List<WorkDynamicsData> data, bool isMonthly) {
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final index = value.toInt();
    if (index < 0 || index >= data.length) return const SizedBox.shrink();

    // Logic to avoid overlapping titles
    // If many points, show fewer labels

    final dateStr = data[index].date; // YYYY-MM-DD or YYYY-MM
    String label = "";

    try {
      if (isMonthly) {
        final date = DateFormat("yyyy-MM").parse(dateStr);
        label = DateFormat(isCompact ? "MM.yy" : "MM.yyyy").format(date);
      } else {
        DateTime? date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          try {
            date = DateFormat("dd.MM.yyyy").parse(dateStr);
          } catch (__) {}
        }

        if (date != null) {
          label = DateFormat(isCompact ? "dd.MM" : "dd.MM.yyyy").format(date);
        } else {
          label = dateStr;
        }
      }
    } catch (e) {
      label = dateStr;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Text(
        label,
        style: textStyles.chartLabel.copyWith(
          fontSize: isCompact ? 9 : 10,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;
    final text = _formatAmount(value);

    return Text(
      text,
      style: textStyles.chartLabel.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.left,
    );
  }

  double _calculateInterval(int length) {
    if (length <= 5) return 1;
    if (length <= 10) return 2;
    if (length <= 20) return 4;
    return (length / 5).toDouble();
  }

  String _formatAmount(double value) {
    final sign = value < 0 ? '-' : '';
    final grouped = _groupThousands(value.abs().round().toString());
    return '$sign$grouped';
  }

  String _groupThousands(String digits) {
    if (digits.length <= 3) {
      return digits;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final positionFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}
