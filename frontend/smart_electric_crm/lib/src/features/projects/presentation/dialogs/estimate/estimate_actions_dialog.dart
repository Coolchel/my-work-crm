import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

import '../../../data/models/estimate_item_model.dart';
import '../../../data/models/stage_model.dart';
import '../../providers/project_providers.dart';
import '../../../services/pdf_service.dart';
import '../../utils/estimate_report_generator.dart';

class EstimateActionsDialog extends ConsumerWidget {
  final String projectId;
  final StageModel stage;
  final List<EstimateItemModel> works;
  final List<EstimateItemModel> materials;
  final double markupPercent;
  final bool showPrices;

  const EstimateActionsDialog({
    required this.projectId,
    required this.stage,
    required this.works,
    required this.materials,
    required this.markupPercent,
    required this.showPrices,
    super.key,
  });

  // Helper to build section header
  Widget buildHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // Helper for standard action button
  Widget buildBtn(String label, Color bg, Color fg, VoidCallback onTap,
      {bool isGradient = false, bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isGradient ? null : bg,
          gradient: isGradient
              ? LinearGradient(
                  colors: [Colors.green.shade200, Colors.blue.shade200])
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      color: fg, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ),
    );
  }

  // Helper for Popup Button (Works/Materials)
  Widget buildPopupBtn(BuildContext context, String label, Color bg, Color fg,
      List<PopupMenuEntry<String>> items, ValueChanged<String> onSelected,
      {bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Colors.transparent,
            child: Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
              child: PopupMenuButton<String>(
                tooltip: label,
                enabled: enabled,
                offset: const Offset(0, 38),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: onSelected,
                itemBuilder: (context) => items,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label,
                          style: TextStyle(
                              color: fg,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: fg, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasWorks = works.isNotEmpty;
    final hasMaterials = materials.isNotEmpty;
    // Check if there are any works with partner share
    final hasPartnerWorks = works.any((w) => w.employerQuantity > 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Center(
                  child: Text("Действия",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ),
              ),

              // 1. View
              buildHeader(Icons.remove_red_eye, "Просмотр"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: buildBtn(
                    "Все сметы (TXT)", Colors.transparent, Colors.white, () {
                  Navigator.pop(context);
                  _showReport(context, ref);
                }, isGradient: true, enabled: hasWorks || hasMaterials),
              ),

              // 2. Copy
              buildHeader(Icons.copy, "Копирование"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: buildBtn("Заказчик", Colors.green.shade50,
                          Colors.green.shade800, () async {
                        Navigator.pop(context);
                        final project = await ref
                            .read(projectByIdProvider(projectId).future);
                        if (!context.mounted) return;
                        final stageTitle =
                            EstimateReportGenerator.formatStageTitle(
                                stage.title);
                        final title =
                            "${project.address} - Работы - $stageTitle";
                        final text = EstimateReportGenerator.generateReportText(
                            works, title,
                            showPrices: true,
                            quantityType: 'total',
                            note: stage.workRemarks);
                        _copyText(context, text);
                      }, enabled: hasWorks),
                    ),
                    if (hasPartnerWorks) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: buildBtn("Контрагент", Colors.green.shade50,
                            Colors.green.shade800, () async {
                          Navigator.pop(context);
                          final project = await ref
                              .read(projectByIdProvider(projectId).future);
                          if (!context.mounted) return;
                          final stageTitle =
                              EstimateReportGenerator.formatStageTitle(
                                  stage.title);
                          final title =
                              "${project.address} - Работы - $stageTitle - ТВОИ";
                          final text =
                              EstimateReportGenerator.generateReportText(
                                  works, title,
                                  showPrices: true,
                                  quantityType: 'employer',
                                  note: stage.workRemarks);
                          _copyText(context, text);
                        }, enabled: hasWorks),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: buildBtn("Материалы", Colors.blue.shade50,
                          Colors.blue.shade800, () async {
                        Navigator.pop(context);
                        final project = await ref
                            .read(projectByIdProvider(projectId).future);
                        if (!context.mounted) return;
                        final stageTitle =
                            EstimateReportGenerator.formatStageTitle(
                                stage.title);
                        final title =
                            "${project.address} - Материалы - $stageTitle";
                        final text = EstimateReportGenerator.generateReportText(
                            materials, title,
                            showPrices: false,
                            markup: 0,
                            quantityType: 'total',
                            note: stage.materialRemarks);
                        _copyText(context, text);
                      }, enabled: hasMaterials),
                    ),
                  ],
                ),
              ),

              // 3. PDF Export
              buildHeader(Icons.picture_as_pdf, "Экспорт в PDF"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: buildPopupBtn(
                        context,
                        "Работы",
                        Colors.green.shade50,
                        Colors.green.shade800,
                        [
                          const PopupMenuItem(
                              value: 'total', child: Text("Для Заказчика")),
                          if (hasPartnerWorks) ...[
                            const PopupMenuItem(
                                value: 'employer',
                                child: Text("Для Контрагента")),
                            const PopupMenuItem(
                                value: 'our', child: Text("Наши")),
                          ]
                        ],
                        (val) {
                          Navigator.pop(context);
                          if (val == 'total') {
                            _printPdfWithParams(context, ref,
                                isWork: true, type: 'total');
                          } else if (val == 'employer') {
                            _printPdfWithParams(context, ref,
                                isWork: true, type: 'employer');
                          } else if (val == 'our') {
                            _printPdfWithParams(context, ref,
                                isWork: true, type: 'our');
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
                        Colors.blue.shade50,
                        Colors.blue.shade800,
                        [
                          const PopupMenuItem(
                              value: 'noprice', child: Text("Без цен")),
                          if (showPrices) ...[
                            const PopupMenuItem(
                                value: 'price', child: Text("С ценами")),
                            if (markupPercent > 0)
                              PopupMenuItem(
                                  value: 'markup',
                                  child: Text(
                                      "С наценкой (+${markupPercent.toStringAsFixed(0)}%)")),
                          ]
                        ],
                        (val) {
                          Navigator.pop(context);
                          if (val == 'noprice') {
                            _printPdfWithParams(context, ref,
                                isWork: false, showPrices: false);
                          } else if (val == 'price') {
                            _printPdfWithParams(context, ref,
                                isWork: false, showPrices: true);
                          } else if (val == 'markup') {
                            _printPdfWithParams(context, ref,
                                isWork: false,
                                showPrices: true,
                                markup: markupPercent);
                          }
                        },
                        enabled: hasMaterials,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Close Button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Закрыть",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
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

  Future<void> _printPdfWithParams(
    BuildContext context,
    WidgetRef ref, {
    required bool isWork,
    bool showPrices = true,
    double markup = 0,
    String type = 'total',
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
        markupPercent: markup);
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
  }) async {
    try {
      final pdfService = PdfService();
      final bytes = await pdfService.generateEstimatePdf(
        title: title,
        items: items,
        showPrices: showPrices,
        isWork: isWork, // New
        quantityType: quantityType, // New
        remarks: remarks,
        markupPercent: markupPercent,
      );

      // Save to temporary file
      final output = await getTemporaryDirectory();
      // Sanitize title for filename
      final filename = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final file = File("${output.path}/$filename.pdf");
      await file.writeAsBytes(bytes);

      // Open file
      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Не удалось открыть файл: ${result.message}")));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка PDF: $e")));
    }
  }

  Future<void> _showReport(BuildContext context, WidgetRef ref) async {
    try {
      final project = await ref.read(projectByIdProvider(projectId).future);
      final address = project.address;
      final formattedStage =
          EstimateReportGenerator.formatStageTitle(stage.title);

      final List<_ReportTabInfo> tabs = [];

      final matBaseTitle = "$address - Материалы - $formattedStage";
      final workBaseTitle = "$address - Работы - $formattedStage";

      // --- ORDER: Works First, then Materials (V6) ---

      tabs.add(_ReportTabInfo(
          title: "Наши",
          text: EstimateReportGenerator.generateReportText(works, workBaseTitle,
              showPrices: true, quantityType: 'our', note: stage.workRemarks),
          color: Colors.green));

      tabs.add(_ReportTabInfo(
          title: "Контрагент",
          // ADDED: " - ТВОИ" suffix
          text: EstimateReportGenerator.generateReportText(
              works, "$workBaseTitle - ТВОИ",
              showPrices: true,
              quantityType: 'employer',
              note: stage.workRemarks),
          color: Colors.green));

      tabs.add(_ReportTabInfo(
          title: "Заказчик",
          text: EstimateReportGenerator.generateReportText(works, workBaseTitle,
              showPrices: true, quantityType: 'total', note: stage.workRemarks),
          color: Colors.green));

      // 2. MATERIALS
      if (showPrices) {
        // Case 1: With Prices

        // No Prices (Renamed V6: Материал)
        tabs.add(_ReportTabInfo(
            title: "Материал",
            text: EstimateReportGenerator.generateReportText(
                materials, matBaseTitle,
                showPrices: false,
                markup: 0,
                quantityType: 'total',
                note: stage.materialRemarks),
            color: Colors.blue));

        // Base Prices (Renamed V6: Материал с ценами)
        tabs.add(_ReportTabInfo(
            title: "Материал с ценами",
            text: EstimateReportGenerator.generateReportText(
                materials, matBaseTitle,
                showPrices: true,
                markup: 0,
                quantityType: 'total',
                note: stage.materialRemarks),
            color: Colors.blue));

        if (markupPercent > 0) {
          // Renamed V6: Материал с + %
          tabs.add(_ReportTabInfo(
              title: "Материал с + %",
              text: EstimateReportGenerator.generateReportText(
                  materials, matBaseTitle,
                  showPrices: true,
                  markup: markupPercent,
                  quantityType: 'total',
                  note: stage.materialRemarks),
              color: Colors.blue));
        }
      } else {
        // Case 2: Only No Prices
        tabs.add(_ReportTabInfo(
            title: "Материал",
            text: EstimateReportGenerator.generateReportText(
                materials, matBaseTitle,
                showPrices: false,
                markup: 0,
                quantityType: 'total',
                note: stage.materialRemarks),
            color: Colors.blue));
      }

      if (!context.mounted) return;

      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Center(child: Text("Сметы")),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: _ReportDialogContent(tabs: tabs),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    // V7: Black close button
                    style: TextButton.styleFrom(foregroundColor: Colors.black),
                    child: const Text("Закрыть"))
              ],
            );
          });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка подготовки отчета: $e")));
    }
  }
}

class _ReportTabInfo {
  final String title;
  final String text;
  final MaterialColor color;

  _ReportTabInfo(
      {required this.title, required this.text, required this.color});
}

class _ReportDialogContent extends StatefulWidget {
  final List<_ReportTabInfo> tabs;

  const _ReportDialogContent({required this.tabs});

  @override
  State<_ReportDialogContent> createState() => _ReportDialogContentState();
}

class _ReportDialogContentState extends State<_ReportDialogContent> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentTab = widget.tabs[_currentIndex];
    final activeColor = currentTab.color;

    return Column(
      children: [
        // Navigation: Wrap with Chips instead of TabBar
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center, // Center chips
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(widget.tabs.length, (index) {
              final tab = widget.tabs[index];
              final isSelected = index == _currentIndex;
              // Use color from the tab
              final color = tab.color;

              return ChoiceChip(
                label: Text(tab.title),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _currentIndex = index);
                  }
                },
                // V6 & V7: Pastel styling & Colored unselected
                selectedColor: color
                    .shade100, // Slightly darker for selected to distinguish
                backgroundColor: color
                    .withOpacity(0.15), // V7.1: Increased saturation (was 0.05)
                labelStyle: TextStyle(
                  color: isSelected ? color.shade900 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                // V6: Thinner border
                side: BorderSide(
                  color: isSelected ? color.shade300 : Colors.grey.shade300,
                  width: 0.5,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        // V7: Colored divider
        Divider(
            color: activeColor.shade200,
            thickness: 1), // V7.1: Increased saturation (was shade100)
        const SizedBox(height: 8),

        // Content
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: SelectableText(currentTab.text,
                  style: const TextStyle(
                      fontSize: 13, fontFamily: 'Courier', height: 1.2)),
            ),
          ),
        ),

        const SizedBox(height: 12),
        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: currentTab.text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("Скопировано!")));
            },
            icon: const Icon(Icons.copy, size: 18),
            // V6: Removed "отчет"
            label: Text("Копировать (${currentTab.title})"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: activeColor.shade50,
              foregroundColor: activeColor.shade800,
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
