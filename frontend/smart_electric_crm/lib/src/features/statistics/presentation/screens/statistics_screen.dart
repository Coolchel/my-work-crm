import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/features/statistics/data/models/statistics_model.dart';
import 'package:smart_electric_crm/src/features/statistics/data/repositories/statistics_repository.dart';
import 'package:smart_electric_crm/src/features/statistics/presentation/widgets/work_dynamics_chart.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/compact_section_app_bar.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/content_tab_strip.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';

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
  static const List<String> _periodValues = ['month', 'year', 'all'];
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
    final sign = amount < 0 ? '-' : '';
    final fixed = amount.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final integerPart = _groupThousands(parts[0]);
    final decimalPart = parts[1].replaceFirst(RegExp(r'0+$'), '');

    if (decimalPart.isEmpty) {
      return '$sign$integerPart';
    }
    return '$sign$integerPart.$decimalPart';
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

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final isMobile = viewport.width < 600;
    final isDesktopWeb = DesktopWebFrame.isDesktop(context, minWidth: 1180);
    final horizontalContentPadding = DesktopWebFrame.contentHorizontalPadding(
      context,
      desktop: 16,
    );
    final shellSidebarInset = DesktopWebFrame.persistentShellContentInset(
      context,
    );
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
    final headerStripeColor =
        isDark ? scheme.primary.withOpacity(0.76) : statisticsAccent;
    final periodItems = <ContentTabStripItem>[
      const ContentTabStripItem(
        label: '\u041c\u0435\u0441\u044f\u0446',
        icon: Icons.calendar_view_month,
        keyName: 'statistics_period_month',
      ),
      const ContentTabStripItem(
        label: '\u0413\u043e\u0434',
        icon: Icons.calendar_today,
        keyName: 'statistics_period_year',
      ),
      ContentTabStripItem(
        label: isMobile
            ? '\u0412\u0441\u0435'
            : '\u0412\u0441\u0435 \u0432\u0440\u0435\u043c\u044f',
        icon: Icons.history,
        keyName: 'statistics_period_all',
      ),
    ];
    final selectedPeriodIndex = _periodValues.indexOf(currentPeriod);
    final statisticsSwitcherTopPadding = isMobile ? 6.0 : 8.0;
    final statisticsSwitcherBottomPadding = isMobile ? 2.0 : 4.0;
    final statisticsSwitcherOverlayHeight = isMobile ? 52.0 : 58.0;
    final statisticsSwitcherItemWidth = isMobile ? 108.0 : 152.0;

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
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(left: shellSidebarInset),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalContentPadding,
                        (isDesktopWeb ? 18 : 12) +
                            statisticsSwitcherOverlayHeight,
                        horizontalContentPadding,
                        16,
                      ),
                      child: DesktopWebPageFrame(
                        maxWidth: 1380,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Переключатель периода
                            const SizedBox(height: 6),

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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                .map((e) =>
                                                    _ChartData(e.name, e.usd))
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                .map((e) =>
                                                    _ChartData(e.name, e.usd))
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
                                  _buildWorkDynamicsCard(
                                    stats: stats,
                                    currentPeriod: currentPeriod,
                                    isMobile: isMobile,
                                    currencyLabel: "USD",
                                    currencySymbol: "\$",
                                    isUsd: true,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildWorkDynamicsCard(
                                    stats: stats,
                                    currentPeriod: currentPeriod,
                                    isMobile: isMobile,
                                    currencyLabel: "BYN",
                                    currencySymbol: '\u0440',
                                    isUsd: false,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(left: shellSidebarInset),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalContentPadding,
                    ),
                    child: DesktopWebPageFrame(
                      maxWidth: 1380,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ContentTabStrip(
                          key: const ValueKey('statistics_period_switcher'),
                          items: periodItems,
                          selectedIndex: selectedPeriodIndex == -1
                              ? 0
                              : selectedPeriodIndex,
                          topPadding: statisticsSwitcherTopPadding,
                          bottomPadding: statisticsSwitcherBottomPadding,
                          sidePadding: 0,
                          itemWidth: statisticsSwitcherItemWidth,
                          onSelected: (index) {
                            ref
                                .read(statisticsFilterProvider.notifier)
                                .setPeriod(_periodValues[index]);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkDynamicsCard({
    required StatisticsModel stats,
    required String currentPeriod,
    required bool isMobile,
    required String currencyLabel,
    required String currencySymbol,
    required bool isUsd,
  }) {
    final accentColor = isUsd ? Colors.green : Colors.indigo;

    return _HoverStatsCard(
      borderRadius: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widthPerPoint = currentPeriod == 'month' ? 44.0 : 64.0;
          final contentWidth = isMobile
              ? math.max(
                  constraints.maxWidth,
                  stats.workDynamics.length * widthPerPoint,
                )
              : constraints.maxWidth;

          return SizedBox(
            height: isMobile ? 300 : 280,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _buildWorkDynamicsCardHeader(
                    context,
                    title: '$currencyLabel $currencySymbol',
                    subtitle: 'Заработок по сделанным объектам',
                    accentColor: accentColor,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                        child: WorkDynamicsChart(
                          data: stats.workDynamics,
                          isMonthly: currentPeriod != 'month',
                          currencyLabel: currencyLabel,
                          currencySymbol: currencySymbol,
                          isUsd: isUsd,
                          showLegend: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkDynamicsCardHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textStyles.cardTitle.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRotateDeviceNotice(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;

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
              style: textStyles.sectionTitle.copyWith(
                fontSize: 15,
                height: 1.35,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\u0412 \u0433\u043e\u0440\u0438\u0437\u043e\u043d\u0442\u0430\u043b\u044c\u043d\u043e\u0439 \u043e\u0440\u0438\u0435\u043d\u0442\u0430\u0446\u0438\u0438 \u0433\u0440\u0430\u0444\u0438\u043a\u0438 \u0431\u0443\u0434\u0443\u0442 \u0447\u0438\u0442\u0430\u0442\u044c\u0441\u044f \u043b\u0443\u0447\u0448\u0435.',
              textAlign: TextAlign.center,
              style: textStyles.secondaryBody.copyWith(
                fontSize: 12,
                height: 1.35,
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
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;
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
          style: textStyles.sectionTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
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
    final textStyles = context.appTextStyles;
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
                style: textStyles.metricLabel.copyWith(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
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
          const SizedBox(height: 12),
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
                style: textStyles.metricValue.copyWith(
                  fontSize: compact ? 26 : 28,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                  letterSpacing: -0.6,
                  height: 1.0,
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
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;
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

    return SizedBox(
      height: _pieChartCardHeight,
      child: _HoverStatsCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;
            final legendMaxWidth =
                (constraints.maxWidth * (isCompact ? 0.56 : 0.42))
                    .clamp(150.0, constraints.maxWidth - 24)
                    .toDouble();
            final compactLabelMaxWidth =
                (legendMaxWidth - 14).clamp(96.0, legendMaxWidth).toDouble();
            final regularLabelMaxWidth =
                (legendMaxWidth - 54).clamp(78.0, legendMaxWidth).toDouble();
            final legendWidget = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final color = palette[(index + paletteOffset) % palette.length];
                final amountLabel = '${_formatAmount(item.original.value)}\$';

                final nameText = Text(
                  item.original.name,
                  maxLines: isCompact ? 3 : 2,
                  softWrap: true,
                  style: textStyles.chartLabel.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  textAlign: TextAlign.right,
                );

                final amountText = Text(
                  amountLabel,
                  style: textStyles.chartLabel.copyWith(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: legendMaxWidth),
                      child: isCompact
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: compactLabelMaxWidth,
                                      ),
                                      child: nameText,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                amountText,
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: regularLabelMaxWidth,
                                  ),
                                  child: nameText,
                                ),
                                const SizedBox(width: 8),
                                amountText,
                              ],
                            ),
                    ),
                  ),
                );
              }).toList(),
            );
            final pieChart = Center(
              child: SizedBox.square(
                dimension: isCompact ? 148 : 170,
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
                        titleStyle: textStyles.chartLabel.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );

            return Stack(
              children: [
                pieChart,
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
    final textStyles = context.appTextStyles;
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
            style: textStyles.sectionTitle.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Карточка заполнится, когда в статистике появятся ненулевые значения.',
            textAlign: TextAlign.center,
            style: textStyles.secondaryBody.copyWith(
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
