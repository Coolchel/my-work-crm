import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/unpaid_project_model.dart';
import '../../data/models/finance_settings_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../../../shared/presentation/dialogs/confirmation_dialog.dart';
import '../../../../shared/presentation/widgets/inline_save_button.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../../../shared/presentation/widgets/compact_section_app_bar.dart';
import '../../../../shared/presentation/widgets/desktop_web_frame.dart';
import '../../../../shared/presentation/widgets/friendly_empty_state.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/navigation/app_navigation.dart';

part 'finance_screen.g.dart';
part '../widgets/finance_screen_sections.dart';

// Провайдер для загрузки данных финансового монитора
@riverpod
Future<UnpaidProjectsResponse> unpaidProjects(Ref ref) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.fetchUnpaidProjects();
}

// Провайдер для загрузки глобальных настроек
@riverpod
Future<FinanceSettingsModel> financeSettings(Ref ref) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getSettings();
}

class FinanceScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const FinanceScreen({
    this.onBackPressed,
    super.key,
  });

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  static const _financeAccent = Colors.green;
  static const _cardRadius = AppDesignTokens.radiusM;
  static const _desktopSectionHPadding = AppDesignTokens.spacingM;
  // Контроллеры для глобальных полей
  final _estimateController = TextEditingController();
  final _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SectionAppBarCollapseController _appBarCollapseController =
      SectionAppBarCollapseController();
  bool _hasChanges = false;
  bool _isDataLoaded = false;
  Object? _scrollAttachment;

  // Состояние раскрытых проектов (ID проекта -> раскрыт ли)
  final Map<int, bool> _expandedProjects = {};
  final Map<int, bool> _hoveredProjects = {};
  final Map<String, bool> _hoveredStages = {};

  void _setProjectHovered(int projectId, bool value) {
    setState(() => _hoveredProjects[projectId] = value);
  }

  void _toggleProjectExpanded(int projectId) {
    final current = _expandedProjects[projectId] ?? false;
    setState(() => _expandedProjects[projectId] = !current);
  }

  void _setStageHovered(String key, bool value) {
    setState(() => _hoveredStages[key] = value);
  }

  @override
  void initState() {
    super.initState();
    _appBarCollapseController.bind(_scrollController);
    _scrollAttachment =
        AppNavigation.financeScrollController.attach(_scrollToTop);
    _estimateController.addListener(_onTextChanged);
    _notesController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_isDataLoaded && !_hasChanges) {
      if (mounted) setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.financeScrollController.detach(scrollAttachment);
    }
    _appBarCollapseController.dispose();
    _scrollController.dispose();
    _estimateController.dispose();
    _notesController.dispose();
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

  double _sectionHPadding(BuildContext context) {
    return DesktopWebFrame.contentHorizontalPadding(
      context,
      desktop: _desktopSectionHPadding,
    );
  }

  Widget _buildAmountDisplay(double usd, double byn,
      {double fontSize = 13, Color? color}) {
    final List<TextSpan> spans = [];
    final effectiveColor = color ?? _financeAccent;

    if (usd > 0) {
      spans.add(TextSpan(
        text: '${_formatAmount(usd)} \$',
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ));
    }

    if (usd > 0 && byn > 0) {
      spans.add(TextSpan(
        text: ' + ',
        style: TextStyle(color: Colors.grey[500], fontSize: fontSize * 0.85),
      ));
    }

    if (byn > 0) {
      spans.add(TextSpan(
        text: '${_formatAmount(byn)} р',
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ));
    }

    if (spans.isEmpty) {
      return Text('0',
          style: TextStyle(color: Colors.grey[400], fontSize: fontSize));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _markStagePaid(int stageId, String stageTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Закрыть этап?',
        content: 'Отметить "$stageTitle" как оплаченный?',
        confirmText: 'Закрыть',
        themeColor: Colors.green,
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(financeRepositoryProvider);
        await repository.markStagePaid(stageId);
        ref.invalidate(unpaidProjectsProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.updateSettings(
        partnerExternalEstimate: _estimateController.text,
        financialNotes: _notesController.text,
      );
      setState(() => _hasChanges = false);
      ref.invalidate(financeSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Сохранено'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(unpaidProjectsProvider);
    final settingsAsync = ref.watch(financeSettingsProvider);
    final handleBack =
        widget.onBackPressed ?? () => Navigator.of(context).maybePop();

    // Безопасная инициализация данных
    if (!_isDataLoaded && settingsAsync.hasValue && !settingsAsync.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDataLoaded && mounted) {
          final settings = settingsAsync.value!;
          _estimateController.text = settings.partnerExternalEstimate;
          _notesController.text = settings.financialNotes;
          _isDataLoaded = true;
        }
      });
    }

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
            title: 'Финансы',
            icon: Icons.account_balance_wallet_rounded,
            gradientColors: AppDesignTokens.subtleSectionGradient,
          ),
          body: child!,
        );
      },
      child: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => FriendlyEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Не удалось загрузить данные финансов',
          subtitle: 'Проверьте соединение и попробуйте снова.\n$error',
          accentColor: Colors.red,
          action: FilledButton.icon(
            onPressed: () => ref.invalidate(unpaidProjectsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Повторить'),
          ),
        ),
        data: (data) => _buildContent(data, settingsAsync),
      ),
    );
  }

  Widget _buildProjectsHeader(int projectsCount) {
    final sectionHPadding = _sectionHPadding(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(sectionHPadding, 10, sectionHPadding, 4),
      child: Row(
        children: [
          Text(
            'Неоплаченные объекты',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _financeAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _financeAccent.withOpacity(0.24)),
            ),
            child: Text(
              '$projectsCount',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _financeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(UnpaidProjectsResponse data,
      AsyncValue<FinanceSettingsModel> settingsAsync) {
    // Инициализация контроллеров перенесена в build с использованием addPostFrameCallback
    final isDesktopWeb = DesktopWebFrame.isDesktop(context, minWidth: 1240);
    final sectionHPadding = _sectionHPadding(context);
    final usesMobileContentPadding = DesktopWebFrame.usesMobileContentPadding(
      context,
    );
    final shellSidebarInset = DesktopWebFrame.persistentShellContentInset(
      context,
    );
    final sortedProjects = data.projects.toList()
      ..sort((a, b) {
        final aDate = _getEarliestStageDate(a);
        final bDate = _getEarliestStageDate(b);
        return aDate.compareTo(bDate);
      });

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(unpaidProjectsProvider);
        ref.invalidate(financeSettingsProvider);
        // Даём время на обновление
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(left: shellSidebarInset),
          child: DesktopWebPageFrame(
            maxWidth: 1380,
            padding: EdgeInsets.fromLTRB(
              usesMobileContentPadding ? 0 : sectionHPadding,
              isDesktopWeb ? 24 : 0,
              usesMobileContentPadding ? 0 : sectionHPadding,
              0,
            ),
            child: isDesktopWeb
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            if (data.projects.isEmpty)
                              _buildEmptyState()
                            else
                              Column(
                                children: [
                                  _buildProjectsHeader(data.projects.length),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: sectionHPadding,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      children: sortedProjects
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => _buildProjectCard(
                                              entry.value,
                                              entry.key + 1,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 380,
                        child: Column(
                          children: [
                            IgnorePointer(
                              child: Opacity(
                                opacity: 0,
                                child:
                                    _buildProjectsHeader(data.projects.length),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTotalSection(data.totalUsd, data.totalByn),
                            _buildGlobalSettingsSection(),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      if (data.projects.isEmpty)
                        _buildEmptyState()
                      else
                        Column(
                          children: [
                            _buildProjectsHeader(data.projects.length),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: sectionHPadding,
                                vertical: 8,
                              ),
                              child: Column(
                                children: sortedProjects
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => _buildProjectCard(
                                        entry.value,
                                        entry.key + 1,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      _buildTotalSection(data.totalUsd, data.totalByn),
                      _buildGlobalSettingsSection(),
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSection(double totalUsd, double totalByn) {
    return Column(
      children: [
        _buildCurrencyTotalCard(
          title: 'К получению USD',
          amount: totalUsd,
          symbol: '\$',
          accentColor: Colors.green,
          icon: Icons.attach_money_rounded,
        ),
        const SizedBox(height: 12),
        _buildCurrencyTotalCard(
          title: 'К получению BYN',
          amount: totalByn,
          symbol: 'р',
          accentColor: Colors.indigo,
          icon: Icons.payments_outlined,
        ),
      ],
    );
  }

  Widget _buildCurrencyTotalCard({
    required String title,
    required double amount,
    required String symbol,
    required Color accentColor,
    required IconData icon,
  }) {
    final sectionHPadding = _sectionHPadding(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(sectionHPadding, 0, sectionHPadding, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border:
            Border.all(color: AppDesignTokens.cardBorder(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppDesignTokens.cardShadow(context),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            amount > 0 ? '${_formatAmount(amount)} $symbol' : '0',
            style: TextStyle(
              color: accentColor,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const FriendlyEmptyState(
      icon: Icons.check_circle_outline_rounded,
      title: 'Все этапы оплачены',
      subtitle: 'Новых задолженностей сейчас нет.',
      accentColor: Colors.green,
      iconSize: 72,
      padding: EdgeInsets.all(24),
    );
  }
}
