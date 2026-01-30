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
  Widget buildHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700)),
        ],
      ),
    );
  }

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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text("Текстовые действия",
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

            // 2. Copy Text
            buildHeader(Icons.copy, "Копировать текст"),
            _buildActionSection(context, ref, hasWorks, hasPartnerWorks,
                hasMaterials, false), // share = false

            // 3. Share Text (NEW)
            buildHeader(Icons.share, "Поделиться текстом"),
            _buildActionSection(context, ref, hasWorks, hasPartnerWorks,
                hasMaterials, true), // share = true

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
    );
  }

  Widget _buildActionSection(BuildContext context, WidgetRef ref, bool hasWorks,
      bool hasPartnerWorks, bool hasMaterials, bool share) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: buildBtn(
                "Заказчик", Colors.green.shade50, Colors.green.shade800,
                () async {
              Navigator.pop(context);
              await _processAction(context, ref, true, 'total', false, share);
            }, enabled: hasWorks),
          ),
          if (hasPartnerWorks) ...[
            const SizedBox(width: 8),
            Expanded(
              child: buildBtn(
                  "Контрагент", Colors.green.shade50, Colors.green.shade800,
                  () async {
                Navigator.pop(context);
                await _processAction(
                    context, ref, true, 'employer', false, share);
              }, enabled: hasWorks),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child:
                buildBtn("Материалы", Colors.blue.shade50, Colors.blue.shade800,
                    () async {
              Navigator.pop(context);
              await _processAction(context, ref, false, 'total', true, share);
            }, enabled: hasMaterials),
          ),
        ],
      ),
    );
  }

  Future<void> _processAction(BuildContext context, WidgetRef ref, bool isWork,
      String type, bool isMaterial, bool share) async {
    final project = await ref.read(projectByIdProvider(projectId).future);
    if (!context.mounted) return;

    // Construct Text
    String text = "";
    final stageTitle = EstimateReportGenerator.formatStageTitle(stage.title);

    if (isWork) {
      String titleType = (type == 'employer') ? "Работы (Ты)" : "Работы";
      final title = "${project.address} - $titleType - $stageTitle";
      final quantityType = type; // 'total' or 'employer'

      text = EstimateReportGenerator.generateReportText(works, title,
          showPrices: true,
          quantityType: quantityType,
          note: stage.workRemarks);
    } else {
      final title = "${project.address} - Материалы - $stageTitle";
      text = EstimateReportGenerator.generateReportText(
        materials,
        title,
        showPrices: showPrices,
        markup: markupPercent > 0
            ? markupPercent
            : 0, // Renamed markupPercent to markup
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

  Future<void> _showReport(BuildContext context, WidgetRef ref) async {
    final project = await ref.read(projectByIdProvider(projectId).future);
    if (!context.mounted) return;

    // Manually generate full report
    final stageTitle = EstimateReportGenerator.formatStageTitle(stage.title);
    final StringBuffer buffer = StringBuffer();

    // Works Part
    if (works.isNotEmpty) {
      final workTitle = "${project.address} - Работы - $stageTitle";
      final workText = EstimateReportGenerator.generateReportText(
          works, workTitle,
          showPrices: true, // Works always show prices in full report usually
          quantityType: 'total',
          note: stage.workRemarks);
      buffer.writeln(workText);
      buffer.writeln("\n\n");
    }

    // Materials Part
    if (materials.isNotEmpty) {
      final matTitle = "${project.address} - Материалы - $stageTitle";
      final matText = EstimateReportGenerator.generateReportText(
          materials, matTitle,
          showPrices: showPrices,
          markup: markupPercent,
          quantityType: 'total',
          note: stage.materialRemarks);
      buffer.writeln(matText);
    }

    final text = buffer.toString();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          height: 800,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Предварительный просмотр",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close))
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(text,
                        style: const TextStyle(fontFamily: 'RobotoMono')),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Share Full Report button? Maybe later.
                  ElevatedButton.icon(
                    onPressed: () => _copyText(context, text),
                    icon: const Icon(Icons.copy),
                    label: const Text("Копировать"),
                  ),
                ],
              ),
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text("PDF Действия",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ),
            ),

            // 1. Export PDF
            buildHeader(Icons.picture_as_pdf, "Экспорт в PDF"),
            _buildPdfSection(context, ref, hasWorks, hasPartnerWorks,
                hasMaterials, false), // share = false

            // 2. Share PDF
            buildHeader(Icons.share, "Поделиться PDF"),
            _buildPdfSection(context, ref, hasWorks, hasPartnerWorks,
                hasMaterials, true), // share = true

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
              Colors.green.shade50,
              Colors.green.shade800,
              [
                const PopupMenuItem(
                    value: 'total', child: Text("Для Заказчика")),
                if (hasPartnerWorks) ...[
                  const PopupMenuItem(
                      value: 'employer', child: Text("Для Контрагента")),
                  const PopupMenuItem(value: 'our', child: Text("Наши")),
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
              Colors.blue.shade50,
              Colors.blue.shade800,
              [
                const PopupMenuItem(value: 'noprice', child: Text("Без цен")),
                if (showPrices) ...[
                  const PopupMenuItem(value: 'price', child: Text("С ценами")),
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
