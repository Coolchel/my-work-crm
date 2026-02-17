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
    final effectiveColor = color ?? Colors.green;

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
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Ошибка: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(unpaidProjectsProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (data) => _buildContent(data, settingsAsync),
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.green.withOpacity(0.05),
            Colors.green.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Итого к получению',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (totalUsd > 0 && totalByn > 0) const SizedBox(height: 2),
              if (totalByn > 0)
                Text(
                  '${_formatAmount(totalByn)} р',
                  style: const TextStyle(
                    color: Colors.green,
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
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
          const SizedBox(height: 12),
          const Text(
            'Все этапы оплачены!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(UnpaidProjectModel project, int index) {
    final isExpanded = _expandedProjects[project.id] ?? false;
    final isHovered = _hoveredProjects[project.id] ?? false;
    final shouldHighlight = isExpanded || isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredProjects[project.id] = true),
      onExit: (_) => setState(() => _hoveredProjects[project.id] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: shouldHighlight
              ? Colors.green.shade50.withOpacity(0.22)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: shouldHighlight
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.shade200,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: shouldHighlight
                  ? Colors.green.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: shouldHighlight ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Акцентная полоса слева
                Container(
                  width: 4,
                  color: Colors.green.withOpacity(0.7),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Кликабельный заголовок проекта
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedProjects[project.id] = !isExpanded;
                          });
                        },
                        hoverColor: Colors.transparent,
                        child: Container(
                          // Добавляем подсветку при раскрытии
                          color: isExpanded
                              ? Colors.green.withOpacity(0.03)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              // Порядковый номер слева
                              Text(
                                '$index.',
                                style: TextStyle(
                                  color: Colors.green.withOpacity(0.5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.address,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14, // Уменьшили с 15
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    if (project.source != null &&
                                        project.source!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 0.5),
                                        ),
                                        child: Text(
                                          project.source!,
                                          style: TextStyle(
                                            fontSize: 9, // Уменьшили с 10
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Перенесли суммы сюда
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildAmountDisplay(
                                      project.totalUsd, project.totalByn,
                                      fontSize: 12,
                                      color: Colors.black), // Чисто черный
                                ],
                              ),
                              const SizedBox(width: 12),
                              const SizedBox(width: 8),
                              // Красивая плашка с количеством этапов
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.withOpacity(0.12),
                                      Colors.green.withOpacity(0.06),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.layers_outlined,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${project.stages.length}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Декоративная стрелочка перенесена вправо и стала серой
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Раскрывающийся список этапов
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 12, right: 12, bottom: 4),
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < project.stages.length;
                                  i++) ...[
                                _buildStageRow(project, project.stages[i]),
                                if (i < project.stages.length - 1)
                                  Divider(
                                    height: 1, // Минимум пространства
                                    thickness: 0.5,
                                    color: Colors.grey[200],
                                    indent: 0,
                                    endIndent: 0,
                                  ),
                              ],
                            ],
                          ),
                        ),
                    ],
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
        decoration: BoxDecoration(
          color:
              isHovered ? Colors.green.withOpacity(0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.titleDisplay,
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (stage.updatedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _getStageDateInfo(stage.updatedAt!).text,
                            style: TextStyle(
                              fontSize: 11,
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
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 60,
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
                                  color: Colors.green.withOpacity(0.8),
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes, size: 18, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Финансовые заметки',
                style: TextStyle(
                  fontSize: 14,
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
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.green.withOpacity(0.08);
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
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            fillColor: Colors.grey[50],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green, width: 1),
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
        width: 118,
        height: 30,
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.green.withOpacity(0.16)
              : Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _isHovered
                ? Colors.green.withOpacity(0.45)
                : Colors.green.withOpacity(0.25),
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.12),
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
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isHovered
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isHovered ? 'Оплачено' : 'Не оплачено',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
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
