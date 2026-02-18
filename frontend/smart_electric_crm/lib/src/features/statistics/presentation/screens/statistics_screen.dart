import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/statistics_model.dart';
import '../../data/repositories/statistics_repository.dart';
import '../widgets/work_dynamics_chart.dart';
import '../../../../shared/presentation/widgets/compact_section_app_bar.dart';
import '../../../../core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    String formatted = amount.toStringAsFixed(2);
    if (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsDataProvider);
    final currentPeriod = ref.watch(statisticsFilterProvider);
    final statisticsAccent =
        Theme.of(context).floatingActionButtonTheme.backgroundColor ??
            Colors.indigo;

    return Scaffold(
      appBar: const CompactSectionAppBar(
        title: 'Статистика',
        icon: Icons.bar_chart_rounded,
        gradientColors: AppDesignTokens.subtleSectionGradient,
        bottomGap: 10,
      ),
      body: statsAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(statisticsDataProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Переключатель периода
                Center(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'month',
                        label: Text('Месяц'),
                        icon: Icon(Icons.calendar_view_month),
                      ),
                      ButtonSegment<String>(
                        value: 'year',
                        label: Text('Год'),
                        icon: Icon(Icons.calendar_today),
                      ),
                      ButtonSegment<String>(
                        value: 'all',
                        label: Text('Все время'),
                        icon: Icon(Icons.history),
                      ),
                    ],
                    selected: {currentPeriod},
                    onSelectionChanged: (Set<String> newSelection) {
                      ref
                          .read(statisticsFilterProvider.notifier)
                          .setPeriod(newSelection.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: MaterialStateProperty.all(
                          BorderSide(color: statisticsAccent)),
                      backgroundColor:
                          MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.selected)) {
                          return statisticsAccent;
                        }
                        return Colors.transparent;
                      }),
                      foregroundColor:
                          MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return Colors.black87;
                      }),
                      iconColor:
                          MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return Colors.grey;
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const SizedBox(height: 24),

                _buildHeader(
                  'Финансы за ${_getPeriodTitle(currentPeriod)}',
                  stripeColor: statisticsAccent,
                ),
                const SizedBox(height: 12),
                _buildFinancialSummary(stats.finances),
                const SizedBox(height: 24),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(
                              'Откуда объекты',
                              stripeColor: statisticsAccent,
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                                child: _buildPieChartCard(
                              stats.sources
                                  .map((e) => _ChartData(e.name, e.usd))
                                  .toList(),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(
                              'Типы объектов',
                              stripeColor: statisticsAccent,
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                                child: _buildPieChartCard(
                              stats.objectTypes
                                  .map((e) => _ChartData(e.name, e.usd))
                                  .toList(),
                              paletteOffset: 2,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildHeader(
                  'Динамика работ',
                  stripeColor: statisticsAccent,
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: WorkDynamicsChart(
                        data: stats.workDynamics,
                        isMonthly: currentPeriod != 'month',
                        currencyLabel: "USD",
                        currencySymbol: "\$",
                        isUsd: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.indigo.withOpacity(0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: WorkDynamicsChart(
                        data: stats.workDynamics,
                        isMonthly: currentPeriod != 'month',
                        currencyLabel: "BYN",
                        currencySymbol: "р",
                        isUsd: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    "* За выполненные работы (фиксация по дате создания, не зависит от оплаты)",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPeriodTitle(String period) {
    switch (period) {
      case 'month':
        return 'месяц';
      case 'year':
        return 'год';
      case 'all':
        return 'все время';
      default:
        return '';
    }
  }

  Widget _buildHeader(
    String title, {
    required Color stripeColor,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: stripeColor, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  // 1. Financial Summary Cards
  Widget _buildFinancialSummary(CurrencyAmount finances) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _buildFinanceCard(
              'Всего USD',
              finances.usd,
              '\$',
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildFinanceCard(
              'Всего BYN',
              finances.byn,
              'р',
              Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(
      String title, double amount, String symbol, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.attach_money,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_formatAmount(amount)} $symbol',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Helper class for chart data

  Widget _buildPieChartCard(List<_ChartData> data, {int paletteOffset = 0}) {
    if (data.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: const FriendlyEmptyState(
          icon: Icons.pie_chart_outline_rounded,
          title: 'Нет данных',
          subtitle: 'Данные появятся после добавления активности.',
          accentColor: Colors.indigo,
          iconSize: 64,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }

    // Reverted palette (Mixed colors)
    final List<Color> palette = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.redAccent,
      Colors.green,
      Colors.brown,
    ];

    final realTotal = data.fold(0.0, (sum, item) => sum + item.value);

    // Sort logic
    final sortedData = List<_ChartData>.from(data)
      ..sort((a, b) => b.value.compareTo(a.value));

    // Logic to visually boost small percentages to 5%
    // but keep REAL value in text
    final List<({_ChartData original, double visualValue, double realPercent})>
        chartData = [];

    for (var item in sortedData) {
      final realPercent = (item.value / realTotal * 100);
      // If less than 5%, visual value is 5% of total (approx), else real value
      // Note: This distorts the chart slightly but ensures visibility.
      // A better approximation for visual consistency:
      final visualValue = realPercent < 5.0 ? (realTotal * 0.05) : item.value;

      chartData.add((
        original: item,
        visualValue: visualValue,
        realPercent: realPercent,
      ));
    }

    // Build Legend Widget first to reuse it
    final legendWidget = Column(
      mainAxisSize: MainAxisSize.min, // Wrap content so it stays at bottom
      crossAxisAlignment: CrossAxisAlignment.end,
      children: chartData.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final color = palette[(index + paletteOffset) % palette.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                // Ensure text doesn't overflow if very narrow
                child: Text(
                  item.original.name,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatAmount(item.original.value)}\$',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.15), // Greenish border
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Hidden Top Legend (For balancing)
          IgnorePointer(
            child: Opacity(
              opacity: 0.0,
              child: Align(
                alignment: Alignment.topRight,
                child: legendWidget,
              ),
            ),
          ),

          // 2. Chart (Centered)
          Center(
            child: SizedBox(
              height: 170, // Increased height
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 25,
                  sections: chartData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final color =
                        palette[(index + paletteOffset) % palette.length];

                    return PieChartSectionData(
                      color: color,
                      value: item.visualValue,
                      title:
                          '${item.realPercent.toStringAsFixed(1).replaceAll('.0', '')}%',
                      radius: 50, // Increased radius
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // 3. Visible Bottom Legend
          Align(
            alignment: Alignment.bottomRight,
            child: legendWidget,
          )
        ],
      ),
    );
  }
}

class _ChartData {
  final String name;
  final double value;
  _ChartData(this.name, this.value);
}
