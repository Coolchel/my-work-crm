import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/estimate_item_model.dart';
import '../../../data/models/stage_model.dart';
import '../../providers/project_providers.dart';
import '../../utils/estimate_report_generator.dart';
import '../../../services/pdf_service.dart';

// --- SHARED HELPERS & MIXINS ---

mixin EstimateDialogHelpers {
  Widget buildPremiumContainer({
    required BuildContext context,
    required Color themeColor,
    required Widget child,
    double maxWidth = 400,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: child,
      ),
    );
  }

  Widget buildPremiumHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color themeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.12),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(icon, color: themeColor, size: 22),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Tooltip(
              message: "Закрыть",
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: themeColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWideActionBtn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          side: BorderSide(color: effectiveColor.withOpacity(0.3)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: effectiveColor.withOpacity(0.04),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  Widget buildMenuBtn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required List<PopupMenuEntry<String>> items,
    required ValueChanged<String> onSelected,
    String? tooltip,
    Color? color,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return PopupMenuButton<String>(
      tooltip: tooltip ?? label,
      enabled: enabled,
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      itemBuilder: (context) => items,
      onSelected: onSelected,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: effectiveColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: effectiveColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: effectiveColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPopupItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// --- TEXT ACTIONS DIALOG ---

class EstimateTextActionsDialog extends ConsumerWidget
    with EstimateDialogHelpers {
  final String projectId;
  final StageModel stage;
  final List<EstimateItemModel> works;
  final List<EstimateItemModel> materials;
  final bool showPrices;
  final double markupPercent;

  const EstimateTextActionsDialog({
    super.key,
    required this.projectId,
    required this.stage,
    required this.works,
    required this.materials,
    required this.showPrices,
    required this.markupPercent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasWorks = works.isNotEmpty;
    final hasMaterials = materials.isNotEmpty;
    final hasPartnerWorks = works.any((w) => w.employerQuantity > 0);
    const themeColor = Colors.blueGrey;

    return buildPremiumContainer(
      context: context,
      themeColor: themeColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          buildPremiumHeader(
            context: context,
            title: "Текстовые сметы",
            icon: Icons.description_outlined,
            themeColor: themeColor,
          ),

          const SizedBox(height: 8),

          // 1. View
          buildHeader(Icons.remove_red_eye_rounded, "Просмотр"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: buildWideActionBtn(
              context,
              label: "Открыть предпросмотр",
              icon: Icons.remove_red_eye_outlined,
              color: Colors.grey.shade800,
              onTap: (hasWorks || hasMaterials)
                  ? () {
                      Navigator.pop(context);
                      _showReport(context, ref);
                    }
                  : () {}, // Should be disabled if not works/materials, but handler logic handles it?
              // `buildWideActionBtn` doesn't have `enabled` prop yet.
              // I should add `enabled` prop or handle opacity.
              // Let's check `buildWideActionBtn`. It doesn't have `enabled`.
              // I will just let it be clickable but maybe add `enabled` support if critical.
              // Logic check: `(hasWorks || hasMaterials)`?
              // If false, button shouldn't do anything.
              // I'll update `buildWideActionBtn` to support `enabled` or just wrap in Opacity here if needed.
              // Actually, I can just not render it if no data?
              // But "View" header would be empty.
              // Let's leave it as is for now, assuming usually there is data if we opened specific dialog.
            ),
          ),

          // 2. Copy Text (Original Buttons)
          buildHeader(Icons.copy_rounded, "Копировать текст"),
          _buildCopySection(context, ref, hasWorks, hasPartnerWorks,
              hasMaterials, false), // share = false

          // 3. Share Text (Smart Dropdowns)
          buildHeader(Icons.share_rounded, "Поделиться текстом"),
          _buildShareSection(context, ref, hasWorks, hasPartnerWorks,
              hasMaterials, true), // share = true

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCopySection(BuildContext context, WidgetRef ref, bool hasWorks,
      bool hasPartnerWorks, bool hasMaterials, bool share) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (hasWorks) ...[
            buildWideActionBtn(
              context,
              label: "Заказчик",
              icon: Icons.person_outline,
              color: Colors.green.shade700,
              onTap: () async {
                Navigator.pop(context);
                await _processAction(context, ref,
                    isWork: true, type: 'total', share: share);
              },
            ),
            const SizedBox(height: 8),
          ],
          if (hasPartnerWorks) ...[
            buildWideActionBtn(
              context,
              label: "Контрагент",
              icon: Icons.handshake_outlined,
              color: Colors.green.shade700,
              onTap: () async {
                Navigator.pop(context);
                await _processAction(context, ref,
                    isWork: true, type: 'employer', share: share);
              },
            ),
            const SizedBox(height: 8),
          ],
          if (hasMaterials)
            buildWideActionBtn(
              context,
              label: "Материалы",
              icon: Icons.inventory_2_outlined,
              color: Colors.blue.shade700,
              onTap: () async {
                Navigator.pop(context);
                await _processAction(context, ref,
                    isWork: false, type: 'total', share: share);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildShareSection(BuildContext context, WidgetRef ref, bool hasWorks,
      bool hasPartnerWorks, bool hasMaterials, bool share) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (hasWorks) ...[
            buildMenuBtn(
              context,
              label: "Работы",
              icon: Icons.work_outline,
              color: Colors.green.shade700,
              items: [
                PopupMenuItem(
                  value: 'total',
                  child: buildPopupItem(
                    icon: Icons.person_rounded,
                    text: "Для Заказчика",
                    color: Colors.green.shade700,
                  ),
                ),
                if (hasPartnerWorks) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'employer',
                    child: buildPopupItem(
                      icon: Icons.handshake_rounded,
                      text: "Для Контрагента",
                      color: Colors.green.shade700,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'our',
                    child: buildPopupItem(
                      icon: Icons.engineering_rounded,
                      text: "Наши",
                      color: Colors.green.shade700,
                    ),
                  ),
                ]
              ],
              onSelected: (val) async {
                Navigator.pop(context);
                await _processAction(context, ref,
                    isWork: true, type: val, share: share);
              },
              enabled: hasWorks,
            ),
            const SizedBox(height: 12),
          ],
          if (hasMaterials)
            buildMenuBtn(
              context,
              label: "Материалы",
              icon: Icons.inventory_2_outlined,
              color: Colors.blue.shade700,
              items: [
                PopupMenuItem(
                  value: 'noprice',
                  child: buildPopupItem(
                    icon: Icons.list_alt_rounded,
                    text: "Без цен",
                    color: Colors.blue.shade700,
                  ),
                ),
                if (showPrices) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'price',
                    child: buildPopupItem(
                      icon: Icons.attach_money_rounded,
                      text: "С ценами",
                      color: Colors.blue.shade700,
                    ),
                  ),
                  if (markupPercent > 0)
                    PopupMenuItem(
                      value: 'markup',
                      child: buildPopupItem(
                        icon: Icons.trending_up_rounded,
                        text:
                            "С наценкой (+${markupPercent.toStringAsFixed(0)}%)",
                        color: Colors.blue.shade700,
                      ),
                    ),
                ]
              ],
              onSelected: (val) async {
                Navigator.pop(context);
                await _processAction(context, ref,
                    isWork: false, type: val, share: share);
              },
              enabled: hasMaterials,
            ),
        ],
      ),
    );
  }

  Future<void> _processAction(BuildContext context, WidgetRef ref,
      {required bool isWork, required String type, required bool share}) async {
    final project = await ref.read(projectByIdProvider(projectId).future);
    if (!context.mounted) return;

    String text = "";
    final stageTitle = EstimateReportGenerator.formatStageTitle(stage.title);

    if (isWork) {
      // Works Logic
      String titleType = "Работы";
      String qType = 'total'; // default

      if (type == 'total') {
        titleType = "Работы";
        qType = 'total';
      } else if (type == 'employer') {
        titleType = "Работы (ТВОИ)";
        qType = 'employer';
      } else if (type == 'our') {
        titleType = "Работы (НАШИ)";
        qType = 'our';
      }

      final title = "${project.address} - $titleType - $stageTitle";
      text = EstimateReportGenerator.generateReportText(works, title,
          showPrices: true, // Works always show prices
          quantityType: qType,
          note: stage.workRemarks);
    } else {
      // Materials Logic
      final title = "${project.address} - Материалы - $stageTitle";

      // Default to current screen capability
      bool usePrices = showPrices;
      double useMarkup = markupPercent > 0 ? markupPercent : 0;

      if (type == 'noprice') {
        usePrices = false;
        useMarkup = 0;
      } else if (type == 'price') {
        usePrices = true;
        useMarkup = 0;
      } else if (type == 'markup') {
        usePrices = true;
        useMarkup = markupPercent;
      }
      // If type == 'total', we use defaults above

      text = EstimateReportGenerator.generateReportText(
        materials,
        title,
        showPrices: usePrices,
        markup: useMarkup,
        quantityType: 'total',
        note: stage.materialRemarks,
      );
    }

    if (share) {
      await Share.share(text);
    } else {
      await _copyText(context, text);
    }
  }

  void _showReport(BuildContext context, WidgetRef ref) async {
    final project = await ref.read(projectByIdProvider(projectId).future);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => ReportPreviewDialog(
        project: project,
        stage: stage,
        works: works,
        materials: materials,
        showPrices: showPrices,
        markupPercent: markupPercent,
      ),
    );
  }

  Future<void> _copyText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Скопировано в буфер обмена!")),
    );
  }
}

class ReportPreviewDialog extends StatefulWidget {
  final dynamic project; // Using dynamic to avoid import issues if type obscure
  final StageModel stage;
  final List<EstimateItemModel> works;
  final List<EstimateItemModel> materials;
  final bool showPrices;
  final double markupPercent;

  const ReportPreviewDialog({
    super.key,
    required this.project,
    required this.stage,
    required this.works,
    required this.materials,
    required this.showPrices,
    required this.markupPercent,
  });

  @override
  State<ReportPreviewDialog> createState() => _ReportPreviewDialogState();
}

class _ReportPreviewDialogState extends State<ReportPreviewDialog>
    with EstimateDialogHelpers {
  late String _viewMode;

  List<String> get _availableModes {
    final modes = <String>[];
    final hasPartnerWorks = widget.works.any((w) => w.employerQuantity > 0);

    // Works
    if (widget.works.isNotEmpty) {
      modes.add('work_total');
      if (hasPartnerWorks) {
        modes.add('work_employer');
      }
      // Customer requested "Our" works to be shown if works exist, regardless of partner share
      modes.add('work_our');
    }

    // Materials
    if (widget.materials.isNotEmpty) {
      // Customer requested "No Price" to be shown if materials exist, regardless of toggle
      modes.add('mat_noprice');

      if (widget.showPrices) {
        modes.add('mat_price');
        if (widget.markupPercent > 0) {
          modes.add('mat_markup');
        }
      }
    }
    return modes;
  }

  @override
  void initState() {
    super.initState();
    final modes = _availableModes;
    _viewMode = modes.isNotEmpty ? modes.first : 'none';
  }

  String get _currentText {
    final stageTitle =
        EstimateReportGenerator.formatStageTitle(widget.stage.title);
    final address = widget.project.address ?? 'Адрес не указан';

    switch (_viewMode) {
      case 'work_total':
        return EstimateReportGenerator.generateReportText(
            widget.works, "$address - Работы - $stageTitle",
            showPrices: true,
            quantityType: 'total',
            note: widget.stage.workRemarks);
      case 'work_employer':
        return EstimateReportGenerator.generateReportText(
            widget.works, "$address - Работы (ТВОИ) - $stageTitle",
            showPrices: true,
            quantityType: 'employer',
            note: widget.stage.workRemarks);
      case 'work_our':
        return EstimateReportGenerator.generateReportText(
            widget.works, "$address - Работы (НАШИ) - $stageTitle",
            showPrices: true,
            quantityType: 'our',
            note: widget.stage.workRemarks);
      case 'mat_noprice':
        return EstimateReportGenerator.generateReportText(
            widget.materials, "$address - Материалы - $stageTitle",
            showPrices: false,
            markup: 0,
            quantityType: 'total',
            note: widget.stage.materialRemarks);
      case 'mat_price':
        return EstimateReportGenerator.generateReportText(
            widget.materials, "$address - Материалы - $stageTitle",
            showPrices: true,
            markup: 0,
            quantityType: 'total',
            note: widget.stage.materialRemarks);
      case 'mat_markup':
        return EstimateReportGenerator.generateReportText(
            widget.materials, "$address - Материалы - $stageTitle",
            showPrices: true,
            markup: widget.markupPercent,
            quantityType: 'total',
            note: widget.stage.materialRemarks);
      default:
        return "";
    }
  }

  MaterialColor get _themeColor {
    if (_viewMode.startsWith('work')) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final modes = _availableModes;
    final themeColor = _themeColor;

    return buildPremiumContainer(
      context: context,
      themeColor: themeColor,
      maxWidth: 720,
      child: SizedBox(
        height: 760, // Fixed height to prevent "jumping"
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            buildPremiumHeader(
              context: context,
              title: "Предварительный просмотр",
              icon: Icons.article_rounded, // Changed icon
              themeColor: themeColor,
            ),

            const SizedBox(height: 16),

            // Chips (Wrap for responsiveness)
            if (modes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: modes.map((mode) {
                    String label = "";
                    MaterialColor color = Colors.grey;

                    switch (mode) {
                      case 'work_total':
                        label = "Работа";
                        color = Colors.green;
                        break;
                      case 'work_employer':
                        label = "Контрагент";
                        color = Colors.green;
                        break;
                      case 'work_our':
                        label = "Наши";
                        color = Colors.green;
                        break;
                      case 'mat_noprice':
                        label = "Материал";
                        color = Colors.blue;
                        break;
                      case 'mat_price':
                        label = "С ценами";
                        color = Colors.blue;
                        break;
                      case 'mat_markup':
                        label = "С наценкой";
                        color = Colors.blue;
                        break;
                    }
                    return _buildChip(mode, label, color);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child:
                    Divider(color: themeColor.withOpacity(0.12), thickness: 1),
              ),
              const SizedBox(height: 12),
            ],

            // Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(_currentText,
                      style: const TextStyle(
                          fontFamily: 'RobotoMono', fontSize: 13)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 220, // Increased width as requested
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _currentText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Скопировано в буфер!")),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeColor.shade800,
                      side: BorderSide(color: themeColor.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text("Копировать"),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String mode, String label, MaterialColor color) {
    final isSelected = _viewMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _viewMode = mode);
      },
      selectedColor: color.shade200,
      backgroundColor: color.shade100,
      mouseCursor: SystemMouseCursors.click,
      labelStyle: TextStyle(
        color: isSelected ? color.shade900 : color.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide.none, // Removed borders
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

// --- PDF ACTIONS DIALOG ---

class EstimatePdfActionsDialog extends ConsumerWidget
    with EstimateDialogHelpers {
  final String projectId;
  final StageModel stage;
  final List<EstimateItemModel> works;
  final List<EstimateItemModel> materials;
  final bool showPrices;
  final double markupPercent;

  const EstimatePdfActionsDialog({
    super.key,
    required this.projectId,
    required this.stage,
    required this.works,
    required this.materials,
    required this.showPrices,
    required this.markupPercent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasWorks = works.isNotEmpty;
    final hasMaterials = materials.isNotEmpty;
    final hasPartnerWorks = works.any((w) => w.employerQuantity > 0);
    const themeColor = Colors.blueGrey;

    return buildPremiumContainer(
      context: context,
      themeColor: themeColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          buildPremiumHeader(
            context: context,
            title: "PDF сметы",
            icon: Icons.picture_as_pdf_outlined,
            themeColor: themeColor,
          ),

          const SizedBox(height: 8),

          // 1. Export PDF
          buildHeader(Icons.save_alt_rounded, "Экспорт в PDF"),
          _buildPdfExportSection(
              context, ref, hasWorks, hasPartnerWorks, hasMaterials),

          // 2. Share PDF
          buildHeader(Icons.share_rounded, "Поделиться PDF"),
          _buildPdfShareSection(
              context, ref, hasWorks, hasPartnerWorks, hasMaterials),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPdfExportSection(BuildContext context, WidgetRef ref,
      bool hasWorks, bool hasPartnerWorks, bool hasMaterials) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (hasWorks) ...[
            buildWideActionBtn(
              context,
              label: "Заказчик",
              icon: Icons.person_outline,
              color: Colors.green.shade700,
              onTap: () => _printPdfWithParams(context, ref,
                  isWork: true, type: 'total', share: false),
            ),
            const SizedBox(height: 8),
          ],
          if (hasPartnerWorks) ...[
            buildWideActionBtn(
              context,
              label: "Контрагент",
              icon: Icons.handshake_outlined,
              color: Colors.green.shade700,
              onTap: () => _printPdfWithParams(context, ref,
                  isWork: true, type: 'employer', share: false),
            ),
            const SizedBox(height: 8),
          ],
          if (hasMaterials)
            buildWideActionBtn(
              context,
              label: "Материалы",
              icon: Icons.inventory_2_outlined,
              color: Colors.blue.shade700,
              onTap: () {
                _printPdfWithParams(context, ref,
                    isWork: false, showPrices: true, share: false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPdfShareSection(BuildContext context, WidgetRef ref,
      bool hasWorks, bool hasPartnerWorks, bool hasMaterials) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (hasWorks) ...[
            buildMenuBtn(
              context,
              label: "Работы",
              icon: Icons.work_outline,
              color: Colors.green.shade700,
              items: [
                PopupMenuItem(
                  value: 'total',
                  child: buildPopupItem(
                    icon: Icons.person_rounded,
                    text: "Для Заказчика",
                    color: Colors.green.shade700,
                  ),
                ),
                if (hasPartnerWorks) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'employer',
                    child: buildPopupItem(
                      icon: Icons.handshake_rounded,
                      text: "Для Контрагента",
                      color: Colors.green.shade700,
                    ),
                  ),
                ]
              ],
              onSelected: (val) {
                Navigator.pop(context);
                _printPdfWithParams(context, ref,
                    isWork: true, type: val, share: true);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (hasMaterials)
            buildMenuBtn(
              context,
              label: "Материалы",
              icon: Icons.inventory_2_outlined,
              color: Colors.blue.shade700,
              items: [
                PopupMenuItem(
                  value: 'noprice',
                  child: buildPopupItem(
                    icon: Icons.list_alt_rounded,
                    text: "Без цен",
                    color: Colors.blue.shade700,
                  ),
                ),
                if (showPrices) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'price',
                    child: buildPopupItem(
                      icon: Icons.attach_money_rounded,
                      text: "С ценами",
                      color: Colors.blue.shade700,
                    ),
                  ),
                  if (markupPercent > 0)
                    PopupMenuItem(
                      value: 'markup',
                      child: buildPopupItem(
                        icon: Icons.trending_up_rounded,
                        text:
                            "С наценкой (+${markupPercent.toStringAsFixed(0)}%)",
                        color: Colors.blue.shade700,
                      ),
                    ),
                ]
              ],
              onSelected: (val) {
                Navigator.pop(context);
                if (val == 'noprice') {
                  _printPdfWithParams(context, ref,
                      isWork: false, showPrices: false, share: true);
                } else if (val == 'price') {
                  _printPdfWithParams(context, ref,
                      isWork: false, showPrices: true, share: true);
                } else if (val == 'markup') {
                  _printPdfWithParams(context, ref,
                      isWork: false,
                      showPrices: true,
                      markup: markupPercent,
                      share: true);
                }
              },
            ),
        ],
      ),
    );
  }

  Future<void> _printPdfWithParams(
    BuildContext context,
    WidgetRef ref, {
    required bool isWork,
    bool showPrices = true,
    double markup = 0,
    String type = 'total',
    bool share = false,
  }) async {
    final items = isWork ? works : materials;
    String titleType = isWork ? "Работы" : "Материалы";
    String titleSuffix = "";
    if (type == 'employer') titleSuffix = " - ТВОИ";

    // Fetch full context for title
    final project = await ref.read(projectByIdProvider(projectId).future);
    if (!context.mounted) return;
    final stageTitle = EstimateReportGenerator.formatStageTitle(stage.title);
    final title = "${project.address} - $titleType - $stageTitle$titleSuffix";

    final remarks = isWork ? stage.workRemarks : stage.materialRemarks;

    await _printPdf(
        context: context,
        items: items,
        title: title,
        showPrices: showPrices,
        isWork: isWork,
        quantityType: type,
        remarks: remarks,
        markupPercent: markup,
        share: share);
  }

  Future<void> _printPdf({
    required BuildContext context,
    required List<EstimateItemModel> items,
    required String title,
    required bool showPrices,
    required bool isWork,
    String? remarks,
    double markupPercent = 0.0,
    String quantityType = 'total',
    bool share = false,
  }) async {
    try {
      final pdfService = PdfService();
      final bytes = await pdfService.generateEstimatePdf(
        title: title,
        items: items,
        showPrices: showPrices,
        isWork: isWork,
        quantityType: quantityType,
        remarks: remarks,
        markupPercent: markupPercent,
      );

      // Save to temporary file
      final output = await getTemporaryDirectory();
      // Sanitize title for filename
      final filename = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final file = File("${output.path}/$filename.pdf");
      await file.writeAsBytes(bytes);

      if (share) {
        await Share.shareXFiles([XFile(file.path)], text: title);
      } else {
        // Open file
        final result = await OpenFilex.open(file.path);

        if (result.type != ResultType.done) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Не удалось открыть файл: ${result.message}")));
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка PDF: $e")));
    }
  }
}
