import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../../data/models/project_model.dart';
import 'engineering_tab.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/confirmation_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/text_input_dialog.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/compact_section_app_bar.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/content_tab_strip.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_popup_select_field.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/constants/api_urls.dart';
import 'package:smart_electric_crm/src/core/utils/app_number_formatter.dart';
import 'dart:io';
import '../../data/models/project_file_model.dart';
import '../../../../shared/services/temp_file_service.dart';
import '../widgets/stages/stage_card.dart';
import 'add_project_screen.dart';
import '../widgets/project_detail/add_stage_dialog.dart';
import '../widgets/project_detail/detail_info_row.dart';
import '../dialogs/project_file_share_fallback_dialog.dart';
import '../../services/project_file_browser_bridge.dart';
import '../../services/project_file_save_service.dart';
import '../../services/project_file_share_service.dart';

import '../../data/models/stage_model.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  final ProjectDetailSection initialTab;
  final ValueChanged<ProjectDetailSection>? onTabChanged;
  final VoidCallback? onBackPressed;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.initialTab = ProjectDetailSection.stages,
    this.onTabChanged,
    this.onBackPressed,
  });

  void _handleBack(BuildContext context) {
    onBackPressed?.call();
    if (onBackPressed != null) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));

    return projectAsync.when(
      data: (project) => _ProjectDetailContent(
        project: project,
        initialTab: initialTab,
        onTabChanged: onTabChanged,
        onBackPressed: onBackPressed,
      ),
      loading: () => Scaffold(
        appBar: CompactSectionAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: 'Назад',
            onPressed: () => _handleBack(context),
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
            onPressed: () => _handleBack(context),
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
  final ProjectDetailSection initialTab;
  final ValueChanged<ProjectDetailSection>? onTabChanged;
  final VoidCallback? onBackPressed;

  const _ProjectDetailContent({
    required this.project,
    required this.initialTab,
    this.onTabChanged,
    this.onBackPressed,
  });

  @override
  ConsumerState<_ProjectDetailContent> createState() =>
      _ProjectDetailContentState();
}

class _ProjectDetailContentState extends ConsumerState<_ProjectDetailContent> {
  int _currentIndex = 0;
  final ScrollController _stagesScrollController = ScrollController();
  final ScrollController _shieldsScrollController = ScrollController();
  final ScrollController _filesScrollController = ScrollController();
  final SectionAppBarCollapseController _appBarCollapseController =
      SectionAppBarCollapseController();

  int _tabIndexFromSection(ProjectDetailSection section) {
    return switch (section) {
      ProjectDetailSection.stages => 0,
      ProjectDetailSection.shields => 1,
      ProjectDetailSection.files => 2,
    };
  }

  ProjectDetailSection _sectionFromTabIndex(int index) {
    return switch (index) {
      1 => ProjectDetailSection.shields,
      2 => ProjectDetailSection.files,
      _ => ProjectDetailSection.stages,
    };
  }

  void _handleBack() {
    widget.onBackPressed?.call();
    if (widget.onBackPressed != null) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  ScrollController get _activeScrollController {
    switch (_currentIndex) {
      case 0:
        return _stagesScrollController;
      case 1:
        return _shieldsScrollController;
      case 2:
        return _filesScrollController;
      default:
        return _stagesScrollController;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _tabIndexFromSection(widget.initialTab);
    _appBarCollapseController.bind(_activeScrollController);
  }

  @override
  void didUpdateWidget(covariant _ProjectDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _tabIndexFromSection(widget.initialTab);
    if (nextIndex != _currentIndex) {
      _currentIndex = nextIndex;
      _appBarCollapseController.bind(_activeScrollController);
    }
  }

  Future<void> _scrollCurrentTabToTop() {
    switch (_currentIndex) {
      case 0:
        return AppNavigation.stagesScrollController.scrollToTop();
      case 1:
        return AppNavigation.shieldsScrollController.scrollToTop();
      case 2:
        return AppNavigation.filesScrollController.scrollToTop();
      default:
        return Future.value();
    }
  }

  void _handleSectionSelection(int index) {
    if (index == _currentIndex) {
      _scrollCurrentTabToTop();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    widget.onTabChanged?.call(_sectionFromTabIndex(index));
    _appBarCollapseController.bind(_activeScrollController);
  }

  @override
  void dispose() {
    _appBarCollapseController.dispose();
    _stagesScrollController.dispose();
    _shieldsScrollController.dispose();
    _filesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobileWeb = DesktopWebFrame.isMobileWeb(context, maxWidth: 700);
    final shellSidebarInset = DesktopWebFrame.persistentShellContentInset(
      context,
    );
    final localNavOverlayInset = ContentTabStrip.overlayInset(context);
    final screens = [
      _StagesTab(
        project: widget.project,
        scrollController: _stagesScrollController,
        topContentInset: localNavOverlayInset,
      ),
      EngineeringTab(
        project: widget.project,
        scrollController: _shieldsScrollController,
        topContentInset: localNavOverlayInset,
      ),
      _FilesTab(
        project: widget.project,
        scrollController: _filesScrollController,
        topContentInset: localNavOverlayInset,
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
              icon: const Icon(Icons.arrow_back_ios_new),
              tooltip: 'Назад',
              onPressed: _handleBack,
            ),
            title: '\u041e\u0431\u044a\u0435\u043a\u0442',
            subtitle: widget.project.address,
            icon: Icons.apartment_rounded,
            bottomGap: isMobileWeb ? 16 : 30,
          ),
          body: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(left: shellSidebarInset),
            child: Stack(
              children: [
                Positioned.fill(child: child!),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ContentTabStrip(
                    key: const ValueKey('project_local_nav'),
                    selectedIndex: _currentIndex,
                    onSelected: _handleSectionSelection,
                    items: const [
                      ContentTabStripItem(
                        label: '\u042d\u0442\u0430\u043f\u044b',
                        icon: Icons.layers_rounded,
                        keyName: 'project_local_nav_stages',
                      ),
                      ContentTabStripItem(
                        label: '\u0429\u0438\u0442\u044b',
                        icon: Icons.settings_input_component_rounded,
                        keyName: 'project_local_nav_shields',
                      ),
                      ContentTabStripItem(
                        label: '\u0424\u0430\u0439\u043b\u044b',
                        icon: Icons.folder_open_rounded,
                        keyName: 'project_local_nav_files',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}

class _StagesTab extends ConsumerStatefulWidget {
  final ProjectModel project;
  final ScrollController scrollController;
  final double topContentInset;

  const _StagesTab({
    required this.project,
    required this.scrollController,
    required this.topContentInset,
  });

  @override
  ConsumerState<_StagesTab> createState() => _StagesTabState();
}

class _StagesTabState extends ConsumerState<_StagesTab> {
  Object? _scrollAttachment;

  @override
  void initState() {
    super.initState();
    _scrollAttachment =
        AppNavigation.stagesScrollController.attach(_scrollToTop);
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.stagesScrollController.detach(scrollAttachment);
    }
    super.dispose();
  }

  Future<void> _scrollToTop({bool animated = true}) async {
    if (!widget.scrollController.hasClients) {
      return;
    }
    if (animated) {
      await widget.scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.scrollController.jumpTo(0);
  }

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
  Widget build(BuildContext context) {
    final isDesktopWeb = DesktopWebFrame.isDesktop(context, minWidth: 1180);
    final isMobileWeb = DesktopWebFrame.isMobileWeb(context, maxWidth: 700);

    return Scaffold(
      floatingActionButton: Tooltip(
        message: 'Добавить этап',
        preferBelow: false,
        verticalOffset: 32,
        child: isMobileWeb
            ? FloatingActionButton.small(
                onPressed: () => _showAddStageDialog(context, ref),
                backgroundColor: Colors.indigo,
                foregroundColor: Theme.of(context).colorScheme.surface,
                child: const Icon(Icons.add),
              )
            : FloatingActionButton(
                onPressed: () => _showAddStageDialog(context, ref),
                backgroundColor: Colors.indigo,
                foregroundColor: Theme.of(context).colorScheme.surface,
                child: const Icon(Icons.add),
              ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const contentMaxWidth = 1380.0;
          final horizontalPadding = DesktopWebFrame.centeredContentSidePadding(
            constraints.maxWidth,
            maxWidth: contentMaxWidth,
            minPadding: 12,
          );
          final content = SingleChildScrollView(
            controller: widget.scrollController,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              widget.topContentInset + (isMobileWeb ? 12 : 20),
              horizontalPadding,
              isMobileWeb ? 12 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProjectOverviewCard(isMobileWeb: isMobileWeb),
                SizedBox(height: isMobileWeb ? 20 : 28),

                if (widget.project.stages.isEmpty)
                  const FriendlyEmptyState(
                    icon: Icons.layers_clear_rounded,
                    title: 'Этапы еще не созданы',
                    subtitle:
                        'Добавьте первый этап, чтобы продолжить работу по объекту.',
                    accentColor: Colors.indigo,
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),

                if (isDesktopWeb && widget.project.stages.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth >= 1100 ? 2 : 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 152,
                        ),
                        itemCount: widget.project.stages.length,
                        itemBuilder: (context, index) {
                          final stage = widget.project.stages[index];
                          return StageCard(
                            stage: stage,
                            onTap: () {
                              AppNavigation.openEstimate(
                                context,
                                projectId: widget.project.id.toString(),
                                stageId: stage.id.toString(),
                              );
                            },
                            onStatusChanged: (newStatus) => _updateStatus(
                              context,
                              ref,
                              stage.id.toString(),
                              newStatus,
                            ),
                            onDelete: () => _deleteStage(context, ref, stage),
                          );
                        },
                      );
                    },
                  )
                else
                  ...widget.project.stages.map((stage) {
                    return StageCard(
                      stage: stage,
                      onTap: () {
                        AppNavigation.openEstimate(
                          context,
                          projectId: widget.project.id.toString(),
                          stageId: stage.id.toString(),
                        );
                      },
                      onStatusChanged: (newStatus) => _updateStatus(
                          context, ref, stage.id.toString(), newStatus),
                      onDelete: () => _deleteStage(context, ref, stage),
                    );
                  }),

                SizedBox(height: isMobileWeb ? 64 : 80), // Space for FAB
              ],
            ),
          );

          if (!isDesktopWeb) {
            return content;
          }

          return SizedBox(
            width: constraints.maxWidth,
            child: content,
          );
        },
      ),
    );
  }

  // Helpers (Duplicated for now, should be moved to Utils or mixin)

  void _showAddStageDialog(BuildContext context, WidgetRef ref) {
    final existingKeys = widget.project.stages.map((s) => s.title).toList();

    showDialog(
      context: context,
      builder: (context) => AddStageDialog(
        projectId: widget.project.id.toString(),
        existingStageKeys: existingKeys,
      ),
    );
  }

  Widget _buildProjectOverviewCard({
    required bool isMobileWeb,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final isDark = AppDesignTokens.isDark(context);
    final headerBackground = isDark
        ? scheme.surfaceContainerHigh.withOpacity(0.72)
        : scheme.surfaceContainer.withOpacity(0.6);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppDesignTokens.cardShadow(context),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppDesignTokens.softBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              18,
              isMobileWeb ? 14 : 16,
              14,
              isMobileWeb ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: headerBackground,
              border: Border(
                bottom: BorderSide(color: AppDesignTokens.softBorder(context)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(isDark ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    size: 18,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Об объекте',
                        style: textStyles.captionStrong.copyWith(
                          color: scheme.onSurfaceVariant.withOpacity(0.72),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.project.address.isNotEmpty
                            ? widget.project.address
                            : 'Без адреса',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.cardTitle.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Редактировать объект',
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              AddProjectDialog(project: widget.project),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              isMobileWeb ? 14 : 18,
              18,
              isMobileWeb ? 16 : 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailInfoRow(
                  icon: Icons.person_outline,
                  label: 'ЗАКАЗЧИК',
                  value: widget.project.clientInfo.isNotEmpty
                      ? widget.project.clientInfo
                      : '—',
                  color: Colors.blue.shade600,
                  selectable: true,
                ),
                SizedBox(height: isMobileWeb ? 12 : 16),
                DetailInfoRow(
                  icon: Icons.info_outline,
                  label: 'ИСТОЧНИК',
                  value: widget.project.source.isNotEmpty
                      ? widget.project.source
                      : '—',
                  color: Colors.teal.shade700,
                  selectable: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilesTab extends ConsumerStatefulWidget {
  final ProjectModel project;
  final ScrollController scrollController;
  final double topContentInset;

  const _FilesTab({
    required this.project,
    required this.scrollController,
    required this.topContentInset,
  });

  @override
  ConsumerState<_FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends ConsumerState<_FilesTab> {
  Object? _scrollAttachment;
  bool _isLimitInfoOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollAttachment =
        AppNavigation.filesScrollController.attach(_scrollToTop);
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.filesScrollController.detach(scrollAttachment);
    }
    super.dispose();
  }

  Future<void> _scrollToTop({bool animated = true}) async {
    if (!widget.scrollController.hasClients) {
      return;
    }
    if (animated) {
      await widget.scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final isMobileWeb = DesktopWebFrame.isMobileWeb(context, maxWidth: 700);
    final content = Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  DesktopWebFrame.centeredContentSidePadding(
                constraints.maxWidth,
                maxWidth: 1380,
                minPadding: 12,
              );

              return ListView(
                controller: widget.scrollController,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  widget.topContentInset + (isMobileWeb ? 12 : 20),
                  horizontalPadding,
                  isMobileWeb ? 12 : 16,
                ),
                children: [
                  _FileCategorySection(
                    title: "Проекты и схемы",
                    icon: Icons.architecture_rounded,
                    color: Colors.blueGrey,
                    category: "PROJECT",
                    files: widget.project.files
                        .where((f) => f.category == "PROJECT")
                        .toList(),
                    onDelete: (fileId) => _deleteFile(context, ref, fileId),
                    onUpload: () =>
                        _pickAndUploadFiles(context, ref, "PROJECT"),
                    projectId: widget.project.id.toString(),
                  ),
                  _FileCategorySection(
                    title: "Реализация",
                    icon: Icons.construction_rounded,
                    color: Colors.blue,
                    category: "WORK",
                    files: widget.project.files
                        .where((f) => f.category == "WORK")
                        .toList(),
                    onDelete: (fileId) => _deleteFile(context, ref, fileId),
                    onUpload: () => _pickAndUploadFiles(context, ref, "WORK"),
                    projectId: widget.project.id.toString(),
                  ),
                  _FileCategorySection(
                    title: "Финишные фото",
                    icon: Icons.auto_awesome_rounded,
                    color: Colors.green,
                    category: "FINISH",
                    files: widget.project.files
                        .where((f) => f.category == "FINISH")
                        .toList(),
                    onDelete: (fileId) => _deleteFile(context, ref, fileId),
                    onUpload: () => _pickAndUploadFiles(context, ref, "FINISH"),
                    projectId: widget.project.id.toString(),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ],
    );
    return Stack(
      children: [
        content,
        if (_isLimitInfoOpen)
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('files_limit_info_dismiss_area'),
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _isLimitInfoOpen = false),
              child: const SizedBox.expand(),
            ),
          ),
        Positioned(
          right: 16,
          bottom: isMobileWeb ? 12 : 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isLimitInfoOpen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: _FilesLimitInfoBlock(
                      filesCount: widget.project.files.length,
                    ),
                  ),
                ),
              _FilesLimitInfoButton(
                isOpen: _isLimitInfoOpen,
                onTap: () =>
                    setState(() => _isLimitInfoOpen = !_isLimitInfoOpen),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadFiles(
      BuildContext context, WidgetRef ref, String category) async {
    // 1. Проверка лимита количества файлов (Макс 12 на проект)
    if (widget.project.files.length >= 12) {
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
      withData: kIsWeb,
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
      if (widget.project.files.length + result.files.length > 12) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => ConfirmationDialog(
              title: 'Слишком много файлов',
              content:
                  'Вы выбрали ${result.files.length} файлов для загрузки. В текущий проект можно загрузить еще не более ${12 - widget.project.files.length} файлов.',
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
        final uploadPath = kIsWeb ? null : pickedFile.path?.trim();
        final uploadBytes = pickedFile.bytes;
        final sizeInBytes =
            pickedFile.size > 0 ? pickedFile.size : uploadBytes?.length ?? 0;
        if ((uploadPath == null || uploadPath.isEmpty) &&
            (uploadBytes == null || uploadBytes.isEmpty)) {
          uploadErrors
              .add('${pickedFile.name}: не удалось получить данные файла');
          continue;
        }
        // 3. Проверка размера файла (Макс 20 МБ)
        final sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 20) {
          sizeErrors.add(
            '${pickedFile.name} (${AppNumberFormatter.decimal(sizeInMb, maxFractionDigits: 1, minFractionDigits: 1)} МБ)',
          );
          continue;
        }

        try {
          await notifier.uploadFile(
            projectId: widget.project.id,
            filePath: uploadPath,
            fileBytes: uploadBytes,
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
            widget.project.id.toString(),
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
  static const double _fileActionMenuWidth = 220;

  bool _isHovered = false;
  final GlobalKey _actionMenuAnchorKey = GlobalKey();
  final ProjectFileSaveService _fileSaveService = ProjectFileSaveService();
  final ProjectFileShareService _fileShareService = ProjectFileShareService();

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

  bool get usesCopyLinkShareAction =>
      kIsWeb && _fileShareService.usesCopyLinkAsPrimaryAction;

  IconData get shareActionIcon =>
      kIsWeb ? Icons.link_rounded : Icons.share_rounded;

  String get shareActionTooltip =>
      usesCopyLinkShareAction ? 'Скопировать ссылку' : 'Поделиться';

  String _fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        return Uri.decodeComponent(uri.pathSegments.last);
      }
    } catch (_) {
      // Keep fallback below.
    }
    return url.split('/').last;
  }

  Future<File> _createDownloadedTempFile(String url,
      {String? preferredName}) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Не удалось загрузить файл.', uri: uri);
    }
    final tempDir = await getTemporaryDirectory();
    final fallbackName = _fileNameFromUrl(url);
    final safeName = ProjectFileSaveService.sanitizeFileName(
      preferredName ?? fallbackName,
      fallback: ProjectFileSaveService.sanitizeFileName(
        fallbackName,
        fallback: 'file',
      ),
    );
    final localFile = File('${tempDir.path}/$safeName');
    await localFile.writeAsBytes(response.bodyBytes);
    TempFileService().track(localFile);
    return localFile;
  }

  @override
  Widget build(BuildContext context) {
    final fileUrl = ApiUrls.resolveBackendUrl(widget.file.file);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyles = context.appTextStyles;
    final blocksLongPress = switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
    final previewBackground = Color.alphaBlend(
      fileAccentColor.withOpacity(0.032),
      AppDesignTokens.surface2(context),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(context, hovered: _isHovered),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context, hovered: _isHovered),
              blurRadius: _isHovered ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: AppDesignTokens.cardBorder(context, hovered: _isHovered),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onLongPress: blocksLongPress ? () {} : null,
          onTap: () => _openFile(context, fileUrl),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: previewBackground,
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
                                  color: fileAccentColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: fileAccentColor.withOpacity(0.14),
                                  ),
                                ),
                                child: Icon(
                                  isPdf
                                      ? Icons.description_rounded
                                      : Icons.insert_drive_file_rounded,
                                  color: fileAccentColor.withOpacity(0.78),
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
                            style: textStyles.captionStrong.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? scheme.onSurface
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: fileAccentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: fileAccentColor.withOpacity(0.12),
                            ),
                          ),
                          child: Text(
                            extensionLabel,
                            style: textStyles.captionStrong.copyWith(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: fileAccentColor.withOpacity(0.78),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 6,
                right: 6,
                child: _buildActionEntryButton(
                  context,
                  fileUrl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionEntryButton(
    BuildContext context,
    String fileUrl,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final menuHoverColor = AppDesignTokens.isDark(context)
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.045);
    return Theme(
      data: theme.copyWith(
        hoverColor: menuHoverColor,
        highlightColor: menuHoverColor,
        splashColor: menuHoverColor,
        popupMenuTheme: theme.popupMenuTheme.copyWith(
          color: scheme.surface,
          surfaceTintColor: Colors.transparent,
          mouseCursor: const WidgetStatePropertyAll<MouseCursor>(
            SystemMouseCursors.click,
          ),
        ),
      ),
      child: Builder(
        builder: (menuContext) {
          return SizedBox(
            key: _actionMenuAnchorKey,
            child: KeyedSubtree(
              key: ValueKey('file_action_entry_${widget.file.id}'),
              child: _FileActionEntryButton(
                onTap: () => _showActionMenu(menuContext, fileUrl),
              ),
            ),
          );
        },
      ),
    );
  }

  List<PopupMenuEntry<_FileCardAction>> _buildFileActionMenuItems(
      BuildContext context) {
    return buildPopupMenuEntriesWithDividers<_FileCardAction>([
      const PopupMenuItem<_FileCardAction>(
        value: _FileCardAction.rename,
        child: _FileActionMenuLabel(
          icon: Icons.edit_rounded,
          title: 'Переименовать',
        ),
      ),
      const PopupMenuItem<_FileCardAction>(
        value: _FileCardAction.saveAs,
        child: _FileActionMenuLabel(
          icon: Icons.download_rounded,
          title: 'Сохранить как...',
        ),
      ),
      PopupMenuItem<_FileCardAction>(
        value: _FileCardAction.share,
        child: _FileActionMenuLabel(
          icon: shareActionIcon,
          title: shareActionTooltip,
        ),
      ),
      const PopupMenuItem<_FileCardAction>(
        value: _FileCardAction.delete,
        child: _FileActionMenuLabel(
          icon: Icons.close_rounded,
          title: 'Удалить',
          isDestructive: true,
        ),
      ),
    ]);
  }

  Future<void> _showActionMenu(BuildContext context, String fileUrl) async {
    final anchorContext = _actionMenuAnchorKey.currentContext;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final anchor = anchorContext?.findRenderObject() as RenderBox?;
    if (overlay == null || anchor == null) {
      return;
    }

    final buttonOffset = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonRect = buttonOffset & anchor.size;
    const verticalGap = 6.0;
    const horizontalInset = 8.0;
    final left = (buttonRect.right - _fileActionMenuWidth).clamp(
        horizontalInset,
        overlay.size.width - _fileActionMenuWidth - horizontalInset);
    final top = (buttonRect.bottom + verticalGap)
        .clamp(horizontalInset, overlay.size.height - horizontalInset);
    final position = RelativeRect.fromLTRB(
      left,
      top,
      overlay.size.width - left - _fileActionMenuWidth,
      overlay.size.height - top,
    );

    final action = await showMenu<_FileCardAction>(
      context: context,
      position: position,
      items: _buildFileActionMenuItems(context),
      menuPadding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      elevation: 6,
      shadowColor: AppDesignTokens.cardShadow(context),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppDesignTokens.softBorder(context)),
      ),
      constraints: const BoxConstraints.tightFor(width: _fileActionMenuWidth),
    );

    if (action == null || !context.mounted) {
      return;
    }
    await _handleFileAction(context, action, fileUrl);
  }

  Future<void> _handleFileAction(
    BuildContext context,
    _FileCardAction action,
    String fileUrl,
  ) async {
    switch (action) {
      case _FileCardAction.rename:
        await _renameFile(context);
        return;
      case _FileCardAction.saveAs:
        await _saveAsFile(context, fileUrl);
        return;
      case _FileCardAction.share:
        await _shareFile(context, fileUrl);
        return;
      case _FileCardAction.delete:
        widget.onDelete();
        return;
    }
  }

  void _openFile(BuildContext context, String url) {
    if (isImage) {
      AppNavigation.openFileViewer(
        context,
        url: url,
        title: displayName,
      );
      return;
    }

    if (kIsWeb) {
      openUrlInBrowser(url);
      return;
    }

    _downloadAndOpenFile(url);
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
    final result = await _fileSaveService.saveRemoteFile(
      url: url,
      displayName: displayName,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _downloadAndOpenFile(String url) async {
    try {
      final localFile =
          await _createDownloadedTempFile(url, preferredName: displayName);
      await OpenFilex.open(localFile.path);
    } catch (e) {
      debugPrint("Open file error: $e");
    }
  }

  Future<void> _shareFile(BuildContext context, String url) async {
    if (kIsWeb) {
      final result = await _fileShareService.shareRemoteFile(
        url: url,
        displayName: displayName,
      );
      if (!context.mounted || result.isShared || result.isCancelled) {
        return;
      }
      if (result.requiresManualFallback && result.url != null) {
        await showProjectFileShareFallbackDialog(
          context: context,
          url: result.url!,
          displayName: displayName,
          saveService: _fileSaveService,
          shareService: _fileShareService,
          message: result.message,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    try {
      final localFile =
          await _createDownloadedTempFile(url, preferredName: displayName);
      await Share.shareXFiles([XFile(localFile.path)]);
    } catch (e) {
      debugPrint("Share file error: $e");
    }
  }
}

enum _FileCardAction {
  rename,
  saveAs,
  share,
  delete,
}

class _FileActionEntryButton extends StatefulWidget {
  const _FileActionEntryButton({
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  State<_FileActionEntryButton> createState() => _FileActionEntryButtonState();
}

class _FileActionEntryButtonState extends State<_FileActionEntryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);

    return Tooltip(
      message: 'Действия с файлом',
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isHovered
                    ? scheme.surface.withOpacity(isDark ? 0.88 : 0.92)
                    : scheme.surface.withOpacity(isDark ? 0.72 : 0.82),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isHovered
                      ? Colors.black.withOpacity(0.12)
                      : Colors.black.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                    blurRadius: _isHovered ? 6 : 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: 17,
                color: scheme.onSurface.withOpacity(_isHovered ? 0.76 : 0.62),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FileActionMenuLabel extends StatelessWidget {
  const _FileActionMenuLabel({
    required this.icon,
    required this.title,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.onSurface;

    return Row(
      children: [
        Icon(icon,
            size: 18, color: color.withOpacity(isDestructive ? 1 : 0.78)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: context.appTextStyles.body.copyWith(
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilesLimitInfoButton extends StatefulWidget {
  const _FilesLimitInfoButton({
    required this.isOpen,
    required this.onTap,
  });

  final bool isOpen;
  final VoidCallback onTap;

  @override
  State<_FilesLimitInfoButton> createState() => _FilesLimitInfoButtonState();
}

class _FilesLimitInfoButtonState extends State<_FilesLimitInfoButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final borderColor = widget.isOpen
        ? scheme.primary.withOpacity(isDark ? 0.30 : 0.22)
        : AppDesignTokens.softBorder(context);

    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          key: const ValueKey('files_limit_info_button'),
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: widget.isOpen
                  ? scheme.primary.withOpacity(isDark ? 0.16 : 0.10)
                  : (_isHovered
                      ? AppDesignTokens.surface3(context)
                      : AppDesignTokens.surface2(context)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: AppDesignTokens.cardShadow(context),
                  blurRadius: _isHovered || widget.isOpen ? 8 : 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'i',
                style: context.appTextStyles.bodyStrong.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.isOpen
                      ? scheme.primary.withOpacity(isDark ? 0.92 : 0.82)
                      : scheme.onSurfaceVariant.withOpacity(0.82),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilesLimitInfoBlock extends StatelessWidget {
  const _FilesLimitInfoBlock({
    required this.filesCount,
  });

  final int filesCount;

  static const int _maxFiles = 12;
  static const int _nearLimitThreshold = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyles = context.appTextStyles;
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = DesktopWebFrame.isMobileWeb(context, maxWidth: 700);
    final isNearLimit = filesCount >= _nearLimitThreshold;
    final surface = AppDesignTokens.surface1(context);
    final backgroundColor = isNearLimit
        ? Color.alphaBlend(
            scheme.primary.withOpacity(isDark ? 0.10 : 0.06),
            surface,
          )
        : Color.alphaBlend(
            Colors.black.withOpacity(isDark ? 0.03 : 0.02),
            surface,
          );
    final borderColor = isNearLimit
        ? scheme.primary.withOpacity(isDark ? 0.24 : 0.18)
        : AppDesignTokens.softBorder(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isCompact ? 280 : 340),
      child: Container(
        key: const ValueKey('files_limit_info_block'),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 14,
          vertical: isCompact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'До 12 файлов на проект',
              style: textStyles.captionStrong.copyWith(
                color: scheme.onSurface.withOpacity(isDark ? 0.88 : 0.78),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Сейчас ${AppNumberFormatter.integer(filesCount)} из $_maxFiles, до 20 МБ на файл',
              style: textStyles.caption.copyWith(
                color:
                    scheme.onSurfaceVariant.withOpacity(isDark ? 0.88 : 0.92),
              ),
            ),
          ],
        ),
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

  String _filesCountLabel(int count) {
    final absoluteCount = count.abs() % 100;
    final tail = absoluteCount % 10;

    if (absoluteCount >= 11 && absoluteCount <= 19) {
      return 'файлов';
    }
    if (tail == 1) {
      return 'файл';
    }
    if (tail >= 2 && tail <= 4) {
      return 'файла';
    }
    return 'файлов';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyles = context.appTextStyles;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isNarrowHeader = viewportWidth < 460 ||
        DesktopWebFrame.isMobileWeb(context, maxWidth: 500);
    final useCompactCountPill = viewportWidth < 360 ||
        DesktopWebFrame.isMobileWeb(context, maxWidth: 390);
    return MouseRegion(
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
                    mouseCursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        19,
                        isNarrowHeader ? 12 : 14,
                        14,
                        isNarrowHeader ? 12 : 14,
                      ),
                      child: Row(
                        crossAxisAlignment: isNarrowHeader
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isNarrowHeader ? 7 : 8),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: isNarrowHeader ? 17 : 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: isNarrowHeader
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  key: ValueKey(
                                      'file_group_title_${widget.category}'),
                                  maxLines: isNarrowHeader ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textStyles.cardTitle.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? scheme.onSurface
                                        : Colors.grey.shade900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (!isNarrowHeader) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _isExpanded
                                        ? 'Нажмите, чтобы свернуть'
                                        : 'Нажмите, чтобы развернуть',
                                    style: textStyles.caption.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? scheme.onSurfaceVariant
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFilesCountPill(
                            widget.files.length,
                            compact: useCompactCountPill,
                          ),
                          const SizedBox(width: 8),
                          _buildHeaderActionButton(
                            key: ValueKey(
                                'file_group_upload_${widget.category}'),
                            icon: Icons.add_rounded,
                            tooltip: 'Загрузить файлы',
                            onTap: widget.onUpload,
                            isPrimary: true,
                            compact: isNarrowHeader,
                          ),
                          const SizedBox(width: 6),
                          _buildHeaderExpandToggle(
                            compact: isNarrowHeader,
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
                      padding: EdgeInsets.fromLTRB(
                        12,
                        0,
                        12,
                        isNarrowHeader ? 12 : 16,
                      ),
                      child: widget.files.isEmpty
                          ? FriendlyEmptyState(
                              icon: Icons.folder_open_rounded,
                              title: 'Нет загруженных файлов',
                              subtitle:
                                  'Загрузите файлы этого типа, чтобы они появились в списке.',
                              accentColor: widget.color,
                              iconSize: 66,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = 12.0;
                                const minTileWidth = 140.0;
                                final rawCount =
                                    ((constraints.maxWidth + spacing) /
                                            (minTileWidth + spacing))
                                        .floor();
                                final crossAxisCount = rawCount.clamp(1, 6);

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
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
    bool compact = false,
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
            mouseCursor: SystemMouseCursors.basic,
            borderRadius: BorderRadius.circular(6),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: compact ? 22 : 24,
              height: compact ? 22 : 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isExpandToggleHovered
                    ? Colors.black.withOpacity(0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: compact ? 18 : 20,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton({
    Key? key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool compact = false,
  }) {
    final size = compact ? 32.0 : 34.0;

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            key: key,
            width: size,
            height: size,
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
              size: compact ? 18 : 20,
              color: isPrimary ? widget.color : widget.color.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilesCountPill(
    int count, {
    bool compact = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final iconColor = widget.color.withOpacity(0.88);
    final countLabel =
        '${AppNumberFormatter.integer(count)} ${_filesCountLabel(count)}';

    return Container(
      key: ValueKey('file_group_count_${widget.category}'),
      height: 34,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: AppDesignTokens.surface2(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppDesignTokens.softBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_copy_outlined,
            size: compact ? 14 : 15,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          if (compact)
            Text(
              AppNumberFormatter.integer(count),
              style: textStyles.captionStrong.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withOpacity(0.78),
              ),
            )
          else
            Text(
              countLabel,
              style: textStyles.captionStrong.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withOpacity(0.78),
              ),
            ),
        ],
      ),
    );
  }
}
