import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../../data/models/project_model.dart';
import 'engineering_tab.dart';
import 'estimate_screen.dart';
import 'file_viewer_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/confirmation_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/text_input_dialog.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/compact_section_app_bar.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'dart:io';
import '../../data/models/project_file_model.dart';
import '../../../../shared/services/temp_file_service.dart';
import '../widgets/stages/stage_card.dart';

import '../../data/models/stage_model.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectListAsync = ref.watch(projectListProvider);

    return projectListAsync.when(
      data: (projects) {
        try {
          final project = projects.firstWhere(
            (p) => p.id.toString() == projectId,
          );
          return _ProjectDetailContent(project: project);
        } catch (_) {
          return Scaffold(
            appBar: CompactSectionAppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                tooltip: 'Назад',
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: 'Объект',
              subtitle: 'Детали',
              icon: Icons.apartment_rounded,
            ),
            body: const Center(child: Text('Объект не найден')),
          );
        }
      },
      loading: () => Scaffold(
        appBar: CompactSectionAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: 'Назад',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: 'Объект',
          subtitle: 'Загрузка',
          icon: Icons.apartment_rounded,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: CompactSectionAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: 'Назад',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: 'Объект',
          subtitle: 'Ошибка загрузки',
          icon: Icons.apartment_rounded,
        ),
        body: Center(child: Text('Ошибка: $error')),
      ),
    );
  }
}

class _ProjectDetailContent extends ConsumerStatefulWidget {
  final ProjectModel project;

  const _ProjectDetailContent({required this.project});

  @override
  ConsumerState<_ProjectDetailContent> createState() =>
      _ProjectDetailContentState();
}

class _ProjectDetailContentState extends ConsumerState<_ProjectDetailContent> {
  int _currentIndex = 0;
  static const List<String> _tabTitles = ['Этапы', 'Щиты', 'Файлы'];
  static const List<IconData> _tabIcons = [
    Icons.layers_rounded,
    Icons.settings_input_component_rounded,
    Icons.folder_open_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      _StagesTab(project: widget.project),
      EngineeringTab(project: widget.project),
      _FilesTab(project: widget.project),
    ];

    return Scaffold(
      appBar: CompactSectionAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'Назад',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _tabTitles[_currentIndex],
        subtitle: widget.project.address,
        icon: _tabIcons[_currentIndex],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers),
            label: 'Этапы',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_input_component_outlined),
            selectedIcon: Icon(Icons.settings_input_component),
            label: 'Щиты',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder_open),
            label: 'Файлы',
          ),
        ],
      ),
    );
  }
}

class _StagesTab extends ConsumerWidget {
  final ProjectModel project;

  const _StagesTab({required this.project});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref,
      String stageId, String newStatus) async {
    // Simpler signature
    await ref
        .read(projectOperationsProvider.notifier)
        .updateStageStatus(stageId, newStatus);
  }

  Future<void> _deleteStage(
      BuildContext context, WidgetRef ref, StageModel stage) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Удаление этапа',
        content:
            'Вы уверены, что хотите удалить этап "${StageCard.getStageTitleDisplay(stage.title)}"? Все сметы внутри будут удалены.',
        confirmText: 'Удалить',
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(projectRepositoryProvider).deleteStage(stage.id);
        // Force refresh
        ref.invalidate(projectListProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: Tooltip(
        message: 'Добавить этап',
        preferBelow: false,
        verticalOffset: 32,
        child: FloatingActionButton(
          onPressed: () => _showAddStageDialog(context, ref),
          backgroundColor: Colors.indigo,
          foregroundColor: Theme.of(context).colorScheme.surface,
          child: const Icon(Icons.add),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header "OBJECT"
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Об объекте',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
              ),
            ),
            // Premium Project Info Header
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Accent stripe
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 5,
                    child: Container(color: Colors.indigo),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заказчик
                        _DetailInfoRow(
                          icon: Icons.person_outline,
                          label: 'ЗАКАЗЧИК',
                          value: project.clientInfo.isNotEmpty
                              ? project.clientInfo
                              : '—',
                          color: Colors.blue.shade600,
                          selectable: true,
                        ),
                        const SizedBox(height: 16),
                        // Источник
                        _DetailInfoRow(
                          icon: Icons.info_outline,
                          label: 'ИСТОЧНИК',
                          value:
                              project.source.isNotEmpty ? project.source : '—',
                          color: Colors.teal.shade700,
                          selectable: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Text(
                  'Этапы работ',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (project.stages.isEmpty)
              const FriendlyEmptyState(
                icon: Icons.layers_clear_rounded,
                title: 'Этапы еще не созданы',
                subtitle:
                    'Добавьте первый этап, чтобы продолжить работу по объекту.',
                accentColor: Colors.indigo,
                padding: EdgeInsets.symmetric(vertical: 8),
              ),

            // List of Stages
            ...project.stages.map((stage) {
              return StageCard(
                stage: stage,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EstimateScreen(
                        stage: stage,
                        projectId: project.id.toString(),
                      ),
                    ),
                  );
                },
                onStatusChanged: (newStatus) =>
                    _updateStatus(context, ref, stage.id.toString(), newStatus),
                onDelete: () => _deleteStage(context, ref, stage),
              );
            }),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  // Helpers (Duplicated for now, should be moved to Utils or mixin)

  void _showAddStageDialog(BuildContext context, WidgetRef ref) {
    final existingKeys = project.stages.map((s) => s.title).toList();

    showDialog(
      context: context,
      builder: (context) => _AddStageDialog(
        projectId: project.id.toString(),
        existingStageKeys: existingKeys,
      ),
    );
  }
}

class _AddStageDialog extends ConsumerStatefulWidget {
  final String projectId;
  final List<String> existingStageKeys;

  const _AddStageDialog({
    required this.projectId,
    required this.existingStageKeys,
  });

  @override
  ConsumerState<_AddStageDialog> createState() => _AddStageDialogState();
}

class _AddStageDialogState extends ConsumerState<_AddStageDialog> {
  bool _isLoading = false;

  final Map<String, String> _allStages = {
    'precalc': 'Предпросчет',
    'stage_1': 'Этап 1 (Черновой)',
    'stage_1_2': 'Этап 1+2 (Черновой)',
    'stage_2': 'Этап 2 (Черновой)',
    'stage_3': 'Этап 3 (Чистовой)',
    'extra': 'Доп. работы',
    'other': 'Другое',
  };

  Map<String, String> get _availableStages {
    final available = Map<String, String>.from(_allStages);
    for (final key in widget.existingStageKeys) {
      if (key != 'extra' &&
          key != 'other' &&
          key != 'precalc' &&
          key != 'stage_1_2' &&
          key != 'stage_3') {
        available.remove(key);
      }
    }
    return available;
  }

  Future<void> _addStage(String stageKey) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(projectOperationsProvider.notifier)
          .addStage(widget.projectId, stageKey);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Этап успешно добавлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = _availableStages;
    const themeColor = Colors.indigo;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppDesignTokens.cardBorder(context)),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: themeColor.withOpacity(0.1)),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    "Выберите этап",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(
                                AppDesignTokens.isDark(context) ? 0.22 : 0.5,
                              ),
                        ),
                        child: Icon(Icons.close,
                            size: 18, color: themeColor.withOpacity(0.8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            if (_isLoading)
              const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()))
            else if (stages.isEmpty)
              const FriendlyEmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Все основные этапы уже созданы',
                subtitle: 'При необходимости добавьте дополнительный этап.',
                accentColor: Colors.green,
                padding: EdgeInsets.all(20),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  itemCount: stages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = stages.entries.elementAt(index);
                    final stageKey = entry.key;
                    Color itemColor;
                    switch (stageKey) {
                      case 'precalc':
                        itemColor = Colors.blueGrey;
                        break;
                      case 'stage_1':
                      case 'stage_1_2':
                      case 'stage_2':
                        itemColor = Colors.blue;
                        break;
                      case 'stage_3':
                        itemColor = Colors.green;
                        break;
                      case 'extra':
                        itemColor = Colors.purple;
                        break;
                      default:
                        itemColor = Colors.amber;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _addStage(entry.key),
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: itemColor.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: itemColor.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add,
                                      size: 18, color: itemColor),
                                ),
                              ],
                            ), // Row
                          ), // Padding
                        ), // InkWell
                      ), // Material
                    ); // Container
                  }, // itemBuilder
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FilesTab extends ConsumerWidget {
  final ProjectModel project;

  const _FilesTab({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              _FileCategorySection(
                title: "Проекты и схемы",
                icon: Icons.architecture_rounded,
                color: Colors.blueGrey,
                category: "PROJECT",
                files: project.files
                    .where((f) => f.category == "PROJECT")
                    .toList(),
                onDelete: (fileId) => _deleteFile(context, ref, fileId),
                onUpload: () => _pickAndUploadFiles(context, ref, "PROJECT"),
                projectId: project.id.toString(),
              ),
              _FileCategorySection(
                title: "Реализация (Этапы 1-2)",
                icon: Icons.construction_rounded,
                color: Colors.blue,
                category: "WORK",
                files:
                    project.files.where((f) => f.category == "WORK").toList(),
                onDelete: (fileId) => _deleteFile(context, ref, fileId),
                onUpload: () => _pickAndUploadFiles(context, ref, "WORK"),
                projectId: project.id.toString(),
              ),
              _FileCategorySection(
                title: "Финишные фото",
                icon: Icons.auto_awesome_rounded,
                color: Colors.green,
                category: "FINISH",
                files:
                    project.files.where((f) => f.category == "FINISH").toList(),
                onDelete: (fileId) => _deleteFile(context, ref, fileId),
                onUpload: () => _pickAndUploadFiles(context, ref, "FINISH"),
                projectId: project.id.toString(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              "Лимит загрузки: до 12 файлов на проект, до 20 МБ каждый",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadFiles(
      BuildContext context, WidgetRef ref, String category) async {
    // 1. Проверка лимита количества файлов (Макс 12 на проект)
    if (project.files.length >= 12) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => const ConfirmationDialog(
            title: 'Лимит файлов',
            content:
                'Достигнут лимит в 12 файлов на проект. Удалите старые файлы, чтобы загрузить новые.',
            confirmText: 'Закрыть',
            cancelText: '', // Скрываем кнопку отмены
            isDestructive: false,
            themeColor: Colors.indigo,
          ),
        );
      }
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 2. Выбор файлов с фильтрацией по расширению
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'heic',
        'heif',
        'pdf',
        'docx',
        'xls',
        'xlsx',
        'txt',
        'zip',
        'mp4',
        'mov'
      ],
    );

    if (result != null && result.files.isNotEmpty) {
      // Проверка: не превысит ли добавление новых файлов общий лимит
      if (project.files.length + result.files.length > 12) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => ConfirmationDialog(
              title: 'Слишком много файлов',
              content:
                  'Вы выбрали ${result.files.length} файлов для загрузки. В текущий проект можно загрузить еще не более ${12 - project.files.length} файлов.',
              confirmText: 'Закрыть',
              cancelText: '',
              isDestructive: false,
              themeColor: Colors.indigo,
            ),
          );
        }
        return;
      }

      final notifier = ref.read(projectOperationsProvider.notifier);
      int successCount = 0;
      List<String> sizeErrors = [];
      List<String> uploadErrors = [];

      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Начинаю загрузку ${result.files.length} файлов...')),
      );

      for (final pickedFile in result.files) {
        if (pickedFile.path == null) {
          uploadErrors
              .add('${pickedFile.name}: не удалось получить путь к файлу');
          continue;
        }
        // 3. Проверка размера файла (Макс 20 МБ)
        final file = File(pickedFile.path!);
        final sizeInBytes = await file.length();
        final sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 20) {
          sizeErrors.add(
            '${pickedFile.name} (${sizeInMb.toStringAsFixed(1)} МБ)',
          );
          continue;
        }

        try {
          await notifier.uploadFile(
            projectId: project.id,
            filePath: pickedFile.path!,
            fileName: pickedFile.name,
            category: category,
          );
          successCount++;
        } catch (e) {
          uploadErrors.add('${pickedFile.name}: $e');
          debugPrint("Upload failed: $e");
        }
      }

      // 4. Итоговый отчет
      if (sizeErrors.isNotEmpty && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => ConfirmationDialog(
            title: 'Некоторые файлы не загружены',
            content:
                'Следующие файлы превышают лимит в 20 МБ:\n\n${sizeErrors.join('\n')}',
            confirmText: 'Закрыть',
            cancelText: '',
            isDestructive: false,
            themeColor: Colors.indigo,
          ),
        );
      }

      if (uploadErrors.isNotEmpty && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => ConfirmationDialog(
            title: 'Часть файлов не загружена',
            content: uploadErrors.join('\n'),
            confirmText: 'Закрыть',
            cancelText: '',
            isDestructive: false,
            themeColor: Colors.indigo,
          ),
        );
      }

      if (successCount > 0) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text(
                  'Успешно загружено: $successCount из ${result.files.length}')),
        );
      }
    }
  }

  Future<void> _deleteFile(
      BuildContext context, WidgetRef ref, int fileId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Удалить файл?',
        content:
            'Это действие нельзя отменить. Файл будет физически удален с сервера.',
        confirmText: 'Удалить',
        cancelText: 'Отмена',
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      await ref.read(projectOperationsProvider.notifier).deleteFile(
            fileId,
            project.id.toString(),
          );
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Файл удален')),
        );
      }
    }
  }
}

class _FileCard extends ConsumerStatefulWidget {
  final ProjectFileModel file;
  final VoidCallback onDelete;
  final String projectId;

  const _FileCard({
    required this.file,
    required this.onDelete,
    required this.projectId,
  });

  @override
  ConsumerState<_FileCard> createState() => _FileCardState();
}

class _FileCardState extends ConsumerState<_FileCard> {
  bool _isHovered = false;
  bool _areTouchActionsVisible = false;

  bool get isImage {
    final ext = widget.file.file.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp');
  }

  bool get isPdf => widget.file.file.toLowerCase().endsWith('.pdf');

  String get displayName => widget.file.originalName.isNotEmpty
      ? widget.file.originalName
      : widget.file.file.split('/').last;

  String get extensionLabel {
    final name = displayName.toLowerCase();
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) {
      return 'FILE';
    }
    return name.substring(dotIndex + 1).toUpperCase();
  }

  Color get fileAccentColor {
    if (isImage) return Colors.teal;
    if (isPdf) return Colors.deepPurple;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final fileUrl = widget.file.file;
    final supportsHover = switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => false,
      _ => true,
    };
    final showActions = supportsHover ? _isHovered : _areTouchActionsVisible;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onLongPress: supportsHover
              ? null
              : () => setState(
                    () => _areTouchActionsVisible = !_areTouchActionsVisible,
                  ),
          onTap: () {
            if (!supportsHover && _areTouchActionsVisible) {
              setState(() => _areTouchActionsVisible = false);
              return;
            }
            _openFile(context, fileUrl);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: _isHovered
                    ? fileAccentColor.withOpacity(0.25)
                    : Colors.grey.shade200,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: fileAccentColor.withOpacity(0.08),
                        ),
                        child: isImage
                            ? Image.network(
                                fileUrl,
                                fit: BoxFit.cover,
                                cacheWidth: 300,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.broken_image_rounded,
                                        size: 30, color: Colors.grey.shade400),
                              )
                            : Center(
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: fileAccentColor.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isPdf
                                        ? Icons.description_rounded
                                        : Icons.insert_drive_file_rounded,
                                    color: fileAccentColor.withOpacity(0.9),
                                    size: 20,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: fileAccentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              extensionLabel,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: fileAccentColor.withOpacity(0.9),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Кнопки управления (появляются при наведении)
                Positioned(
                  top: 6,
                  right: 6,
                  child: AnimatedOpacity(
                    opacity: showActions ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surface.withOpacity(
                                  AppDesignTokens.isDark(context) ? 0.82 : 0.92,
                                ),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: Icons.edit_rounded,
                            tooltip: "Переименовать",
                            onTap: () => _renameFile(context),
                          ),
                          const SizedBox(width: 4),
                          _ActionButton(
                            icon: Icons.download_rounded,
                            tooltip: "Сохранить как...",
                            onTap: () => _saveAsFile(context, fileUrl),
                          ),
                          const SizedBox(width: 4),
                          _ActionButton(
                            icon: Icons.share_rounded,
                            tooltip: "Поделиться",
                            onTap: () => _shareFile(fileUrl),
                          ),
                          const SizedBox(width: 4),
                          _ActionButton(
                            icon: Icons.close_rounded,
                            tooltip: "Удалить",
                            onTap: widget.onDelete,
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

  void _openFile(BuildContext context, String url) {
    if (isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FileViewerScreen(url: url, title: displayName),
        ),
      );
    } else {
      _downloadAndOpenFile(url);
    }
  }

  Future<void> _renameFile(BuildContext context) async {
    final extension = displayName.contains('.')
        ? displayName.substring(displayName.lastIndexOf('.'))
        : '';
    final nameWithoutExtension = displayName.contains('.')
        ? displayName.substring(0, displayName.lastIndexOf('.'))
        : displayName;

    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => TextInputDialog(
        title: 'Переименовать файл',
        labelText: 'Новое имя',
        initialValue: nameWithoutExtension,
        confirmText: 'Сохранить',
        themeColor: Colors.indigo,
      ),
    );

    if (result is String && result.isNotEmpty) {
      final newName = '$result$extension';
      if (newName != displayName) {
        if (context.mounted) {
          try {
            await ref
                .read(projectOperationsProvider.notifier)
                .renameFile(widget.file.id, newName, widget.projectId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Файл переименован')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка переименования: $e')),
              );
            }
          }
        }
      }
    }
  }

  Future<void> _saveAsFile(BuildContext context, String url) async {
    try {
      // 1. Сначала скачиваем во временную папку
      final response = await http.get(Uri.parse(url));
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$displayName');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Регистрируем временный файл для очистки
      TempFileService().track(tempFile);

      // 2. Открываем диалог сохранения (Desktop)
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить файл как...',
        fileName: displayName,
      );

      if (outputFile != null) {
        await tempFile.copy(outputFile);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Файл сохранен: $outputFile')),
          );
        }
      }
    } catch (e) {
      debugPrint("Save file error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  Future<void> _downloadAndOpenFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final documentDirectory = await getTemporaryDirectory();
      final localFile =
          File('${documentDirectory.path}/${url.split('/').last}');
      await localFile.writeAsBytes(response.bodyBytes);

      // Регистрируем временный файл для очистки
      TempFileService().track(localFile);

      await OpenFilex.open(localFile.path);
    } catch (e) {
      debugPrint("Open file error: $e");
    }
  }

  Future<void> _shareFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final documentDirectory = await getTemporaryDirectory();
      final localFile =
          File('${documentDirectory.path}/${url.split('/').last}');
      await localFile.writeAsBytes(response.bodyBytes);

      // Регистрируем временный файл для очистки
      TempFileService().track(localFile);

      await Share.shareXFiles([XFile(localFile.path)]);
    } catch (e) {
      debugPrint("Share file error: $e");
    }
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _isHovered
                    ? Colors.black.withOpacity(0.12)
                    : Theme.of(context).colorScheme.surface.withOpacity(
                          AppDesignTokens.isDark(context) ? 0.84 : 0.95,
                        ),
                border: Border.all(
                  color: _isHovered
                      ? Colors.black.withOpacity(0.28)
                      : Colors.black.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool selectable;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              selectable
                  ? SelectableText(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FileCategorySection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String category;
  final List<ProjectFileModel> files;
  final Function(int) onDelete;
  final VoidCallback onUpload;
  final String projectId;

  const _FileCategorySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.category,
    required this.files,
    required this.onDelete,
    required this.onUpload,
    required this.projectId,
  });

  @override
  State<_FileCategorySection> createState() => _FileCategorySectionState();
}

class _FileCategorySectionState extends State<_FileCategorySection> {
  bool _isExpanded = false;
  bool _isHovered = false;
  bool _isExpandToggleHovered = false;

  bool _shouldAutoExpandByCount(int count) {
    return count >= 1 && count <= 6;
  }

  @override
  void initState() {
    super.initState();
    // Правило по умолчанию:
    // 0 файлов -> закрыто, 1..6 -> открыто, 7+ -> закрыто.
    _isExpanded = _shouldAutoExpandByCount(widget.files.length);
  }

  @override
  void didUpdateWidget(covariant _FileCategorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.files.length != widget.files.length) {
      _isExpanded = _shouldAutoExpandByCount(widget.files.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(context, hovered: _isHovered),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppDesignTokens.cardBorder(context, hovered: _isHovered),
          ),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context, hovered: _isHovered),
              blurRadius: _isHovered ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: ColoredBox(color: widget.color),
            ),
            Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(19, 14, 14, 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(widget.icon,
                                color: widget.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isExpanded
                                      ? 'Нажмите, чтобы свернуть'
                                      : 'Нажмите, чтобы развернуть',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildFilesCountPill(widget.files.length),
                          const SizedBox(width: 8),
                          _buildHeaderActionButton(
                            icon: Icons.add_rounded,
                            tooltip: 'Загрузить файлы',
                            onTap: widget.onUpload,
                            isPrimary: true,
                          ),
                          const SizedBox(width: 6),
                          _buildHeaderExpandToggle(
                            tooltip: _isExpanded ? 'Свернуть' : 'Развернуть',
                            onTap: () =>
                                setState(() => _isExpanded = !_isExpanded),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: widget.files.isEmpty
                          ? const FriendlyEmptyState(
                              icon: Icons.folder_open_rounded,
                              title: 'Нет загруженных файлов',
                              subtitle:
                                  'Загрузите файлы этого типа, чтобы они появились в списке.',
                              accentColor: Colors.blueGrey,
                              iconSize: 66,
                              padding: EdgeInsets.symmetric(vertical: 18),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.96,
                              ),
                              itemCount: widget.files.length,
                              itemBuilder: (context, index) {
                                return Center(
                                  child: FractionallySizedBox(
                                    widthFactor: 0.93,
                                    heightFactor: 0.93,
                                    child: _FileCard(
                                      file: widget.files[index],
                                      onDelete: () => widget
                                          .onDelete(widget.files[index].id),
                                      projectId: widget.projectId,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderExpandToggle({
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 32,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isExpandToggleHovered = true),
        onExit: (_) => setState(() => _isExpandToggleHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isExpandToggleHovered
                    ? Colors.black.withOpacity(0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isPrimary
                  ? widget.color.withOpacity(0.16)
                  : widget.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPrimary
                    ? widget.color.withOpacity(0.34)
                    : widget.color.withOpacity(0.16),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isPrimary ? widget.color : widget.color.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilesCountPill(int count) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.color.withOpacity(0.34)),
            ),
            child: Icon(
              Icons.layers_outlined,
              size: 12,
              color: widget.color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

