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
import '../../../settings/application/app_settings_controller.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'dart:io';
import '../../data/models/project_file_model.dart';
import '../../../../shared/services/temp_file_service.dart';
import '../widgets/stages/stage_card.dart';
import '../widgets/project_detail/add_stage_dialog.dart';
import '../widgets/project_detail/detail_info_row.dart';

import '../../data/models/stage_model.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));

    return projectAsync.when(
      data: (project) => _ProjectDetailContent(project: project),
      loading: () => Scaffold(
        appBar: CompactSectionAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: 'РќР°Р·Р°Рґ',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: 'РћР±СЉРµРєС‚',
          subtitle: 'Р—Р°РіСЂСѓР·РєР°',
          icon: Icons.apartment_rounded,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: CompactSectionAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: 'РќР°Р·Р°Рґ',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: 'РћР±СЉРµРєС‚',
          subtitle: 'РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё',
          icon: Icons.apartment_rounded,
        ),
        body: Center(child: Text('РћС€РёР±РєР°: $error')),
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
  static const List<String> _tabTitles = [
    'Р­С‚Р°РїС‹',
    'Р©РёС‚С‹',
    'Р¤Р°Р№Р»С‹'
  ];
  static const List<IconData> _tabIcons = [
    Icons.layers_rounded,
    Icons.settings_input_component_rounded,
    Icons.folder_open_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final showWelcome = ref.watch(
      appSettingsProvider.select((value) => value.showWelcome),
    );
    final screens = [
      _StagesTab(project: widget.project),
      EngineeringTab(project: widget.project),
      _FilesTab(project: widget.project),
    ];

    return Scaffold(
      appBar: CompactSectionAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'РќР°Р·Р°Рґ',
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
        selectedIndex: showWelcome ? _currentIndex + 1 : _currentIndex,
        onDestinationSelected: (index) {
          if (showWelcome && index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => const HomeScreen(),
              ),
              (route) => false,
            );
            return;
          }
          setState(() {
            _currentIndex = showWelcome ? index - 1 : index;
          });
        },
        destinations: [
          if (showWelcome)
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '\u0413\u043b\u0430\u0432\u043d\u0430\u044f',
            ),
          const NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers),
            label: '\u042d\u0442\u0430\u043f\u044b',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_input_component_outlined),
            selectedIcon: Icon(Icons.settings_input_component),
            label: '\u0429\u0438\u0442\u044b',
          ),
          const NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder_open),
            label: '\u0424\u0430\u0439\u043b\u044b',
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
        title: 'РЈРґР°Р»РµРЅРёРµ СЌС‚Р°РїР°',
        content:
            'Р’С‹ СѓРІРµСЂРµРЅС‹, С‡С‚Рѕ С…РѕС‚РёС‚Рµ СѓРґР°Р»РёС‚СЊ СЌС‚Р°Рї "${StageCard.getStageTitleDisplay(stage.title)}"? Р’СЃРµ СЃРјРµС‚С‹ РІРЅСѓС‚СЂРё Р±СѓРґСѓС‚ СѓРґР°Р»РµРЅС‹.',
        confirmText: 'РЈРґР°Р»РёС‚СЊ',
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
            SnackBar(content: Text('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: Tooltip(
        message: 'Р”РѕР±Р°РІРёС‚СЊ СЌС‚Р°Рї',
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
                'РћР± РѕР±СЉРµРєС‚Рµ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
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
                    color: AppDesignTokens.cardShadow(context),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: AppDesignTokens.softBorder(context)),
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
                        // Р—Р°РєР°Р·С‡РёРє
                        DetailInfoRow(
                          icon: Icons.person_outline,
                          label: 'Р—РђРљРђР—Р§РРљ',
                          value: project.clientInfo.isNotEmpty
                              ? project.clientInfo
                              : 'вЂ”',
                          color: Colors.blue.shade600,
                          selectable: true,
                        ),
                        const SizedBox(height: 16),
                        // РСЃС‚РѕС‡РЅРёРє
                        DetailInfoRow(
                          icon: Icons.info_outline,
                          label: 'РРЎРўРћР§РќРРљ',
                          value: project.source.isNotEmpty
                              ? project.source
                              : 'вЂ”',
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
                  'Р­С‚Р°РїС‹ СЂР°Р±РѕС‚',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (project.stages.isEmpty)
              const FriendlyEmptyState(
                icon: Icons.layers_clear_rounded,
                title: 'Р­С‚Р°РїС‹ РµС‰Рµ РЅРµ СЃРѕР·РґР°РЅС‹',
                subtitle:
                    'Р”РѕР±Р°РІСЊС‚Рµ РїРµСЂРІС‹Р№ СЌС‚Р°Рї, С‡С‚РѕР±С‹ РїСЂРѕРґРѕР»Р¶РёС‚СЊ СЂР°Р±РѕС‚Сѓ РїРѕ РѕР±СЉРµРєС‚Сѓ.',
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
      builder: (context) => AddStageDialog(
        projectId: project.id.toString(),
        existingStageKeys: existingKeys,
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
                title: "РџСЂРѕРµРєС‚С‹ Рё СЃС…РµРјС‹",
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
                title: "Р РµР°Р»РёР·Р°С†РёСЏ (Р­С‚Р°РїС‹ 1-2)",
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
                title: "Р¤РёРЅРёС€РЅС‹Рµ С„РѕС‚Рѕ",
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
              "Р›РёРјРёС‚ Р·Р°РіСЂСѓР·РєРё: РґРѕ 12 С„Р°Р№Р»РѕРІ РЅР° РїСЂРѕРµРєС‚, РґРѕ 20 РњР‘ РєР°Р¶РґС‹Р№",
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
    // 1. РџСЂРѕРІРµСЂРєР° Р»РёРјРёС‚Р° РєРѕР»РёС‡РµСЃС‚РІР° С„Р°Р№Р»РѕРІ (РњР°РєСЃ 12 РЅР° РїСЂРѕРµРєС‚)
    if (project.files.length >= 12) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => const ConfirmationDialog(
            title: 'Р›РёРјРёС‚ С„Р°Р№Р»РѕРІ',
            content:
                'Р”РѕСЃС‚РёРіРЅСѓС‚ Р»РёРјРёС‚ РІ 12 С„Р°Р№Р»РѕРІ РЅР° РїСЂРѕРµРєС‚. РЈРґР°Р»РёС‚Рµ СЃС‚Р°СЂС‹Рµ С„Р°Р№Р»С‹, С‡С‚РѕР±С‹ Р·Р°РіСЂСѓР·РёС‚СЊ РЅРѕРІС‹Рµ.',
            confirmText: 'Р—Р°РєСЂС‹С‚СЊ',
            cancelText: '', // РЎРєСЂС‹РІР°РµРј РєРЅРѕРїРєСѓ РѕС‚РјРµРЅС‹
            isDestructive: false,
            themeColor: Colors.indigo,
          ),
        );
      }
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 2. Р’С‹Р±РѕСЂ С„Р°Р№Р»РѕРІ СЃ С„РёР»СЊС‚СЂР°С†РёРµР№ РїРѕ СЂР°СЃС€РёСЂРµРЅРёСЋ
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
      // РџСЂРѕРІРµСЂРєР°: РЅРµ РїСЂРµРІС‹СЃРёС‚ Р»Рё РґРѕР±Р°РІР»РµРЅРёРµ РЅРѕРІС‹С… С„Р°Р№Р»РѕРІ РѕР±С‰РёР№ Р»РёРјРёС‚
      if (project.files.length + result.files.length > 12) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => ConfirmationDialog(
              title: 'РЎР»РёС€РєРѕРј РјРЅРѕРіРѕ С„Р°Р№Р»РѕРІ',
              content:
                  'Р’С‹ РІС‹Р±СЂР°Р»Рё ${result.files.length} С„Р°Р№Р»РѕРІ РґР»СЏ Р·Р°РіСЂСѓР·РєРё. Р’ С‚РµРєСѓС‰РёР№ РїСЂРѕРµРєС‚ РјРѕР¶РЅРѕ Р·Р°РіСЂСѓР·РёС‚СЊ РµС‰Рµ РЅРµ Р±РѕР»РµРµ ${12 - project.files.length} С„Р°Р№Р»РѕРІ.',
              confirmText: 'Р—Р°РєСЂС‹С‚СЊ',
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
            content: Text(
                'РќР°С‡РёРЅР°СЋ Р·Р°РіСЂСѓР·РєСѓ ${result.files.length} С„Р°Р№Р»РѕРІ...')),
      );

      for (final pickedFile in result.files) {
        if (pickedFile.path == null) {
          uploadErrors.add(
              '${pickedFile.name}: РЅРµ СѓРґР°Р»РѕСЃСЊ РїРѕР»СѓС‡РёС‚СЊ РїСѓС‚СЊ Рє С„Р°Р№Р»Сѓ');
          continue;
        }
        // 3. РџСЂРѕРІРµСЂРєР° СЂР°Р·РјРµСЂР° С„Р°Р№Р»Р° (РњР°РєСЃ 20 РњР‘)
        final file = File(pickedFile.path!);
        final sizeInBytes = await file.length();
        final sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 20) {
          sizeErrors.add(
            '${pickedFile.name} (${sizeInMb.toStringAsFixed(1)} РњР‘)',
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

      // 4. РС‚РѕРіРѕРІС‹Р№ РѕС‚С‡РµС‚
      if (sizeErrors.isNotEmpty && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => ConfirmationDialog(
            title: 'РќРµРєРѕС‚РѕСЂС‹Рµ С„Р°Р№Р»С‹ РЅРµ Р·Р°РіСЂСѓР¶РµРЅС‹',
            content:
                'РЎР»РµРґСѓСЋС‰РёРµ С„Р°Р№Р»С‹ РїСЂРµРІС‹С€Р°СЋС‚ Р»РёРјРёС‚ РІ 20 РњР‘:\n\n${sizeErrors.join('\n')}',
            confirmText: 'Р—Р°РєСЂС‹С‚СЊ',
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
            title: 'Р§Р°СЃС‚СЊ С„Р°Р№Р»РѕРІ РЅРµ Р·Р°РіСЂСѓР¶РµРЅР°',
            content: uploadErrors.join('\n'),
            confirmText: 'Р—Р°РєСЂС‹С‚СЊ',
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
                  'РЈСЃРїРµС€РЅРѕ Р·Р°РіСЂСѓР¶РµРЅРѕ: $successCount РёР· ${result.files.length}')),
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
        title: 'РЈРґР°Р»РёС‚СЊ С„Р°Р№Р»?',
        content:
            'Р­С‚Рѕ РґРµР№СЃС‚РІРёРµ РЅРµР»СЊР·СЏ РѕС‚РјРµРЅРёС‚СЊ. Р¤Р°Р№Р» Р±СѓРґРµС‚ С„РёР·РёС‡РµСЃРєРё СѓРґР°Р»РµРЅ СЃ СЃРµСЂРІРµСЂР°.',
        confirmText: 'РЈРґР°Р»РёС‚СЊ',
        cancelText: 'РћС‚РјРµРЅР°',
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
          const SnackBar(content: Text('Р¤Р°Р№Р» СѓРґР°Р»РµРЅ')),
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

  String _safeFileName(String rawName, {String fallback = 'file'}) {
    final trimmed = rawName.trim();
    final candidate = trimmed.isEmpty ? fallback : trimmed;
    final sanitized = candidate
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'[\u0000-\u001F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final withoutTrailingDots = sanitized.replaceAll(RegExp(r'[. ]+$'), '');
    return withoutTrailingDots.isEmpty ? fallback : withoutTrailingDots;
  }

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
    final response = await http.get(Uri.parse(url));
    final tempDir = await getTemporaryDirectory();
    final fallbackName = _fileNameFromUrl(url);
    final safeName = _safeFileName(
      preferredName ?? fallbackName,
      fallback: _safeFileName(fallbackName, fallback: 'file'),
    );
    final localFile = File('${tempDir.path}/$safeName');
    await localFile.writeAsBytes(response.bodyBytes);
    TempFileService().track(localFile);
    return localFile;
  }

  @override
  Widget build(BuildContext context) {
    final fileUrl = widget.file.file;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supportsHover = switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => false,
      _ => true,
    };
    final showActions = supportsHover ? _isHovered : _areTouchActionsVisible;

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
              // РљРЅРѕРїРєРё СѓРїСЂР°РІР»РµРЅРёСЏ (РїРѕСЏРІР»СЏСЋС‚СЃСЏ РїСЂРё РЅР°РІРµРґРµРЅРёРё)
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedOpacity(
                  opacity: showActions ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(
                            AppDesignTokens.isDark(context) ? 0.82 : 0.92,
                          ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
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
                          tooltip: "РџРµСЂРµРёРјРµРЅРѕРІР°С‚СЊ",
                          onTap: () => _renameFile(context),
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.download_rounded,
                          tooltip: "РЎРѕС…СЂР°РЅРёС‚СЊ РєР°Рє...",
                          onTap: () => _saveAsFile(context, fileUrl),
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.share_rounded,
                          tooltip: "РџРѕРґРµР»РёС‚СЊСЃСЏ",
                          onTap: () => _shareFile(fileUrl),
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.close_rounded,
                          tooltip: "РЈРґР°Р»РёС‚СЊ",
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
        title: 'РџРµСЂРµРёРјРµРЅРѕРІР°С‚СЊ С„Р°Р№Р»',
        labelText: 'РќРѕРІРѕРµ РёРјСЏ',
        initialValue: nameWithoutExtension,
        confirmText: 'РЎРѕС…СЂР°РЅРёС‚СЊ',
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
                const SnackBar(
                    content: Text('Р¤Р°Р№Р» РїРµСЂРµРёРјРµРЅРѕРІР°РЅ')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('РћС€РёР±РєР° РїРµСЂРµРёРјРµРЅРѕРІР°РЅРёСЏ: $e')),
              );
            }
          }
        }
      }
    }
  }

  Future<void> _saveAsFile(BuildContext context, String url) async {
    try {
      final tempFile =
          await _createDownloadedTempFile(url, preferredName: displayName);

      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'РЎРѕС…СЂР°РЅРёС‚СЊ С„Р°Р№Р» РєР°Рє...',
        fileName: _safeFileName(displayName, fallback: 'file'),
      );

      if (outputFile != null) {
        await tempFile.copy(outputFile);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Р¤Р°Р№Р» СЃРѕС…СЂР°РЅРµРЅ: $outputFile')),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('РЎРѕС…СЂР°РЅРµРЅРёРµ РѕС‚РјРµРЅРµРЅРѕ')),
        );
      }
    } catch (e) {
      debugPrint("Save file error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ: $e')),
        );
      }
    }
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

  Future<void> _shareFile(String url) async {
    try {
      final localFile =
          await _createDownloadedTempFile(url, preferredName: displayName);
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
          cursor: SystemMouseCursors.click,
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
    // РџСЂР°РІРёР»Рѕ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ:
    // 0 С„Р°Р№Р»РѕРІ -> Р·Р°РєСЂС‹С‚Рѕ, 1..6 -> РѕС‚РєСЂС‹С‚Рѕ, 7+ -> Р·Р°РєСЂС‹С‚Рѕ.
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompactHeader = MediaQuery.sizeOf(context).width < 360;
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
                      padding: const EdgeInsets.fromLTRB(19, 14, 14, 14),
                      child: Column(
                        children: [
                          Row(
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
                                        color: isDark
                                            ? scheme.onSurface
                                            : Colors.grey.shade900,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isExpanded
                                          ? 'РќР°Р¶РјРёС‚Рµ, С‡С‚РѕР±С‹ СЃРІРµСЂРЅСѓС‚СЊ'
                                          : 'РќР°Р¶РјРёС‚Рµ, С‡С‚РѕР±С‹ СЂР°Р·РІРµСЂРЅСѓС‚СЊ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? scheme.onSurfaceVariant
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCompactHeader) ...[
                                _buildFilesCountPill(widget.files.length),
                                const SizedBox(width: 8),
                                _buildHeaderActionButton(
                                  icon: Icons.add_rounded,
                                  tooltip: 'Р—Р°РіСЂСѓР·РёС‚СЊ С„Р°Р№Р»С‹',
                                  onTap: widget.onUpload,
                                  isPrimary: true,
                                ),
                                const SizedBox(width: 6),
                              ],
                              _buildHeaderExpandToggle(
                                tooltip: _isExpanded
                                    ? 'РЎРІРµСЂРЅСѓС‚СЊ'
                                    : 'Р Р°Р·РІРµСЂРЅСѓС‚СЊ',
                                onTap: () =>
                                    setState(() => _isExpanded = !_isExpanded),
                              ),
                            ],
                          ),
                          if (isCompactHeader) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFilesCountPill(widget.files.length),
                                _buildHeaderActionButton(
                                  icon: Icons.add_rounded,
                                  tooltip: 'Р—Р°РіСЂСѓР·РёС‚СЊ С„Р°Р№Р»С‹',
                                  onTap: widget.onUpload,
                                  isPrimary: true,
                                ),
                              ],
                            ),
                          ],
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
                              title:
                                  'РќРµС‚ Р·Р°РіСЂСѓР¶РµРЅРЅС‹С… С„Р°Р№Р»РѕРІ',
                              subtitle:
                                  'Р—Р°РіСЂСѓР·РёС‚Рµ С„Р°Р№Р»С‹ СЌС‚РѕРіРѕ С‚РёРїР°, С‡С‚РѕР±С‹ РѕРЅРё РїРѕСЏРІРёР»РёСЃСЊ РІ СЃРїРёСЃРєРµ.',
                              accentColor: Colors.blueGrey,
                              iconSize: 66,
                              padding: EdgeInsets.symmetric(vertical: 18),
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
          mouseCursor: SystemMouseCursors.click,
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
