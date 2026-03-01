import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/unpaid_project_model.dart';
import '../../data/models/finance_settings_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../../../shared/presentation/dialogs/confirmation_dialog.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../../projects/presentation/screens/estimate_screen.dart';
import '../../../../shared/presentation/widgets/compact_section_app_bar.dart';
import '../../../../shared/presentation/widgets/friendly_empty_state.dart';
import '../../../../core/theme/app_design_tokens.dart';

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
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  static const _financeAccent = Colors.green;
  static const _cardRadius = AppDesignTokens.radiusM;
  static const _sectionHPadding = AppDesignTokens.spacingM;
  // Контроллеры для глобальных полей
  final _estimateController = TextEditingController();
  final _notesController = TextEditingController();
  bool _hasChanges = false;
  bool _isDataLoaded = false;

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
    _estimateController.dispose();
    _notesController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: const CompactSectionAppBar(
        title: 'Финансы',
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: AppDesignTokens.subtleSectionGradient,
      ),
      body: projectsAsync.when(
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
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(_sectionHPadding, 10, _sectionHPadding, 4),
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

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(unpaidProjectsProvider);
        ref.invalidate(financeSettingsProvider);
        // Даём время на обновление
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Список проектов
            if (data.projects.isEmpty)
              _buildEmptyState()
            else
              Column(
                children: [
                  _buildProjectsHeader(data.projects.length),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _sectionHPadding, vertical: 8),
                    child: Column(
                      children: [
                        // Сортировка: сверху - старые, снизу - новые
                        ...(data.projects.toList()
                              ..sort((a, b) {
                                final aDate = _getEarliestStageDate(a);
                                final bDate = _getEarliestStageDate(b);
                                return aDate.compareTo(bDate);
                              }))
                            .asMap()
                            .entries
                            .map((entry) =>
                                _buildProjectCard(entry.value, entry.key + 1)),
                      ],
                    ),
                  ),
                ],
              ),

            // Блок "Итого к получению" внизу
            _buildTotalSection(data.totalUsd, data.totalByn),

            // Глобальные поля заметок
            _buildGlobalSettingsSection(),

            const SizedBox(height: 80), // Отступ снизу
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(double totalUsd, double totalByn) {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(_sectionHPadding, 16, _sectionHPadding, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _financeAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: _financeAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Итого к получению',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (totalUsd > 0)
                Text(
                  '${_formatAmount(totalUsd)} \$',
                  style: const TextStyle(
                    color: _financeAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (totalUsd > 0 && totalByn > 0) const SizedBox(height: 2),
              if (totalByn > 0)
                Text(
                  '${_formatAmount(totalByn)} р',
                  style: const TextStyle(
                    color: _financeAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (totalUsd == 0 && totalByn == 0)
                Text(
                  '0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
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
