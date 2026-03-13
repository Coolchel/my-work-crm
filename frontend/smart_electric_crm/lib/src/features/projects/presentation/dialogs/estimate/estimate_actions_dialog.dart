import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_dialog_scrollbar.dart';
import 'package:smart_electric_crm/src/shared/presentation/utils/error_feedback.dart';
import 'package:smart_electric_crm/src/shared/services/temp_file_service.dart';

import '../../../data/models/estimate_item_model.dart';
import '../../../data/models/stage_model.dart';
import '../../providers/project_providers.dart';
import '../../../services/project_file_browser_bridge.dart';
import '../../../services/project_file_save_service.dart';
import '../../utils/estimate_report_generator.dart';
import '../../../services/pdf_service.dart';

// --- SHARED HELPERS & MIXINS ---

mixin EstimateDialogHelpers {
  bool get _isTouchPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return true;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }

  /// Builds the main dialog container with premium styling
  Widget buildPremiumContainer({
    required BuildContext context,
    required Color themeColor,
    required Widget child,
    double maxWidth = 420,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height - 32,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  /// Builds the dialog header with title and close button
  Widget buildPremiumHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color themeColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: themeColor.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: themeColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                height: 1.2,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
            tooltip: 'Закрыть',
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a section header label/title
  Widget buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a standard wide action button (Secondary/Outlined style)
  Widget buildWideActionBtn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: SizedBox(
        height: 52,
        child: OutlinedButton(
          onPressed: enabled ? onTap : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: effectiveColor,
            side: BorderSide(color: effectiveColor.withOpacity(0.25)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: effectiveColor.withOpacity(0.03),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            splashFactory: _isTouchPlatform
                ? InkRipple.splashFactory
                : InkSparkle.splashFactory,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: effectiveColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a premium dropdown-style menu button
  Widget buildMenuBtn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required List<PopupMenuEntry<String>> items,
    required ValueChanged<String> onSelected,
    Color? color,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final isDark = AppDesignTokens.isDark(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;
    final contentColor = enabled ? effectiveColor : theme.disabledColor;
    final menuHoverColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.045);
    final triggerHoverColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);

    final triggerContent = Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: contentColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: contentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: contentColor.withOpacity(0.7),
            size: 24,
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final menuWidth = constraints.maxWidth;
          return TooltipVisibility(
            visible: false,
            child: Theme(
              data: theme.copyWith(
                hoverColor: menuHoverColor,
                highlightColor: menuHoverColor,
                splashColor: menuHoverColor,
                popupMenuTheme: theme.popupMenuTheme.copyWith(
                  color: theme.colorScheme.surfaceContainer,
                  surfaceTintColor: Colors.transparent,
                ),
              ),
              child: PopupMenuButton<String>(
                enabled: enabled,
                tooltip: '',
                padding: EdgeInsets.zero,
                menuPadding: EdgeInsets.zero,
                onSelected: onSelected,
                itemBuilder: (context) => items,
                offset: const Offset(0, 56), // Show menu below button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                elevation: 3,
                shadowColor: Colors.black.withOpacity(0.2),
                splashRadius: 24,
                position: _isTouchPlatform
                    ? PopupMenuPosition.under
                    : PopupMenuPosition.over,
                constraints: BoxConstraints(
                  minWidth: menuWidth,
                  maxWidth: menuWidth,
                ),
                child: Opacity(
                  opacity: enabled ? 1.0 : 0.6,
                  child: _isTouchPlatform
                      ? triggerContent
                      : _HoverableMenuTrigger(
                          enabled: enabled,
                          hoverColor: triggerHoverColor,
                          borderRadius: BorderRadius.circular(14),
                          child: triggerContent,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Helper for building standard popup menu items with icon and checkmark support
  PopupMenuItem<String> buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> buildPopupMenuItemsWithDividers(
    List<PopupMenuItem<String>> items,
  ) {
    final entries = <PopupMenuEntry<String>>[];
    for (var index = 0; index < items.length; index++) {
      if (index > 0) {
        entries.add(const PopupMenuDivider(height: 1));
      }
      entries.add(items[index]);
    }
    return entries;
  }
}

class _HoverableMenuTrigger extends StatefulWidget {
  final Widget child;
  final Color hoverColor;
  final BorderRadius borderRadius;
  final bool enabled;

  const _HoverableMenuTrigger({
    required this.child,
    required this.hoverColor,
    required this.borderRadius,
    required this.enabled,
  });

  @override
  State<_HoverableMenuTrigger> createState() => _HoverableMenuTriggerState();
}

class _HoverableMenuTriggerState extends State<_HoverableMenuTrigger> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        child: Container(
          foregroundDecoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : Colors.transparent,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// --- TEXT ACTIONS DIALOG ---

enum EstimateTextDeliveryMode { copy, save, share }

class EstimateTextDocument {
  const EstimateTextDocument({
    required this.viewMode,
    required this.text,
    required this.fileName,
    required this.themeColor,
  });

  final String viewMode;
  final String text;
  final String fileName;
  final MaterialColor themeColor;
}

class EstimateTextDocumentBuilder {
  static List<String> availableModes({
    required List<EstimateItemModel> works,
    required List<EstimateItemModel> materials,
    required bool showPrices,
    required double markupPercent,
  }) {
    final modes = <String>[];
    final hasPartnerWorks = works.any((w) => w.employerQuantity > 0);
    if (works.isNotEmpty) {
      modes.add('work_total');
      if (hasPartnerWorks) {
        modes.add('work_employer');
      }
      modes.add('work_our');
    }
    if (materials.isNotEmpty) {
      modes.add('mat_noprice');
      if (showPrices) {
        modes.add('mat_price');
        if (markupPercent > 0) {
          modes.add('mat_markup');
        }
      }
    }
    return modes;
  }

  static EstimateTextDocument fromActionSelection({
    required bool isWork,
    required String type,
    required String? projectAddress,
    required StageModel stage,
    required List<EstimateItemModel> works,
    required List<EstimateItemModel> materials,
    required bool showPrices,
    required double markupPercent,
  }) {
    final viewMode = switch ((isWork, type)) {
      (true, 'employer') => 'work_employer',
      (true, 'our') => 'work_our',
      (true, _) => 'work_total',
      (false, 'price') => 'mat_price',
      (false, 'markup') => 'mat_markup',
      (false, _) => 'mat_noprice',
    };

    return fromViewMode(
      viewMode: viewMode,
      projectAddress: projectAddress,
      stage: stage,
      works: works,
      materials: materials,
      showPrices: showPrices,
      markupPercent: markupPercent,
    );
  }

  static EstimateTextDocument fromViewMode({
    required String viewMode,
    required String? projectAddress,
    required StageModel stage,
    required List<EstimateItemModel> works,
    required List<EstimateItemModel> materials,
    required bool showPrices,
    required double markupPercent,
  }) {
    final stageTitle = EstimateReportGenerator.formatStageTitle(stage.title);
    final address = projectAddress ?? 'Адрес не указан';

    switch (viewMode) {
      case 'work_total':
        return EstimateTextDocument(
          viewMode: viewMode,
          text: EstimateReportGenerator.generateReportText(
            works,
            '$address - Работы - $stageTitle',
            showPrices: true,
            quantityType: 'total',
            note: stage.workRemarks,
          ),
          fileName: '$address - Работы - $stageTitle.txt',
          themeColor: Colors.green,
        );
      case 'work_employer':
        return EstimateTextDocument(
          viewMode: viewMode,
          text: EstimateReportGenerator.generateReportText(
            works,
            '$address - Работы (ТВОИ) - $stageTitle',
            showPrices: true,
            quantityType: 'employer',
            note: stage.workRemarks,
          ),
          fileName: '$address - Работы (ТВОИ) - $stageTitle.txt',
          themeColor: Colors.green,
        );
      case 'work_our':
        return EstimateTextDocument(
          viewMode: viewMode,
          text: EstimateReportGenerator.generateReportText(
            works,
            '$address - Работы (НАШИ) - $stageTitle',
            showPrices: true,
            quantityType: 'our',
            note: stage.workRemarks,
          ),
          fileName: '$address - Работы (НАШИ) - $stageTitle.txt',
          themeColor: Colors.green,
        );
      case 'mat_price':
        return EstimateTextDocument(
          viewMode: viewMode,
          text: EstimateReportGenerator.generateReportText(
            materials,
            '$address - Материалы - $stageTitle',
            showPrices: true,
            markup: 0,
            quantityType: 'total',
            note: stage.materialRemarks,
          ),
          fileName: '$address - Материалы - $stageTitle.txt',
          themeColor: Colors.blue,
        );
      case 'mat_markup':
        return EstimateTextDocument(
          viewMode: viewMode,
          text: EstimateReportGenerator.generateReportText(
            materials,
            '$address - Материалы - $stageTitle',
            showPrices: true,
            markup: markupPercent,
            quantityType: 'total',
            note: stage.materialRemarks,
          ),
          fileName: '$address - Материалы - $stageTitle.txt',
          themeColor: Colors.blue,
        );
      case 'mat_noprice':
      default:
        return EstimateTextDocument(
          viewMode: viewMode,
          text: EstimateReportGenerator.generateReportText(
            materials,
            '$address - Материалы - $stageTitle',
            showPrices: false,
            markup: 0,
            quantityType: 'total',
            note: stage.materialRemarks,
          ),
          fileName: '$address - Материалы - $stageTitle.txt',
          themeColor: Colors.blue,
        );
    }
  }
}

class EstimateTextActionHandler {
  EstimateTextActionHandler({
    ProjectFileSaveService? fileSaveService,
  }) : _fileSaveService = fileSaveService ?? ProjectFileSaveService();

  final ProjectFileSaveService _fileSaveService;

  static bool get supportsFileShare =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.windows);

  static bool get showsShareSection => !kIsWeb;

  static String get shareSectionTitle =>
      supportsFileShare ? 'Поделиться файлом' : 'Поделиться текстом';

  static String get downloadSectionTitle => 'Скачать TXT';

  Future<void> copyText(
    BuildContext context,
    EstimateTextDocument document,
  ) async {
    try {
      if (kIsWeb) {
        await copyTextInBrowser(document.text);
      } else {
        await Clipboard.setData(ClipboardData(text: document.text));
      }

      if (!context.mounted) {
        return;
      }

      await ErrorFeedback.showMessage(
        context,
        'Текст сметы скопирован в буфер обмена.',
        title: 'TXT',
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      await ErrorFeedback.showMessage(
        context,
        'Не удалось скопировать текст сметы в буфер обмена.',
        title: 'TXT',
      );
    }
  }

  Future<void> saveText(
    BuildContext context,
    EstimateTextDocument document,
  ) async {
    final result = await _fileSaveService.saveBytes(
      bytes: Uint8List.fromList(utf8.encode(document.text)),
      displayName: ProjectFileSaveService.sanitizeFileName(
        document.fileName,
        fallback: 'estimate.txt',
      ),
    );

    if (!context.mounted || result.isCancelled) {
      return;
    }

    if (kIsWeb && result.isSaved) {
      return;
    }

    await ErrorFeedback.showMessage(
      context,
      result.message,
      title: 'TXT',
    );
  }

  Future<void> shareText(
    BuildContext context,
    EstimateTextDocument document,
  ) async {
    try {
      if (supportsFileShare) {
        final shareFile = await _buildShareFile(document);
        if (defaultTargetPlatform == TargetPlatform.android) {
          await SharePlus.instance.share(
            ShareParams(
              files: [shareFile],
            ),
          );
          return;
        }

        await SharePlus.instance.share(
          ShareParams(
            files: [shareFile],
            fileNameOverrides: [
              ProjectFileSaveService.sanitizeFileName(
                document.fileName,
                fallback: 'estimate.txt',
              ),
            ],
          ),
        );
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          text: document.text,
          subject: document.fileName,
          title: document.fileName,
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      await ErrorFeedback.showMessage(
        context,
        'Не удалось выполнить отправку текстовой сметы.',
        title: 'TXT',
      );
    }
  }

  Future<XFile> _buildShareFile(EstimateTextDocument document) async {
    final file = await _createTempTextFile(document);
    if (defaultTargetPlatform == TargetPlatform.android) {
      return XFile(
        file.path,
        mimeType: 'application/octet-stream',
      );
    }
    return XFile(file.path, mimeType: 'text/plain');
  }

  Future<File> _createTempTextFile(EstimateTextDocument document) async {
    final output = await getTemporaryDirectory();
    final fileName = ProjectFileSaveService.sanitizeFileName(
      document.fileName,
      fallback: 'estimate.txt',
    );
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(
      Uint8List.fromList(utf8.encode(document.text)),
      flush: true,
    );
    TempFileService().track(file);
    return file;
  }
}

class EstimateTextActionsDialog extends ConsumerWidget
    with EstimateDialogHelpers {
  final String projectId;
  final StageModel stage;
  final List<EstimateItemModel> works;
  final List<EstimateItemModel> materials;
  final bool showPrices;
  final double markupPercent;
  final EstimateTextActionHandler _textActionHandler =
      EstimateTextActionHandler();

  EstimateTextActionsDialog({
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
    // Determine enabled states based on data presence
    final hasWorks = works.isNotEmpty;
    final hasMaterials = materials.isNotEmpty;
    final hasPartnerWorks = works.any((w) => w.employerQuantity > 0);
    final hasTextActions = hasWorks || hasMaterials;
    final showShareSection =
        hasTextActions && EstimateTextActionHandler.showsShareSection;
    final downloadBeforeShare = EstimateTextActionHandler.supportsFileShare;
    const themeColor = Colors.blueGrey; // Neutral theme for dialog logic

    return buildPremiumContainer(
      context: context,
      themeColor: themeColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildPremiumHeader(
            context: context,
            title: "Текстовые сметы",
            icon: Icons.description_outlined,
            themeColor: themeColor,
          ),
          Flexible(
            child: AppDialogScrollbar.builder(
              builder: (scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildSectionHeader(
                      "Просмотр",
                      icon: Icons.remove_red_eye_rounded,
                    ),
                    buildWideActionBtn(
                      context,
                      label: "Открыть предпросмотр",
                      icon: Icons.fullscreen_rounded,
                      color: Colors.grey.shade800,
                      onTap: (hasWorks || hasMaterials)
                          ? () {
                              final rootContext =
                                  Navigator.of(context, rootNavigator: true)
                                      .context;
                              Navigator.pop(context);
                              _showReport(rootContext, ref);
                            }
                          : () {},
                    ),
                    if (hasTextActions)
                      buildSectionHeader(
                        "Копировать текст",
                        icon: Icons.copy_rounded,
                      ),
                    _buildTextDeliverySection(
                      context,
                      ref,
                      hasWorks,
                      hasPartnerWorks,
                      hasMaterials,
                      deliveryMode: EstimateTextDeliveryMode.copy,
                    ),
                    if (downloadBeforeShare && hasTextActions)
                      buildSectionHeader(
                        EstimateTextActionHandler.downloadSectionTitle,
                        icon: Icons.download_rounded,
                      ),
                    if (downloadBeforeShare)
                      _buildTextDeliverySection(
                        context,
                        ref,
                        hasWorks,
                        hasPartnerWorks,
                        hasMaterials,
                        deliveryMode: EstimateTextDeliveryMode.save,
                      ),
                    if (showShareSection)
                      buildSectionHeader(
                        EstimateTextActionHandler.shareSectionTitle,
                        icon: Icons.share_rounded,
                      ),
                    if (showShareSection)
                      _buildTextDeliverySection(
                        context,
                        ref,
                        hasWorks,
                        hasPartnerWorks,
                        hasMaterials,
                        deliveryMode: EstimateTextDeliveryMode.share,
                      ),
                    if (!downloadBeforeShare && hasTextActions)
                      buildSectionHeader(
                        EstimateTextActionHandler.downloadSectionTitle,
                        icon: Icons.download_rounded,
                      ),
                    if (!downloadBeforeShare)
                      _buildTextDeliverySection(
                        context,
                        ref,
                        hasWorks,
                        hasPartnerWorks,
                        hasMaterials,
                        deliveryMode: EstimateTextDeliveryMode.save,
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextDeliverySection(BuildContext context, WidgetRef ref,
      bool hasWorks, bool hasPartnerWorks, bool hasMaterials,
      {required EstimateTextDeliveryMode deliveryMode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasWorks)
          buildMenuBtn(
            context,
            label: "Работы",
            icon: Icons.work_outline,
            color: Colors.green,
            items: buildPopupMenuItemsWithDividers([
              buildPopupMenuItem(
                value: 'total',
                icon: Icons.person_rounded,
                text: "Для Заказчика",
                color: Colors.green,
              ),
              if (hasPartnerWorks)
                buildPopupMenuItem(
                  value: 'employer',
                  icon: Icons.handshake_rounded,
                  text: "Для Контрагента",
                  color: Colors.green,
                ),
              if (hasPartnerWorks)
                buildPopupMenuItem(
                  value: 'our',
                  icon: Icons.engineering_rounded,
                  text: "Наши (Остаток)",
                  color: Colors.green,
                ),
            ]),
            onSelected: (val) async {
              final rootContext =
                  Navigator.of(context, rootNavigator: true).context;
              Navigator.pop(context);
              await _processAction(
                rootContext,
                ref,
                isWork: true,
                type: val,
                deliveryMode: deliveryMode,
              );
            },
          ),
        if (hasMaterials)
          buildMenuBtn(
            context,
            label: "Материалы",
            icon: Icons.inventory_2_outlined,
            color: Colors.blue.shade700,
            items: buildPopupMenuItemsWithDividers([
              buildPopupMenuItem(
                value: 'noprice',
                icon: Icons.list_alt_rounded,
                text: "Без цен",
                color: Colors.blue.shade700,
              ),
              buildPopupMenuItem(
                value: 'price',
                icon: Icons.attach_money_rounded,
                text: "С ценами",
                color: Colors.blue.shade700,
              ),
              if (markupPercent > 0)
                buildPopupMenuItem(
                  value: 'markup',
                  icon: Icons.trending_up_rounded,
                  text: "С наценкой (+${markupPercent.toStringAsFixed(0)}%)",
                  color: Colors.blue.shade700,
                ),
            ]),
            onSelected: (val) async {
              final rootContext =
                  Navigator.of(context, rootNavigator: true).context;
              Navigator.pop(context);
              await _processAction(
                rootContext,
                ref,
                isWork: false,
                type: val,
                deliveryMode: deliveryMode,
              );
            },
          ),
      ],
    );
  }

  /// Handles report generation and action (copy/share/save)
  Future<void> _processAction(BuildContext context, WidgetRef ref,
      {required bool isWork,
      required String type,
      required EstimateTextDeliveryMode deliveryMode}) async {
    final project = await ref.read(projectByIdProvider(projectId).future);
    if (!context.mounted) return;

    final document = EstimateTextDocumentBuilder.fromActionSelection(
      isWork: isWork,
      type: type,
      projectAddress: project.address as String?,
      stage: stage,
      works: works,
      materials: materials,
      showPrices: showPrices,
      markupPercent: markupPercent,
    );

    switch (deliveryMode) {
      case EstimateTextDeliveryMode.copy:
        await _textActionHandler.copyText(context, document);
        break;
      case EstimateTextDeliveryMode.save:
        await _textActionHandler.saveText(context, document);
        break;
      case EstimateTextDeliveryMode.share:
        await _textActionHandler.shareText(context, document);
        break;
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
}

// --- PDF ACTIONS DIALOG ---

enum EstimatePdfDeliveryMode { open, download, share }

class EstimatePdfActionRequest {
  final bool isWork;
  final bool showPrices;
  final double markup;
  final String type;
  final EstimatePdfDeliveryMode deliveryMode;

  const EstimatePdfActionRequest({
    required this.isWork,
    this.showPrices = true,
    this.markup = 0.0,
    this.type = 'total',
    this.deliveryMode = EstimatePdfDeliveryMode.open,
  });

  bool get share => deliveryMode == EstimatePdfDeliveryMode.share;
  bool get download => deliveryMode == EstimatePdfDeliveryMode.download;
}

class EstimatePdfActionsDialog extends ConsumerStatefulWidget {
  final String projectId;
  final StageModel stage;
  final List<EstimateItemModel> works;
  final List<EstimateItemModel> materials;
  final bool showPrices;
  final double markupPercent;
  final Future<void> Function(EstimatePdfActionRequest request)?
      onExecuteAction;

  const EstimatePdfActionsDialog({
    super.key,
    required this.projectId,
    required this.stage,
    required this.works,
    required this.materials,
    required this.showPrices,
    required this.markupPercent,
    this.onExecuteAction,
  });

  @override
  ConsumerState<EstimatePdfActionsDialog> createState() =>
      _EstimatePdfActionsDialogState();
}

class _EstimatePdfActionsDialogState
    extends ConsumerState<EstimatePdfActionsDialog> with EstimateDialogHelpers {
  bool _isBusy = false;
  final ProjectFileSaveService _fileSaveService = ProjectFileSaveService();

  bool get _showsPdfNativeDownloadMenu =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Widget build(BuildContext context) {
    final hasWorks = widget.works.isNotEmpty;
    final hasMaterials = widget.materials.isNotEmpty;
    final hasPartnerWorks = widget.works.any((w) => w.employerQuantity > 0);
    const themeColor = Colors.blueGrey;

    return buildPremiumContainer(
      context: context,
      themeColor: themeColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildPremiumHeader(
            context: context,
            title: "PDF сметы",
            icon: Icons.picture_as_pdf_outlined,
            themeColor: themeColor,
          ),
          Flexible(
            child: AppDialogScrollbar.builder(
              builder: (scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildSectionHeader(
                      "Открыть в PDF",
                      icon: Icons.open_in_new_rounded,
                    ),
                    _buildPdfDeliverySection(
                      context,
                      hasWorks,
                      hasPartnerWorks,
                      hasMaterials,
                      deliveryMode: EstimatePdfDeliveryMode.open,
                    ),
                    if (kIsWeb) ...[
                      buildSectionHeader(
                        "Скачать PDF",
                        icon: Icons.download_rounded,
                      ),
                      _buildPdfDeliverySection(
                        context,
                        hasWorks,
                        hasPartnerWorks,
                        hasMaterials,
                        deliveryMode: EstimatePdfDeliveryMode.download,
                      ),
                    ],
                    if (_showsPdfNativeDownloadMenu) ...[
                      buildSectionHeader(
                        "Скачать PDF",
                        icon: Icons.download_rounded,
                      ),
                      _buildPdfDeliverySection(
                        context,
                        hasWorks,
                        hasPartnerWorks,
                        hasMaterials,
                        deliveryMode: EstimatePdfDeliveryMode.download,
                      ),
                    ],
                    if (!kIsWeb) ...[
                      buildSectionHeader(
                        "Поделиться PDF",
                        icon: Icons.share_rounded,
                      ),
                      _buildPdfDeliverySection(
                        context,
                        hasWorks,
                        hasPartnerWorks,
                        hasMaterials,
                        deliveryMode: EstimatePdfDeliveryMode.share,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfDeliverySection(
    BuildContext context,
    bool hasWorks,
    bool hasPartnerWorks,
    bool hasMaterials, {
    required EstimatePdfDeliveryMode deliveryMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasWorks)
          buildMenuBtn(
            context,
            label: "Работы",
            icon: Icons.work_outline,
            color: Colors.green,
            enabled: !_isBusy,
            items: buildPopupMenuItemsWithDividers([
              buildPopupMenuItem(
                value: 'total',
                icon: Icons.person_rounded,
                text: "Для Заказчика",
                color: Colors.green,
              ),
              if (hasPartnerWorks)
                buildPopupMenuItem(
                  value: 'employer',
                  icon: Icons.handshake_rounded,
                  text: "Для Контрагента",
                  color: Colors.green,
                ),
              if (hasPartnerWorks)
                buildPopupMenuItem(
                  value: 'our',
                  icon: Icons.engineering_rounded,
                  text: "Наши (Остаток)",
                  color: Colors.green,
                ),
            ]),
            onSelected: (val) => _runPdfAction(
              Navigator.of(context, rootNavigator: true).context,
              EstimatePdfActionRequest(
                isWork: true,
                type: val,
                deliveryMode: deliveryMode,
              ),
            ),
          ),
        if (hasMaterials)
          buildMenuBtn(
            context,
            label: "Материалы",
            icon: Icons.inventory_2_outlined,
            color: Colors.blue.shade700,
            enabled: !_isBusy,
            items: buildPopupMenuItemsWithDividers([
              buildPopupMenuItem(
                value: 'noprice',
                icon: Icons.list_alt_rounded,
                text: "Без цен",
                color: Colors.blue.shade700,
              ),
              buildPopupMenuItem(
                value: 'price',
                icon: Icons.attach_money_rounded,
                text: "С ценами",
                color: Colors.blue.shade700,
              ),
              if (widget.markupPercent > 0)
                buildPopupMenuItem(
                  value: 'markup',
                  icon: Icons.trending_up_rounded,
                  text:
                      "С наценкой (+${widget.markupPercent.toStringAsFixed(0)}%)",
                  color: Colors.blue.shade700,
                ),
            ]),
            onSelected: (val) {
              if (val == 'noprice') {
                _runPdfAction(
                  Navigator.of(context, rootNavigator: true).context,
                  EstimatePdfActionRequest(
                    isWork: false,
                    showPrices: false,
                    deliveryMode: deliveryMode,
                  ),
                );
              } else if (val == 'price') {
                _runPdfAction(
                  Navigator.of(context, rootNavigator: true).context,
                  EstimatePdfActionRequest(
                    isWork: false,
                    showPrices: true,
                    deliveryMode: deliveryMode,
                  ),
                );
              } else if (val == 'markup') {
                _runPdfAction(
                  Navigator.of(context, rootNavigator: true).context,
                  EstimatePdfActionRequest(
                    isWork: false,
                    showPrices: true,
                    markup: widget.markupPercent,
                    deliveryMode: deliveryMode,
                  ),
                );
              }
            },
          ),
      ],
    );
  }

  Future<void> _runPdfAction(
      BuildContext context, EstimatePdfActionRequest request) async {
    if (_isBusy) return;
    final dialogContext = mounted ? this.context : null;
    if (dialogContext != null && Navigator.of(dialogContext).canPop()) {
      Navigator.of(dialogContext).pop();
    }
    if (mounted) {
      setState(() => _isBusy = true);
    }
    try {
      if (widget.onExecuteAction != null) {
        await widget.onExecuteAction!(request);
      } else {
        await _printPdfWithParams(context, request: request);
      }
    } catch (e, st) {
      if (context.mounted) {
        debugPrint('EstimatePdfActionsDialog._runPdfAction failed: $e\n$st');
        ErrorFeedback.showSnackBar(
          context,
          e,
          fallbackMessage: 'Не удалось выполнить операцию с PDF.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _printPdfWithParams(
    BuildContext context, {
    required EstimatePdfActionRequest request,
  }) async {
    final items = request.isWork ? widget.works : widget.materials;
    String titleType = request.isWork ? "Работы" : "Материалы";
    String titleSuffix = "";
    if (request.type == 'employer') titleSuffix = " - ТВОИ";
    if (request.type == 'our') titleSuffix = " - НАШИ";

    final project =
        await ref.read(projectByIdProvider(widget.projectId).future);
    if (!context.mounted) return;
    final stageTitle =
        EstimateReportGenerator.formatStageTitle(widget.stage.title);
    final title = "${project.address} - $titleType - $stageTitle$titleSuffix";
    final remarks = request.isWork
        ? widget.stage.workRemarks
        : widget.stage.materialRemarks;

    await _printPdf(
      context: context,
      items: items,
      title: title,
      showPrices: request.showPrices,
      isWork: request.isWork,
      quantityType: request.type,
      remarks: remarks,
      markupPercent: request.markup,
      deliveryMode: request.deliveryMode,
    );
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
    EstimatePdfDeliveryMode deliveryMode = EstimatePdfDeliveryMode.open,
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

      final fileName =
          '${ProjectFileSaveService.sanitizeFileName(title, fallback: 'estimate')}.pdf';
      if (!context.mounted) {
        return;
      }

      switch (deliveryMode) {
        case EstimatePdfDeliveryMode.open:
          await _openPdf(
            context,
            bytes: bytes,
            fileName: fileName,
          );
          return;
        case EstimatePdfDeliveryMode.download:
          await _downloadPdf(
            context,
            bytes: bytes,
            fileName: fileName,
          );
          return;
        case EstimatePdfDeliveryMode.share:
          if (kIsWeb) {
            await _downloadPdf(
              context,
              bytes: bytes,
              fileName: fileName,
            );
            return;
          }
          await _sharePdf(
            context,
            bytes: bytes,
            fileName: fileName,
            title: title,
          );
          return;
      }
    } catch (e, st) {
      if (context.mounted) {
        debugPrint('EstimatePdfActionsDialog._printPdf failed: $e\n$st');
        ErrorFeedback.showSnackBar(
          context,
          e,
          fallbackMessage: 'Не удалось сформировать PDF.',
        );
      }
    }
  }

  Future<void> _openPdf(
    BuildContext context, {
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      await openBytesInBrowser(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );
      return;
    }

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(bytes, flush: true);

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done && context.mounted) {
      ErrorFeedback.showSnackBarMessage(
        context,
        'Не удалось открыть файл: ${result.message}',
      );
    }
  }

  Future<void> _downloadPdf(
    BuildContext context, {
    required Uint8List bytes,
    required String fileName,
  }) async {
    final result = await _fileSaveService.saveBytes(
      bytes: bytes,
      displayName: fileName,
    );
    if (!context.mounted || result.isCancelled) {
      return;
    }

    if (kIsWeb && result.isSaved) {
      return;
    }

    ErrorFeedback.showSnackBarMessage(
      context,
      result.message,
    );
  }

  Future<void> _sharePdf(
    BuildContext context, {
    required Uint8List bytes,
    required String fileName,
    required String title,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: title,
          text: title,
          title: title,
          fileNameOverrides: [fileName],
        ),
      );
      return;
    }

    final didShare = await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
      subject: title,
      body: title,
    );

    if (didShare || !context.mounted) {
      return;
    }

    if (!kIsWeb) {
      ErrorFeedback.showSnackBarMessage(
        context,
        'Не удалось открыть системное меню шаринга PDF.',
      );
      return;
    }

    final saveResult = await _fileSaveService.saveBytes(
      bytes: bytes,
      displayName: fileName,
    );
    if (!context.mounted) {
      return;
    }

    final message = saveResult.isSaved
        ? 'Браузер не поддержал шаринг PDF. Файл передан браузеру для сохранения, после чего им можно поделиться вручную.'
        : saveResult.message;
    ErrorFeedback.showSnackBarMessage(
      context,
      message,
    );
  }
}

// --- REPORT PREVIEW DIALOG (UNCHANGED / MINIMAL POLISH) ---

class ReportPreviewDialog extends StatefulWidget {
  final dynamic project;
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
  final ScrollController _previewScrollController = ScrollController();
  final EstimateTextActionHandler _textActionHandler =
      EstimateTextActionHandler();
  late String _viewMode;

  List<String> get _availableModes {
    return EstimateTextDocumentBuilder.availableModes(
      works: widget.works,
      materials: widget.materials,
      showPrices: widget.showPrices,
      markupPercent: widget.markupPercent,
    );
  }

  @override
  void initState() {
    super.initState();
    final modes = _availableModes;
    _viewMode = modes.isNotEmpty ? modes.first : 'none';
  }

  @override
  void dispose() {
    _previewScrollController.dispose();
    super.dispose();
  }

  EstimateTextDocument get _currentDocument =>
      EstimateTextDocumentBuilder.fromViewMode(
        viewMode: _viewMode,
        projectAddress: widget.project.address as String?,
        stage: widget.stage,
        works: widget.works,
        materials: widget.materials,
        showPrices: widget.showPrices,
        markupPercent: widget.markupPercent,
      );

  String get _currentText => _currentDocument.text;

  MaterialColor get _themeColor => _currentDocument.themeColor;

  Future<void> _saveCurrentText() async {
    await _textActionHandler.saveText(context, _currentDocument);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _themeColor;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useCompactActionRow =
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ||
            (kIsWeb && screenWidth < 600);
    return buildPremiumContainer(
      context: context,
      themeColor: themeColor,
      maxWidth: 720,
      child: DefaultTabController(
        length: 1, // Just to satisfy if needed, but we use chips
        child: SizedBox(
          height: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildPremiumHeader(
                context: context,
                title: "Предварительный просмотр",
                icon: Icons.article_rounded,
                themeColor: themeColor,
              ),
              const SizedBox(height: 16),
              if (_availableModes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _availableModes.map((mode) {
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child:
                      Divider(height: 1, color: themeColor.withOpacity(0.15)),
                ),
              ],
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppDesignTokens.isDark(context)
                        ? Theme.of(context).colorScheme.surfaceContainerHigh
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppDesignTokens.softBorder(context),
                    ),
                  ),
                  child: AppDialogScrollbar(
                    controller: _previewScrollController,
                    child: SingleChildScrollView(
                      controller: _previewScrollController,
                      child: SelectableText(
                        _currentText,
                        style: const TextStyle(
                            fontFamily: 'RobotoMono', fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: useCompactActionRow
                      ? SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildPreviewActionButton(
                                  themeColor: themeColor,
                                  icon: Icons.copy_rounded,
                                  label: "Копировать",
                                  onPressed: () => _textActionHandler.copyText(
                                    context,
                                    _currentDocument,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPreviewActionButton(
                                  themeColor: themeColor,
                                  icon: Icons.download_rounded,
                                  label: "Скачать TXT",
                                  onPressed: _saveCurrentText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              child: _buildPreviewActionButton(
                                themeColor: themeColor,
                                icon: Icons.copy_rounded,
                                label: "Копировать",
                                onPressed: () => _textActionHandler.copyText(
                                  context,
                                  _currentDocument,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              child: _buildPreviewActionButton(
                                themeColor: themeColor,
                                icon: Icons.download_rounded,
                                label: "Скачать TXT",
                                onPressed: _saveCurrentText,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String mode, String label, MaterialColor color) {
    final isSelected = _viewMode == mode;
    final isDark = AppDesignTokens.isDark(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _viewMode = mode);
      },
      selectedColor: color.shade100,
      backgroundColor:
          isDark ? color.shade900.withOpacity(0.18) : color.shade50,
      labelStyle: TextStyle(
        color: isSelected
            ? color.shade900
            : (isDark ? color.shade100 : color.shade800),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? color.shade300
            : (isDark ? color.shade700 : color.shade100),
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: false,
    );
  }

  Widget _buildPreviewActionButton({
    required MaterialColor themeColor,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: themeColor.shade800,
        side: BorderSide(color: themeColor.shade200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
