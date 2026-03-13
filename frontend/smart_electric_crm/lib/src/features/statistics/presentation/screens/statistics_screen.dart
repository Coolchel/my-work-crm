import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/features/statistics/data/models/statistics_model.dart';
import 'package:smart_electric_crm/src/features/statistics/data/repositories/statistics_repository.dart';
import 'package:smart_electric_crm/src/features/statistics/presentation/widgets/work_dynamics_chart.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/compact_section_app_bar.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/help_tooltip_icon.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const StatisticsScreen({
    this.onBackPressed,
    super.key,
  });

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  static const double _pieChartCardHeight = 320;
  final ScrollController _scrollController = ScrollController();
  final SectionAppBarCollapseController _appBarCollapseController =
      SectionAppBarCollapseController();
  Object? _scrollAttachment;

  @override
  void initState() {
    super.initState();
    _appBarCollapseController.bind(_scrollController);
    _scrollAttachment =
        AppNavigation.statisticsScrollController.attach(_scrollToTop);
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.statisticsScrollController.detach(scrollAttachment);
    }
    _appBarCollapseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToTop({bool animated = true}) async {
    if (!_scrollController.hasClients) {
      return;
    }
    if (animated) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _scrollController.jumpTo(0);
  }

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
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final isMobile = viewport.width < 600;
    final orientation = MediaQuery.orientationOf(context);
    final isPhonePortrait = isMobile && orientation == Orientation.portrait;
    final isPhoneLandscape = isMobile && orientation == Orientation.landscape;
    final useVerticalPieCharts = viewport.width < 980;
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final statsAsync = ref.watch(statisticsDataProvider);
    final handleBack =
        widget.onBackPressed ?? () => Navigator.of(context).maybePop();
    final currentPeriod = ref.watch(statisticsFilterProvider);
    final statisticsAccent =
        Theme.of(context).floatingActionButtonTheme.backgroundColor ??
            Colors.indigo;
    final periodSwitcherWidth =
        (isMobile ? viewport.width - 32 : viewport.width * 0.58)
            .clamp(280.0, 560.0)
            .toDouble();
    final periodSegmentWidth = periodSwitcherWidth / 3;
    final headerStripeColor =
        isDark ? scheme.primary.withOpacity(0.76) : statisticsAccent;
    const workDynamicsTooltip =
        '\u0414\u0438\u043d\u0430\u043c\u0438\u043a\u0430 \u0440\u0430\u0431\u043e\u0442.\n'
        '\u041f\u043e\u043a\u0430\u0437\u044b\u0432\u0430\u0435\u0442 \u0437\u0430\u0440\u0430\u0431\u043e\u0442\u043e\u043a\n'
        '\u043f\u043e \u0441\u0434\u0435\u043b\u0430\u043d\u043d\u044b\u043c \u043e\u0431\u044a\u0435\u043a\u0442\u0430\u043c.\n'
        '\u041d\u0435 \u0441\u0432\u044f\u0437\u0430\u043d\u043e \u0441 \u043e\u043f\u043b\u0430\u0442\u043e\u0439.';
    final periodSegments = <ButtonSegment<String>>[
      ButtonSegment<String>(
        value: 'month',
        label: const Text('\u041c\u0435\u0441\u044f\u0446'),
        icon: isMobile ? null : const Icon(Icons.calendar_view_month),
      ),
      ButtonSegment<String>(
        value: 'year',
        label: const Text('\u0413\u043e\u0434'),
        icon: isMobile ? null : const Icon(Icons.calendar_today),
      ),
      ButtonSegment<String>(
        value: 'all',
        label: Text(
          isMobile
              ? '\u0412\u0441\u0435'
              : '\u0412\u0441\u0435 \u0432\u0440\u0435\u043c\u044f',
        ),
        icon: isMobile ? null : const Icon(Icons.history),
      ),
    ];

    return ListenableBuilder(
      listenable: _appBarCollapseController,
      builder: (context, child) {
        return Scaffold(
          appBar: CompactSectionAppBar(
            collapseProgress: CompactSectionAppBar.resolveCollapseProgress(
              context,
              _appBarCollapseController.progress,
            ),
            leading: IconButton(
              tooltip: '\u041d\u0430\u0437\u0430\u0434',
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: handleBack,
            ),
            title: 'Статистика',
            icon: Icons.bar_chart_rounded,
            gradientColors: AppDesignTokens.subtleSectionGradient,
            bottomGap: isPhoneLandscape ? 10 : 30,
          ),
          body: child!,
        );
      },
      child: statsAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(statisticsDataProvider),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Переключатель периода
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: periodSwitcherWidth,
                    child: SegmentedButton<String>(
                      segments: periodSegments,
                      selected: {currentPeriod},
                      showSelectedIcon: !isMobile,
                      onSelectionChanged: (Set<String> newSelection) {
                        ref
                            .read(statisticsFilterProvider.notifier)
                            .setPeriod(newSelection.first);
                      },
                      style: ButtonStyle(
                        visualDensity: isMobile
                            ? VisualDensity.compact
                            : VisualDensity.standard,
                        minimumSize: MaterialStateProperty.all(
                          Size(periodSegmentWidth, isMobile ? 40 : 46),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
                            vertical: isMobile ? 8 : 10,
                          ),
                        ),
                        side: MaterialStateProperty.resolveWith<BorderSide>(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return BorderSide(
                                color: isDark
                                    ? scheme.primary.withOpacity(0.66)
                                    : statisticsAccent.withOpacity(0.85),
                              );
                            }
                            return BorderSide(
                              color: AppDesignTokens.cardBorder(context),
                            );
                          },
                        ),
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return isDark
                                ? scheme.primary.withOpacity(0.28)
                                : statisticsAccent.withOpacity(0.9);
                          }
                          return isDark
                              ? scheme.surfaceContainerHigh
                              : scheme.surface;
                        }),
                        foregroundColor:
                            MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.white;
                          }
                          return scheme.onSurface;
                        }),
                        iconColor:
                            MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.white;
                          }
                          return isDark ? scheme.onSurfaceVariant : Colors.grey;
                        }),
                        overlayColor:
                            MaterialStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(MaterialState.hovered)) {
                            return AppDesignTokens.hoverOverlay(context);
                          }
                          if (states.contains(MaterialState.pressed)) {
                            return AppDesignTokens.pressedOverlay(context);
                          }
                          return null;
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const SizedBox(height: 24),

                _buildHeader(
                  context,
                  'Финансы за ${_getPeriodTitle(currentPeriod)}',
                  stripeColor: headerStripeColor,
                ),
                const SizedBox(height: 12),
                _buildFinancialSummary(context, stats.finances),
                const SizedBox(height: 24),

                if (useVerticalPieCharts) ...[
                  _buildHeader(
                    context,
                    'Откуда объекты',
                    stripeColor: headerStripeColor,
                  ),
                  const SizedBox(height: 12),
                  _buildPieChartCard(
                    context,
                    stats.sources
                        .map((e) => _ChartData(e.name, e.usd))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildHeader(
                    context,
                    'Типы объектов',
                    stripeColor: headerStripeColor,
                  ),
                  const SizedBox(height: 12),
                  _buildPieChartCard(
                    context,
                    stats.objectTypes
                        .map((e) => _ChartData(e.name, e.usd))
                        .toList(),
                    paletteOffset: 2,
                  ),
                ] else
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(
                                context,
                                'Откуда объекты',
                                stripeColor: headerStripeColor,
                              ),
                              const SizedBox(height: 12),
                              _buildPieChartCard(
                                context,
                                stats.sources
                                    .map((e) => _ChartData(e.name, e.usd))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(
                                context,
                                'Типы объектов',
                                stripeColor: headerStripeColor,
                              ),
                              const SizedBox(height: 12),
                              _buildPieChartCard(
                                context,
                                stats.objectTypes
                                    .map((e) => _ChartData(e.name, e.usd))
                                    .toList(),
                                paletteOffset: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                _buildHeader(
                  context,
                  'Динамика работ',
                  stripeColor: headerStripeColor,
                ),
                const SizedBox(height: 12),
                if (isPhonePortrait)
                  _buildRotateDeviceNotice(context)
                else
                  Column(
                    children: [
                      _HoverStatsCard(
                        borderRadius: 16,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final widthPerPoint =
                                currentPeriod == 'month' ? 44.0 : 64.0;
                            final contentWidth = isMobile
                                ? math.max(
                                    constraints.maxWidth,
                                    stats.workDynamics.length * widthPerPoint,
                                  )
                                : constraints.maxWidth;

                            return SizedBox(
                              height: isMobile ? 300 : 280,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: contentWidth,
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 12, 12, 8),
                                        child: WorkDynamicsChart(
                                          data: stats.workDynamics,
                                          isMonthly: currentPeriod != 'month',
                                          currencyLabel: "USD",
                                          currencySymbol: "\$",
                                          isUsd: true,
                                        ),
                                      ),
                                      const Positioned(
                                        top: 8,
                                        right: 8,
                                        child: HelpTooltipIcon(
                                          message: workDynamicsTooltip,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _HoverStatsCard(
                        borderRadius: 16,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final widthPerPoint =
                                currentPeriod == 'month' ? 44.0 : 64.0;
                            final contentWidth = isMobile
                                ? math.max(
                                    constraints.maxWidth,
                                    stats.workDynamics.length * widthPerPoint,
                                  )
                                : constraints.maxWidth;

                            return SizedBox(
                              height: isMobile ? 300 : 280,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: contentWidth,
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 12, 12, 8),
                                        child: WorkDynamicsChart(
                                          data: stats.workDynamics,
                                          isMonthly: currentPeriod != 'month',
                                          currencyLabel: "BYN",
                                          currencySymbol: '\u0440',
                                          isUsd: false,
                                        ),
                                      ),
                                      const Positioned(
                                        top: 8,
                                        right: 8,
                                        child: HelpTooltipIcon(
                                          message: workDynamicsTooltip,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRotateDeviceNotice(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);

    return _HoverStatsCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(
                  isDark ? 0.52 : 0.8,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.screen_rotation_alt_rounded,
                color: scheme.onSurfaceVariant.withOpacity(0.88),
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\u041f\u043e\u0432\u0435\u0440\u043d\u0438\u0442\u0435 \u0443\u0441\u0442\u0440\u043e\u0439\u0441\u0442\u0432\u043e \u0433\u043e\u0440\u0438\u0437\u043e\u043d\u0442\u0430\u043b\u044c\u043d\u043e \u0434\u043b\u044f \u043f\u0440\u043e\u0441\u043c\u043e\u0442\u0440\u0430 \u0433\u0440\u0430\u0444\u0438\u043a\u043e\u0432',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\u0412 \u0433\u043e\u0440\u0438\u0437\u043e\u043d\u0442\u0430\u043b\u044c\u043d\u043e\u0439 \u043e\u0440\u0438\u0435\u043d\u0442\u0430\u0446\u0438\u0438 \u0433\u0440\u0430\u0444\u0438\u043a\u0438 \u0431\u0443\u0434\u0443\u0442 \u0447\u0438\u0442\u0430\u0442\u044c\u0441\u044f \u043b\u0443\u0447\u0448\u0435.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
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
    BuildContext context,
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // 1. Financial Summary Cards
  Widget _buildFinancialSummary(BuildContext context, CurrencyAmount finances) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout = constraints.maxWidth < 560;
        final usdCard = _buildFinanceCard(
          context,
          'Всего USD',
          finances.usd,
          '\$',
          Colors.green,
          compact: useVerticalLayout,
        );
        final bynCard = _buildFinanceCard(
          context,
          'Всего BYN',
          finances.byn,
          'р',
          Colors.indigo,
          compact: useVerticalLayout,
        );

        if (useVerticalLayout) {
          return Column(
            children: [
              usdCard,
              const SizedBox(height: 16),
              bynCard,
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: usdCard),
              const SizedBox(width: 16),
              Expanded(child: bynCard),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceCard(BuildContext context, String title, double amount,
      String symbol, Color color,
      {bool compact = false}) {
    final scheme = Theme.of(context).colorScheme;
    final amountText = '${_formatAmount(amount)} $symbol';

    return _HoverStatsCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
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
          SizedBox(
            width: double.infinity,
            height: compact ? 40 : 44,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amountText,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: compact ? 28 : 30,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                  letterSpacing: -0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper class for chart data

  Widget _buildPieChartCard(BuildContext context, List<_ChartData> data,
      {int paletteOffset = 0}) {
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

    final normalizedData = data.where((item) => item.value > 0).toList();
    final realTotal = normalizedData.fold(0.0, (sum, item) => sum + item.value);

    if (normalizedData.isEmpty || realTotal <= 0) {
      return SizedBox(
        height: _pieChartCardHeight,
        child: _HoverStatsCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: _buildPieChartEmptyState(context),
        ),
      );
    }

    final sortedData = List<_ChartData>.from(normalizedData)
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<({_ChartData original, double visualValue, double realPercent})>
        chartData = [];

    for (final item in sortedData) {
      final realPercent = item.value / realTotal * 100;
      final visualValue = realPercent < 5.0 ? (realTotal * 0.05) : item.value;

      chartData.add((
        original: item,
        visualValue: visualValue,
        realPercent: realPercent,
      ));
    }

    final legendWidget = Column(
      mainAxisSize: MainAxisSize.min,
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
                child: Text(
                  item.original.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
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

    return SizedBox(
      height: _pieChartCardHeight,
      child: _HoverStatsCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final legendMaxWidth = (constraints.maxWidth * 0.42)
                .clamp(150.0, constraints.maxWidth - 24)
                .toDouble();

            return Stack(
              children: [
                Center(
                  child: SizedBox.square(
                    dimension: 170,
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
                            radius: 50,
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
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: legendMaxWidth),
                    child: SingleChildScrollView(
                      child: legendWidget,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPieChartEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(
                isDark ? 0.52 : 0.8,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.pie_chart_outline_rounded,
              color: scheme.onSurfaceVariant.withOpacity(0.88),
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Нет данных для диаграммы',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Карточка заполнится, когда в статистике появятся ненулевые значения.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
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

class _HoverStatsCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const _HoverStatsCard({
    required this.child,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  State<_HoverStatsCard> createState() => _HoverStatsCardState();
}

class _HoverStatsCardState extends State<_HoverStatsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(context, hovered: _isHovered),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
              color: AppDesignTokens.cardBorder(context, hovered: _isHovered)),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context, hovered: _isHovered),
              blurRadius: _isHovered ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
