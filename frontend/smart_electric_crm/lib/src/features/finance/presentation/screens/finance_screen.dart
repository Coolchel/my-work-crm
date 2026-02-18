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
  static const _cardBorderColor = Color(0xFFE5E7EB);
  // Контроллеры для глобальных полей
  final _estimateController = TextEditingController();
  final _notesController = TextEditingController();
  bool _hasChanges = false;
  bool _isDataLoaded = false;

  // Состояние раскрытых проектов (ID проекта -> раскрыт ли)
  final Map<int, bool> _expandedProjects = {};
  final Map<int, bool> _hoveredProjects = {};
  final Map<String, bool> _hoveredStages = {};

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
      margin: const EdgeInsets.fromLTRB(_sectionHPadding, 16, _sectionHPadding, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              color: Colors.grey.shade800,
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
                const Text(
                  '0',
                  style: TextStyle(
                    color: Colors.black45,
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

  Widget _buildProjectCard(UnpaidProjectModel project, int index) {
    final isExpanded = _expandedProjects[project.id] ?? false;
    final isHovered = _hoveredProjects[project.id] ?? false;
    final shouldHighlight = isExpanded || isHovered;
    final hasSource = project.source != null && project.source!.isNotEmpty;
    final isWideHeader = MediaQuery.of(context).size.width >= 1100;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredProjects[project.id] = true),
      onExit: (_) => setState(() => _hoveredProjects[project.id] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: shouldHighlight ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(
            color: shouldHighlight
                ? _financeAccent.withOpacity(0.24)
                : Colors.grey.shade200,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: shouldHighlight
                  ? _financeAccent.withOpacity(0.07)
                  : Colors.black.withOpacity(0.03),
              blurRadius: shouldHighlight ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cardRadius),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: _financeAccent.withOpacity(0.72),
                ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _expandedProjects[project.id] = !isExpanded;
                        });
                      },
                      hoverColor: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _financeAccent.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$index',
                                    style: TextStyle(
                                      color: _financeAccent.withOpacity(0.85),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isWideHeader)
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  project.address,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13.5,
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              _buildProjectMetaPill(
                                                icon: Icons.layers_outlined,
                                                text:
                                                    '${project.stages.length}',
                                                active: true,
                                              ),
                                              if (hasSource) ...[
                                                const SizedBox(width: 4),
                                                _buildProjectMetaPill(
                                                  icon: Icons.info_outline,
                                                  text: project.source!,
                                                  active: false,
                                                  maxTextWidth: 180,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _buildAmountDisplay(
                                          project.totalUsd,
                                          project.totalByn,
                                          fontSize: 11.5,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isExpanded
                                              ? Icons.expand_less_rounded
                                              : Icons.expand_more_rounded,
                                          color: Colors.grey.shade400,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project.address,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            _buildProjectMetaPill(
                                              icon: Icons.layers_outlined,
                                              text:
                                                  '${project.stages.length}',
                                              active: true,
                                            ),
                                            if (hasSource)
                                              _buildProjectMetaPill(
                                                icon: Icons.info_outline,
                                                text: project.source!,
                                                active: false,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      _buildAmountDisplay(
                                        project.totalUsd,
                                        project.totalByn,
                                        fontSize: 11.5,
                                        color: Colors.black,
                                      ),
                                      const SizedBox(height: 3),
                                      Icon(
                                        isExpanded
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded,
                                        color: Colors.grey.shade400,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isExpanded)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50.withOpacity(0.65),
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(10, 6, 10, 6),
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < project.stages.length;
                                      i++) ...[
                                    _buildStageRow(project, project.stages[i]),
                                    if (i < project.stages.length - 1)
                                      Divider(
                                        height: 4,
                                        thickness: 0.6,
                                        color: Colors.grey.shade200,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageRow(UnpaidProjectModel project, UnpaidStageModel stage) {
    final hasExternalAmount =
        stage.externalAmountUsd > 0 || stage.externalAmountByn > 0;
    final stageKey = '${project.id}_${stage.id}';
    final isHovered = _hoveredStages[stageKey] ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredStages[stageKey] = true),
      onExit: (_) => setState(() => _hoveredStages[stageKey] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color:
              isHovered ? _financeAccent.withOpacity(0.035) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final projects = ref.read(projectListProvider).valueOrNull;
            if (projects != null) {
              try {
                final realProject =
                    projects.firstWhere((p) => p.id == project.id);
                final realStage =
                    realProject.stages.firstWhere((s) => s.id == stage.id);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstimateScreen(
                      projectId: realProject.id.toString(),
                      stage: realStage,
                    ),
                  ),
                );
              } catch (e) {
                debugPrint("Navigation error: $e");
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _financeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.engineering_outlined,
                    size: 12,
                    color: _financeAccent.withOpacity(0.8),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.titleDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (stage.updatedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _getStageDateInfo(stage.updatedAt!).text,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStageDateInfo(stage.updatedAt!).color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAmountDisplay(stage.ourAmountUsd, stage.ourAmountByn,
                        fontSize: 12),
                    if (hasExternalAmount) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'из ${_formatExternalAmount(stage.ourAmountUsd + stage.externalAmountUsd, stage.ourAmountByn + stage.externalAmountByn)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 52,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          border:
                              Border.all(color: Colors.grey[300]!, width: 0.5),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _calculateOurShareFactor(stage),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _financeAccent.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 8),
                _PayStageButton(
                  onPressed: () => _markStagePaid(stage.id, stage.titleDisplay),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectMetaPill({
    required IconData icon,
    required String text,
    required bool active,
    double? maxTextWidth,
  }) {
    final background = active
        ? _financeAccent.withOpacity(0.1)
        : Colors.grey.shade100;
    final border = active
        ? _financeAccent.withOpacity(0.28)
        : Colors.grey.shade300;
    final foreground = active ? _financeAccent : Colors.grey.shade700;

    final label = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          if (maxTextWidth != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTextWidth),
              child: label,
            )
          else
            label,
        ],
      ),
    );
  }

  String _formatExternalAmount(double usd, double byn) {
    final parts = <String>[];
    if (usd > 0) parts.add('${usd.toStringAsFixed(0)}\$');
    if (byn > 0) parts.add('${byn.toStringAsFixed(0)}р');
    return parts.join(' + ');
  }

  _StageDateInfo _getStageDateInfo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return _StageDateInfo('Сегодня', Colors.black87);
      } else if (diff.inDays == 1) {
        return _StageDateInfo('Вчера', Colors.grey.shade700);
      } else if (diff.inDays < 4) {
        return _StageDateInfo('${diff.inDays} дн. назад', Colors.grey.shade700);
      } else if (diff.inDays < 7) {
        return _StageDateInfo('${diff.inDays} дн. назад', Colors.grey.shade600);
      } else {
        final formatted =
            '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
        return _StageDateInfo(formatted, Colors.grey.shade600);
      }
    } catch (e) {
      return _StageDateInfo('', Colors.grey);
    }
  }

  double _calculateOurShareFactor(UnpaidStageModel stage) {
    final totalUsd = stage.ourAmountUsd + stage.externalAmountUsd;
    final totalByn = stage.ourAmountByn + stage.externalAmountByn;

    if (totalUsd > 0) {
      return (stage.ourAmountUsd / totalUsd).clamp(0.0, 1.0);
    }
    if (totalByn > 0) {
      return (stage.ourAmountByn / totalByn).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  // Получить самую раннюю дату обновления из этапов проекта
  DateTime _getEarliestStageDate(UnpaidProjectModel project) {
    if (project.stages.isEmpty) {
      return DateTime.now();
    }

    DateTime earliest = DateTime.now();
    for (final stage in project.stages) {
      if (stage.updatedAt != null) {
        try {
          final date = DateTime.parse(stage.updatedAt!);
          if (date.isBefore(earliest)) {
            earliest = date;
          }
        } catch (e) {
          // Игнорируем ошибки парсинга
        }
      }
    }
    return earliest;
  }

  Widget _buildGlobalSettingsSection() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(_sectionHPadding, 12, _sectionHPadding, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes, size: 18, color: _financeAccent),
              SizedBox(width: 8),
              Text(
                'Финансовые заметки',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          _buildInputField(
            label: 'Смета контрагента',
            controller: _estimateController,
            minLines: 2,
            maxLines: null,
          ),
          const SizedBox(height: 10),
          _buildInputField(
            label: 'Заметки',
            controller: _notesController,
            minLines: 2,
            maxLines: null,
          ),
          if (_hasChanges) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save, size: 14),
                label: const Text('Сохранить'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _financeAccent,
                  side: const BorderSide(color: _financeAccent),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(WidgetState.hovered)) {
                        return _financeAccent.withOpacity(0.08);
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20), // Фиксированный отступ снизу
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    int minLines = 1,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            fillColor: Colors.grey[50],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _financeAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _StageDateInfo {
  final String text;
  final Color color;
  _StageDateInfo(this.text, this.color);
}

class _PayStageButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _PayStageButton({required this.onPressed});

  @override
  State<_PayStageButton> createState() => _PayStageButtonState();
}

class _PayStageButtonState extends State<_PayStageButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 108,
        height: 28,
        decoration: BoxDecoration(
          color: _isHovered
              ? _FinanceScreenState._financeAccent.withOpacity(0.16)
              : _FinanceScreenState._financeAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _isHovered
                ? _FinanceScreenState._financeAccent.withOpacity(0.45)
                : _FinanceScreenState._financeAccent.withOpacity(0.25),
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color:
                        _FinanceScreenState._financeAccent.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isHovered
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 12,
                    color: _FinanceScreenState._financeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isHovered ? 'Оплачено' : 'Не оплачено',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _FinanceScreenState._financeAccent,
                    ),
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



