import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../../data/models/project_model.dart';
import 'add_project_screen.dart';
import 'engineering_tab.dart';
import 'estimate_screen.dart';
import 'file_viewer_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/confirmation_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../data/models/project_file_model.dart';

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
            appBar: AppBar(title: const Text('Детали объекта')),
            body: const Center(child: Text('Объект не найден')),
          );
        }
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Детали объекта')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Детали объекта')),
        body: Center(child: Text('Ошибка: $error')),
      ),
    );
  }
}

class _ProjectDetailContent extends ConsumerWidget {
  final ProjectModel project;

  const _ProjectDetailContent({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.address),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Этапы"),
              Tab(text: "Щиты"),
              Tab(text: "Файлы"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Редактировать',
              onPressed: () => _editProject(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Удалить',
              onPressed: () => _deleteProject(context, ref),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _StagesTab(project: project),
            EngineeringTab(project: project),
            _FilesTab(project: project),
          ],
        ),
      ),
    );
  }

  void _editProject(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProjectScreen(project: project),
      ),
    );
  }

  Future<void> _deleteProject(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление проекта'),
        content: const Text('Вы уверены, что хотите удалить этот проект?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(projectListProvider.notifier)
            .deleteProject(project.id.toString());

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Проект удален')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось удалить: $e')),
          );
        }
      }
    }
  }
}

class _StagesTab extends ConsumerWidget {
  final ProjectModel project;

  const _StagesTab({required this.project});

  String _getObjectTypeDisplay(String type) {
    const map = {
      'new_building': 'Новостройка',
      'secondary': 'Вторичка',
      'cottage': 'Коттедж',
      'office': 'Офис',
      'other': 'Другое',
    };
    return map[type] ?? type;
  }

  String _getProjectStatusDisplay(String status) {
    const map = {
      'new': 'Новый',
      'calculating': 'Предпросчет',
      'stage1_done': 'Этап 1 готов',
      'stage2_done': 'Этап 2 готов',
      'stage3_done': 'Этап 3 готов',
      'completed': 'Завершен',
    };
    return map[status] ?? status;
  }

  String _getStageTitleDisplay(String title) {
    const map = {
      'precalc': 'Предпросчет',
      'stage_1': 'Этап 1 (Черновой)',
      'stage_1_2': 'Этап 1+2 (Черновой)',
      'stage_2': 'Этап 2 (Черновой)',
      'stage_3': 'Этап 3 (Чистовой)',
      'extra': 'Доп. работы',
      'other': 'Другое',
    };
    return map[title] ?? title;
  }

  String _getStageStatusDisplay(String status) {
    const map = {
      'plan': 'План',
      'in_progress': 'В процессе',
      'completed': 'Завершен',
    };
    return map[status] ?? status;
  }

  Color _getStageStatusColor(String status) {
    switch (status) {
      case 'plan':
        return Colors.grey;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref,
      String stageId, String currentStatus, Offset globalPosition) async {
    final newStatus = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(value: 'plan', child: Text('План')),
        PopupMenuItem(value: 'in_progress', child: Text('В процессе')),
        PopupMenuItem(value: 'completed', child: Text('Завершен')),
      ],
    );

    if (newStatus != null && newStatus != currentStatus) {
      await ref
          .read(projectListProvider.notifier)
          .updateStageStatus(stageId, newStatus);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                      label: 'Тип:',
                      value: _getObjectTypeDisplay(project.objectType)),
                  _InfoRow(
                      label: 'Статус:',
                      value: _getProjectStatusDisplay(project.status)),
                  if (project.clientInfo.isNotEmpty)
                    _InfoRow(label: 'Клиент:', value: project.clientInfo),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Этапы работ',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (project.stages.isEmpty) const Text('Этапы еще не созданы'),
          ...project.stages.map((stage) {
            final statusColor = _getStageStatusColor(stage.status);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
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
                title: Text(_getStageTitleDisplay(stage.title)),
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: InkWell(
                      onTapDown: (details) => _updateStatus(
                          context,
                          ref,
                          stage.id.toString(),
                          stage.status,
                          details.globalPosition),
                      onTap:
                          () {}, // Для эффекта нажатия, но без действия (действие в onTapDown)
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStageStatusDisplay(stage.status),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
                trailing: stage.isPaid
                    ? const Icon(Icons.monetization_on, color: Colors.green)
                    : const Icon(Icons.money_off, color: Colors.grey),
              ),
            );
          }),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _showAddStageSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Добавить этап'),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  void _showAddStageSheet(BuildContext context, WidgetRef ref) {
    final existingKeys = project.stages.map((s) => s.title).toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => _AddStageSheet(
        projectId: project.id.toString(),
        existingStageKeys: existingKeys,
      ),
    );
  }
}

class _AddStageSheet extends ConsumerStatefulWidget {
  final String projectId;
  final List<String> existingStageKeys;

  const _AddStageSheet({
    required this.projectId,
    required this.existingStageKeys,
  });

  @override
  ConsumerState<_AddStageSheet> createState() => _AddStageSheetState();
}

class _AddStageSheetState extends ConsumerState<_AddStageSheet> {
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
      if (key != 'extra' && key != 'other') {
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите этап',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (stages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Все основные этапы уже добавлены'),
            )
          else
            ...stages.entries.map((entry) => ListTile(
                  title: Text(entry.value),
                  onTap: () => _addStage(entry.key),
                  leading: const Icon(Icons.add_circle_outline),
                )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FilesTab extends ConsumerWidget {
  final ProjectModel project;

  const _FilesTab({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FileCategorySection(
          title: "Проекты и схемы",
          icon: Icons.architecture_rounded,
          color: Colors.brown,
          category: "PROJECT",
          files: project.files.where((f) => f.category == "PROJECT").toList(),
          onDelete: (fileId) => _deleteFile(context, ref, fileId),
          onUpload: () => _pickAndUploadFiles(context, ref, "PROJECT"),
        ),
        const SizedBox(height: 24),
        _FileCategorySection(
          title: "Реализация (Этапы 1-2)",
          icon: Icons.construction_rounded,
          color: Colors.brown,
          category: "WORK",
          files: project.files.where((f) => f.category == "WORK").toList(),
          onDelete: (fileId) => _deleteFile(context, ref, fileId),
          onUpload: () => _pickAndUploadFiles(context, ref, "WORK"),
        ),
        const SizedBox(height: 24),
        _FileCategorySection(
          title: "Финишные фото",
          icon: Icons.auto_awesome_rounded,
          color: Colors.brown,
          category: "FINISH",
          files: project.files.where((f) => f.category == "FINISH").toList(),
          onDelete: (fileId) => _deleteFile(context, ref, fileId),
          onUpload: () => _pickAndUploadFiles(context, ref, "FINISH"),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Future<void> _pickAndUploadFiles(
      BuildContext context, WidgetRef ref, String category) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      final notifier = ref.read(projectListProvider.notifier);

      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Начинаю загрузку ${result.files.length} файлов...')),
      );

      int successCount = 0;
      for (final pickedFile in result.files) {
        if (pickedFile.path != null) {
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

      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('Загружено: $successCount из ${result.files.length}')),
      );
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

class _FileCard extends StatefulWidget {
  final ProjectFileModel file;
  final VoidCallback onDelete;

  const _FileCard({required this.file, required this.onDelete});

  @override
  State<_FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<_FileCard> {
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
                    ? Colors.brown.withOpacity(0.2)
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
                              ? Colors.brown.shade700
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
    } else if (isPdf) {
      _downloadAndOpenFile(url);
    } else {
      _downloadAndOpenFile(url);
    }
  }

  Future<void> _downloadAndOpenFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final documentDirectory = await getTemporaryDirectory();
      final localFile =
          File('${documentDirectory.path}/${url.split('/').last}');
      await localFile.writeAsBytes(response.bodyBytes);
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
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
              color: widget.color.withOpacity(0.8),
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
                      : widget.color.withOpacity(0.05),
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
