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

  Widget buildBtn(String label, Color bg, Color fg, VoidCallback onTap,
      {bool isGradient = false, bool enabled = true, IconData? icon}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isGradient ? null : (bg == Colors.transparent ? bg : bg),
          gradient: isGradient
              ? LinearGradient(
                  colors: [Colors.green.shade200, Colors.blue.shade200])
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: bg == Colors.transparent
              ? null
              : [
                  BoxShadow(
                    color: bg.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            mouseCursor:
                enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            hoverColor: bg == Colors.transparent
                ? Colors.grey.withOpacity(0.1)
                : fg.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fg, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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

  Widget buildPopupBtn(BuildContext context, String label, Color bg, Color fg,
      List<PopupMenuEntry<String>> items, ValueChanged<String> onSelected,
      {bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Colors.transparent,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerTheme: const DividerThemeData(thickness: 1, space: 1),
                popupMenuTheme: PopupMenuThemeData(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  color: Colors.white,
                  // Setting a more compact default height for menu items if possible
                  // (Flutter doesn't have a direct 'height' in theme, but we can use constraints)
                ),
              ),
              child: PopupMenuButton<String>(
                tooltip: label,
                enabled: enabled,
                offset: const Offset(0, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: onSelected,
                itemBuilder: (context) => items,
                child: InkWell(
                  onTap: null, // PopupMenuButton handles tap
                  mouseCursor: enabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  hoverColor: fg.withOpacity(0.1),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: fg,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: fg, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
    const themeColor = Colors.orange;

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
            icon: Icons.segment_rounded,
            themeColor: themeColor,
          ),

          const SizedBox(height: 8),

          // 1. View
          buildHeader(Icons.remove_red_eye_rounded, "Просмотр"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: buildBtn("Все сметы (TXT)", Colors.transparent, Colors.white,
                () {
              Navigator.pop(context);
              _showReport(context, ref);
            }, isGradient: true, enabled: hasWorks || hasMaterials),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: buildBtn(
                "Заказчик", Colors.green.shade100, Colors.green.shade800,
                () async {
              Navigator.pop(context);
              await _processAction(context, ref,
                  isWork: true, type: 'total', share: share);
            }, enabled: hasWorks),
          ),
          if (hasPartnerWorks) ...[
            const SizedBox(width: 8),
            Expanded(
              child: buildBtn(
                  "Контрагент", Colors.green.shade100, Colors.green.shade800,
                  () async {
                Navigator.pop(context);
                await _processAction(context, ref,
                    isWork: true, type: 'employer', share: share);
              }, enabled: hasWorks),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: buildBtn(
                "Материалы", Colors.blue.shade100, Colors.blue.shade800,
                () async {
              Navigator.pop(context);
              await _processAction(context, ref,
                  isWork: false, type: 'total', share: share);
            }, enabled: hasMaterials),
          ),
        ],
      ),
    );
  }

  Widget _buildShareSection(BuildContext context, WidgetRef ref, bool hasWorks,
      bool hasPartnerWorks, bool hasMaterials, bool share) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: buildPopupBtn(
              context,
              "Работы",
              Colors.green.shade100,
              Colors.green.shade800,
              [
                PopupMenuItem(
                  value: 'total',
                  height: 40,
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
                    height: 40,
                    child: buildPopupItem(
                      icon: Icons.handshake_rounded,
                      text: "Для Контрагента",
                      color: Colors.green.shade700,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'our',
                    height: 40,
                    child: buildPopupItem(
                      icon: Icons.engineering_rounded,
                      text: "Наши",
                      color: Colors.green.shade700,
                    ),
                  ),
                ]
              ],
              (val) async {
                Navigator.pop(context);
                await _processAction(context, ref,
                    isWork: true, type: val, share: share);
              },
              enabled: hasWorks,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: buildPopupBtn(
              context,
              "Материалы",
              Colors.blue.shade100,
              Colors.blue.shade800,
              [
                PopupMenuItem(
                  value: 'noprice',
                  height: 40,
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
                    height: 40,
                    child: buildPopupItem(
                      icon: Icons.attach_money_rounded,
                      text: "С ценами",
                      color: Colors.blue.shade700,
                    ),
                  ),
                  if (markupPercent > 0)
                    PopupMenuItem(
                      value: 'markup',
                      height: 40,
                      child: buildPopupItem(
                        icon: Icons.trending_up_rounded,
                        text:
                            "С наценкой (+${markupPercent.toStringAsFixed(0)}%)",
                        color: Colors.blue.shade700,
                      ),
                    ),
                ]
              ],
              (val) async {
                Navigator.pop(context);
                await _processAction(context, ref,
                    isWork: false, type: val, share: share);
              },
              enabled: hasMaterials,
            ),
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
                  child: buildBtn(
                    "Копировать",
                    themeColor.shade100,
                    themeColor.shade800,
                    () {
                      Clipboard.setData(ClipboardData(text: _currentText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Скопировано в буфер!")),
                      );
                    },
                    icon: Icons.copy_rounded, // Added icon
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
    const themeColor = Colors.deepPurple;

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
            icon: Icons.auto_graph_rounded,
            themeColor: themeColor,
          ),

          const SizedBox(height: 8),

          // 1. Export PDF
          buildHeader(Icons.picture_as_pdf_rounded, "Экспорт в PDF"),
          _buildPdfSection(context, ref, hasWorks, hasPartnerWorks,
              hasMaterials, false), // share = false

          // 2. Share PDF
          buildHeader(Icons.share_rounded, "Поделиться PDF"),
          _buildPdfSection(context, ref, hasWorks, hasPartnerWorks,
              hasMaterials, true), // share = true

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPdfSection(BuildContext context, WidgetRef ref, bool hasWorks,
      bool hasPartnerWorks, bool hasMaterials, bool share) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: buildPopupBtn(
              context,
              "Работы",
              Colors.green.shade100,
              Colors.green.shade800,
              [
                PopupMenuItem(
                  value: 'total',
                  height: 40,
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
                    height: 40,
                    child: buildPopupItem(
                      icon: Icons.handshake_rounded,
                      text: "Для Контрагента",
                      color: Colors.green.shade700,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'our',
                    height: 40,
                    child: buildPopupItem(
                      icon: Icons.engineering_rounded,
                      text: "Наши",
                      color: Colors.green.shade700,
                    ),
                  ),
                ]
              ],
              (val) {
                Navigator.pop(context);
                if (val == 'total') {
                  _printPdfWithParams(context, ref,
                      isWork: true, type: 'total', share: share);
                } else if (val == 'employer') {
                  _printPdfWithParams(context, ref,
                      isWork: true, type: 'employer', share: share);
                } else if (val == 'our') {
                  _printPdfWithParams(context, ref,
                      isWork: true, type: 'our', share: share);
                }
              },
              enabled: hasWorks,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: buildPopupBtn(
              context,
              "Материалы",
              Colors.blue.shade100,
              Colors.blue.shade800,
              [
                PopupMenuItem(
                  value: 'noprice',
                  height: 40,
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
                    height: 40,
                    child: buildPopupItem(
                      icon: Icons.attach_money_rounded,
                      text: "С ценами",
                      color: Colors.blue.shade700,
                    ),
                  ),
                  if (markupPercent > 0)
                    PopupMenuItem(
                      value: 'markup',
                      height: 40,
                      child: buildPopupItem(
                        icon: Icons.trending_up_rounded,
                        text:
                            "С наценкой (+${markupPercent.toStringAsFixed(0)}%)",
                        color: Colors.blue.shade700,
                      ),
                    ),
                ]
              ],
              (val) {
                Navigator.pop(context);
                if (val == 'noprice') {
                  _printPdfWithParams(context, ref,
                      isWork: false, showPrices: false, share: share);
                } else if (val == 'price') {
                  _printPdfWithParams(context, ref,
                      isWork: false, showPrices: true, share: share);
                } else if (val == 'markup') {
                  _printPdfWithParams(context, ref,
                      isWork: false,
                      showPrices: true,
                      markup: markupPercent,
                      share: share);
                }
              },
              enabled: hasMaterials,
            ),
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
