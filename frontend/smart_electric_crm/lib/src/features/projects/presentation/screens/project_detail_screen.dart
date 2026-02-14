import 'package:flutter/material.dart';
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
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Назад',
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Детали объекта'),
            ),
            body: const Center(child: Text('Объект не найден')),
          );
        }
      },
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Назад',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Детали объекта'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Назад',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Детали объекта'),
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      _StagesTab(project: widget.project),
      EngineeringTab(project: widget.project),
      _FilesTab(project: widget.project),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'Назад',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.project.address),
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
        .read(projectListProvider.notifier)
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStageDialog(context, ref),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                color: Colors.white,
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Этапы еще не созданы',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
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
    setState(() => _isLoading = true);
    try {
      await ref
          .read(projectListProvider.notifier)
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
    final themeColor = Colors.indigo;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                          color: Colors.white.withOpacity(0.5),
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
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text("Все основные этапы уже созданы")),
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
                        color: Colors.white,
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
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
            padding: const EdgeInsets.all(16),
            children: [
              _FileCategorySection(
                title: "Проекты и схемы",
                icon: Icons.architecture_rounded,
                color: Colors.indigo,
                category: "PROJECT",
                files: project.files
                    .where((f) => f.category == "PROJECT")
                    .toList(),
                onDelete: (fileId) => _deleteFile(context, ref, fileId),
                onUpload: () => _pickAndUploadFiles(context, ref, "PROJECT"),
              ),
              const SizedBox(height: 24),
              _FileCategorySection(
                title: "Реализация (Этапы 1-2)",
                icon: Icons.construction_rounded,
                color: Colors.indigo,
                category: "WORK",
                files:
                    project.files.where((f) => f.category == "WORK").toList(),
                onDelete: (fileId) => _deleteFile(context, ref, fileId),
                onUpload: () => _pickAndUploadFiles(context, ref, "WORK"),
              ),
              const SizedBox(height: 24),
              _FileCategorySection(
                title: "Финишные фото",
                icon: Icons.auto_awesome_rounded,
                color: Colors.indigo,
                category: "FINISH",
                files:
                    project.files.where((f) => f.category == "FINISH").toList(),
                onDelete: (fileId) => _deleteFile(context, ref, fileId),
                onUpload: () => _pickAndUploadFiles(context, ref, "FINISH"),
              ),
              const SizedBox(height: 24),
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

      final notifier = ref.read(projectListProvider.notifier);
      int successCount = 0;
      List<String> sizeErrors = [];

      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Начинаю загрузку ${result.files.length} файлов...')),
      );

      for (final pickedFile in result.files) {
        if (pickedFile.path != null) {
          // 3. Проверка размера файла (Макс 20 МБ)
          final file = File(pickedFile.path!);
          final sizeInBytes = await file.length();
          final sizeInMb = sizeInBytes / (1024 * 1024);

          if (sizeInMb > 20) {
            sizeErrors
                .add('${pickedFile.name} (${sizeInMb.toStringAsFixed(1)} МБ)');
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
            debugPrint("Upload failed: $e");
          }
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
      await ref.read(projectListProvider.notifier).deleteFile(fileId);
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

  const _FileCard({required this.file, required this.onDelete});

  @override
  ConsumerState<_FileCard> createState() => _FileCardState();
}

class _FileCardState extends ConsumerState<_FileCard> {
  bool _isHovered = false;

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

  @override
  Widget build(BuildContext context) {
    final fileUrl = widget.file.file;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTap: () => _openFile(context, fileUrl),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20), // Больший радиус
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.06),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
              border: Border.all(
                color: _isHovered
                    ? Colors.indigo.withOpacity(0.1)
                    : Colors.grey.shade100,
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
                          color: Colors.grey.shade50,
                        ),
                        child: isImage
                            ? Image.network(
                                fileUrl,
                                fit: BoxFit.cover,
                                cacheWidth: 300,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.broken_image_rounded,
                                        size: 40, color: Colors.grey.shade300),
                              )
                            : Center(
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isPdf
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isPdf
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.insert_drive_file_rounded,
                                    color: isPdf
                                        ? Colors.red.withOpacity(0.8)
                                        : Colors.blue.withOpacity(0.8),
                                    size: 28,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 12.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _isHovered
                              ? Colors.indigo.shade700
                              : Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Кнопки управления (появляются при наведении)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          icon: Icons.edit_rounded,
                          tooltip: "Переименовать",
                          onTap: () => _renameFile(context),
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.download_rounded,
                          tooltip: "Сохранить как...",
                          onTap: () => _saveAsFile(context, fileUrl),
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.share_rounded,
                          tooltip: "Поделиться",
                          onTap: () => _shareFile(fileUrl),
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.close_rounded, // Cross icon
                          tooltip: "Удалить",
                          onTap: widget.onDelete,
                          isDestructive: true,
                        ),
                      ],
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
                .read(projectListProvider.notifier)
                .renameFile(widget.file.id, newName);
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
      final tempFile = File('${tempDir.path}/${displayName}');
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.9),
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDestructive ? Colors.red : Colors.black87,
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

  const _FileCategorySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.category,
    required this.files,
    required this.onDelete,
    required this.onUpload,
  });

  @override
  State<_FileCategorySection> createState() => _FileCategorySectionState();
}

class _FileCategorySectionState extends State<_FileCategorySection> {
  bool _isExpanded = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    // Автоматически раскрываем спойлер, если файлов 5 и менее
    if (widget.files.length <= 5) {
      _isExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.color.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Accent vertical line (Full height)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(
              color: widget.color,
            ),
          ),

          // 2. Main content Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section (Stable & Full Hover)
              MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: Material(
                  color: _isHovered
                      ? widget.color.withOpacity(0.12) // Темнее при наведении
                      : widget.color.withOpacity(0.08),
                  child: Row(
                    children: [
                      // Left interaction area: Expand/Collapse
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              setState(() => _isExpanded = !_isExpanded),
                          hoverColor: Colors.transparent, // Disable local hover
                          splashColor:
                              Colors.transparent, // Disable local splash
                          highlightColor:
                              Colors.transparent, // Disable local highlight
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(19, 16, 14, 16),
                            child: Row(
                              children: [
                                Icon(widget.icon,
                                    color: widget.color, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  widget.title.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: widget.color.withOpacity(0.85),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const Spacer(),
                                // File count badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: widget.color
                                        .withOpacity(_isExpanded ? 0.15 : 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${widget.files.length} ФАЙЛОВ",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: widget.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Right interaction area: Action buttons
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Row(
                          children: [
                            // Add files button (Safe separate InkWell)
                            Tooltip(
                              message: "Загрузить файлы",
                              child: InkWell(
                                onTap: widget.onUpload,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: widget.color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.add_rounded,
                                      size: 22, color: widget.color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Specific Expand Indicator button
                            InkWell(
                              onTap: () =>
                                  setState(() => _isExpanded = !_isExpanded),
                              borderRadius: BorderRadius.circular(20),
                              child: Icon(
                                _isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 26,
                                color: widget.color.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Files Grid (Spoiler support)
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: widget.files.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Text(
                              'Нет загруженных файлов',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: widget.files.length,
                          itemBuilder: (context, index) {
                            return _FileCard(
                              file: widget.files[index],
                              onDelete: () =>
                                  widget.onDelete(widget.files[index].id),
                            );
                          },
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
