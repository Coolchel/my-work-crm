import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';
import '../../dialogs/engineering/edit_shield_dialog.dart';
import 'shield_content_power.dart';
import 'shield_content_led.dart';
import 'shield_content_multimedia.dart';
import '../../../../engineering/presentation/dialogs/template_selection_dialog.dart';
import '../../../../engineering/presentation/providers/template_providers.dart';
import '../../../../engineering/data/models/template_models.dart';
import '../../../../../shared/presentation/dialogs/confirmation_dialog.dart';
import '../../../../../shared/presentation/dialogs/text_input_dialog.dart';
import '../../dialogs/engineering/shield_notes_dialog.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/app_number_formatter.dart';
import '../../../../../shared/presentation/widgets/desktop_web_frame.dart';
import '../../utils/shield_ui_palette.dart';

class ShieldCard extends ConsumerStatefulWidget {
  final ShieldModel shield;
  final String projectId;

  const ShieldCard({required this.shield, required this.projectId, super.key});

  @override
  ConsumerState<ShieldCard> createState() => _ShieldCardState();
}

class _ShieldCardState extends ConsumerState<ShieldCard>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;
  bool _isHovered = false;
  bool _isHeaderHovered = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    // Pulse animation for notes button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulse if notes exist
    if (widget.shield.notes.isNotEmpty) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ShieldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update pulse animation when notes change
    if (widget.shield.notes.isNotEmpty && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.shield.notes.isEmpty && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getColorForType(widget.shield.shieldType);
    final shield = widget.shield;
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final isCompactMobile = MediaQuery.of(context).size.width < 560;
    final textStyles = context.appTextStyles;

    return MouseRegion(
      key: ValueKey('shield_card_${widget.shield.id}'),
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(context,
              hovered: _isHovered && !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isExpanded
                ? ShieldUiPalette.blendAccentBorder(
                    context,
                    themeColor,
                    lightOpacity: 0.18,
                    darkOpacity: 0.24,
                  )
                : AppDesignTokens.cardBorder(context, hovered: _isHovered),
          ),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context,
                  hovered: _isExpanded || _isHovered),
              blurRadius: _isHovered ? 10 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header (Tappable, neutral)
                      Material(
                        color: Colors.transparent,
                        child: MouseRegion(
                          onEnter: (_) =>
                              setState(() => _isHeaderHovered = true),
                          onExit: (_) =>
                              setState(() => _isHeaderHovered = false),
                          child: InkWell(
                            onTap: _toggleExpand,
                            mouseCursor: SystemMouseCursors.click,
                            hoverColor: Colors.transparent,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: _isExpanded
                                    ? ShieldUiPalette.blendAccentSurface(
                                        context,
                                        themeColor,
                                        baseColor:
                                            AppDesignTokens.cardBackground(
                                          context,
                                          hovered:
                                              _isHovered || _isHeaderHovered,
                                        ),
                                        lightOpacity:
                                            _isHeaderHovered ? 0.07 : 0.04,
                                        darkOpacity:
                                            _isHeaderHovered ? 0.16 : 0.10,
                                      )
                                    : AppDesignTokens.cardBackground(context,
                                        hovered:
                                            _isHovered || _isHeaderHovered),
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppDesignTokens.cardBorder(context),
                                  ), // Neutral border
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: ShieldUiPalette.blendAccentSurface(
                                        context,
                                        themeColor,
                                        baseColor:
                                            AppDesignTokens.cardBackground(
                                          context,
                                          hovered:
                                              _isHovered || _isHeaderHovered,
                                        ),
                                        lightOpacity: 0.12,
                                        darkOpacity: 0.22,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIconForType(shield.shieldType),
                                      color: themeColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shield.name,
                                          style: textStyles.cardTitle.copyWith(
                                            fontSize: isCompactMobile ? 14 : 15,
                                            color: scheme.onSurface,
                                            letterSpacing: -0.4,
                                          ),
                                          maxLines: isCompactMobile ? 2 : 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 2,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            _buildTypeChip(
                                              context,
                                              label: _getTypeName(
                                                shield.shieldType,
                                              ),
                                              accentColor: themeColor,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6),
                                              child: Text(
                                                '•',
                                                style:
                                                    textStyles.caption.copyWith(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 9.5,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              (shield.mounting == 'internal'
                                                  ? 'Встроенный'
                                                  : 'Навесной'),
                                              style: textStyles.bodyStrong
                                                  .copyWith(
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  RotationTransition(
                                    turns: Tween(begin: 0.0, end: 0.5)
                                        .animate(_expandAnimation),
                                    child: Icon(
                                      Icons.expand_more_rounded,
                                      color: Colors.grey.shade700,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Content
                      SizeTransition(
                        sizeFactor: _expandAnimation,
                        child: Container(
                          color: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mounting Toggle & Recommended Size
                              _buildTopInfo(
                                  context, themeColor, isCompactMobile),

                              const SizedBox(height: 16),

                              // Shield Content based on type
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? scheme.surfaceContainer
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: scheme.outlineVariant),
                                ),
                                child: Column(
                                  children: [
                                    if (shield.shieldType == 'power')
                                      ShieldContentPower(
                                          shield: shield,
                                          projectId: widget.projectId,
                                          themeColor: themeColor),
                                    if (shield.shieldType == 'led')
                                      ShieldContentLed(
                                          shield: shield,
                                          projectId: widget.projectId,
                                          themeColor: themeColor),
                                    if (shield.shieldType == 'multimedia')
                                      ShieldContentMultimedia(
                                          shield: shield,
                                          projectId: widget.projectId,
                                          themeColor: themeColor),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopInfo(
      BuildContext context, Color themeColor, bool isCompactMobile) {
    final shield = widget.shield;
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final isDesktopWeb =
        kIsWeb && DesktopWebFrame.hasPersistentShellSidebar(context);
    final isWindowsDesktop =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final useExpandedActionButtons = isDesktopWeb || isWindowsDesktop;
    final textStyles = context.appTextStyles;
    final summaryBackground =
        isDark ? scheme.surfaceContainerHigh : const Color(0xFFF8FAFC);
    final summaryBorderColor = AppDesignTokens.softBorder(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: summaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: summaryBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Stats & Mounting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Stats (Configuration)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: themeColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getStatsTitle(shield),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyles.bodyStrong.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text(
                        _getStatsSubtitle(shield),
                        style: textStyles.secondaryBody.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Mounting Toggle
              Flexible(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Wrap(
                    spacing: isCompactMobile ? 6 : 10,
                    runSpacing: isCompactMobile ? 6 : 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.end,
                    children: [
                      Text(
                        'Монтаж:',
                        style: textStyles.bodyStrong.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _buildMountingSegmented(themeColor,
                          compact: isCompactMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppDesignTokens.softBorder(context)),
          const SizedBox(height: 16),
          // Bottom Row: Size & Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shield.suggestedSize != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppDesignTokens.softBorder(context)),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(Icons.straighten_rounded,
                          size: 16, color: Colors.grey.shade400),
                      RichText(
                        text: TextSpan(
                          style: textStyles.body.copyWith(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(
                              text: 'Корпус: ',
                              style: textStyles.bodyStrong.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            TextSpan(
                              text: _formatSuggestedSize(shield.suggestedSize),
                              style: textStyles.bodyStrong.copyWith(
                                fontSize: 11.5,
                                color: themeColor,
                                letterSpacing: 0.2,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (shield.suggestedSize != null) const SizedBox(height: 10),
              // Actions Row
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: useExpandedActionButtons
                      ? WrapAlignment.end
                      : WrapAlignment.center,
                  runAlignment: useExpandedActionButtons
                      ? WrapAlignment.end
                      : WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Template Button (only for Power/LED)
                    if (shield.shieldType == 'power' ||
                        shield.shieldType == 'led') ...[
                      Tooltip(
                        message: 'Шаблоны',
                        child: _buildActionButton(
                          label: 'Шаблоны',
                          icon: const Icon(Icons.copy_all_rounded, size: 18),
                          onPressed: () =>
                              _showTemplateDialog(context, ref, shield),
                          foregroundColor: Colors.grey.shade600,
                          sideColor: Colors.grey.withOpacity(0.3),
                          expanded: useExpandedActionButtons,
                        ),
                      ),
                    ],
                    // Notes Button (with pulsing animation when has notes)
                    Tooltip(
                      message: shield.notes.isEmpty
                          ? 'Добавить заметку'
                          : 'Редактировать заметку',
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          final hasNotes = shield.notes.isNotEmpty;
                          final noteIcon = Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (isDesktopWeb && hasNotes)
                                Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: const Icon(
                                    Icons.note_alt_outlined,
                                    size: 18,
                                  ),
                                )
                              else
                                const Icon(Icons.note_alt_outlined, size: 18),
                              if (hasNotes)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: themeColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );

                          return _buildActionButton(
                            label: hasNotes ? 'Заметки' : 'Заметка',
                            icon: noteIcon,
                            onPressed: () =>
                                _showNotesDialog(context, ref, shield),
                            foregroundColor: hasNotes
                                ? themeColor.withOpacity(0.8)
                                : Colors.grey.shade600,
                            sideColor: hasNotes
                                ? themeColor.withOpacity(0.4)
                                : Colors.grey.withOpacity(0.3),
                            backgroundColor: hasNotes
                                ? themeColor.withOpacity(0.05)
                                : Colors.transparent,
                            expanded: useExpandedActionButtons,
                          );
                        },
                      ),
                    ),
                    // Edit Button
                    Tooltip(
                      message: 'Редактировать щит',
                      child: _buildActionButton(
                        label: 'Редактировать',
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () =>
                            _showEditShieldDialog(context, ref, shield),
                        foregroundColor: Colors.grey.shade700,
                        sideColor: Colors.grey.withOpacity(0.3),
                        expanded: useExpandedActionButtons,
                      ),
                    ),
                    // Delete Button
                    Tooltip(
                      message: 'Удалить щит',
                      child: _buildActionButton(
                        label: 'Удалить',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => _deleteShield(context, ref),
                        foregroundColor: Colors.grey.shade600,
                        sideColor: Colors.grey.withOpacity(0.3),
                        expanded: useExpandedActionButtons,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
    required Color foregroundColor,
    required Color sideColor,
    bool expanded = false,
    Color backgroundColor = Colors.transparent,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        side: BorderSide(color: sideColor),
        backgroundColor: backgroundColor,
        padding: expanded
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : EdgeInsets.zero,
        minimumSize: expanded ? const Size(0, 34) : const Size(36, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: expanded
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 6),
                Text(
                  label,
                  style: context.appTextStyles.captionStrong.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : icon,
    );
  }

  Widget _buildTypeChip(
    BuildContext context, {
    required String label,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ShieldUiPalette.blendAccentSurface(
          context,
          accentColor,
          baseColor: Theme.of(context).colorScheme.surface,
          lightOpacity: 0.10,
          darkOpacity: 0.18,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ShieldUiPalette.blendAccentBorder(
            context,
            accentColor,
            lightOpacity: 0.18,
            darkOpacity: 0.30,
          ),
        ),
      ),
      child: Text(
        label,
        style: context.appTextStyles.captionStrong.copyWith(
          color: accentColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatSuggestedSize(String? size) {
    if (size == null) return '';
    final count = int.tryParse(size);
    if (count == null) return size; // E.g. "Индивидуальный расчет"
    return '${AppNumberFormatter.integer(count)} ${_getModulesText(count)}';
  }

  String _getModulesText(int count) {
    int n = count % 100;
    if (n >= 11 && n <= 19) return "модулей";
    n = count % 10;
    if (n == 1) return "модуль";
    if (n >= 2 && n <= 4) return "модуля";
    return "модулей";
  }

  Widget _buildMountingSegmented(Color themeColor, {bool compact = false}) {
    final shield = widget.shield;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: 'internal',
            label: Text('Внутр.',
                style: TextStyle(
                  fontSize: compact ? 9 : 9.5,
                  fontWeight: FontWeight.bold,
                )),
          ),
          ButtonSegment(
            value: 'external',
            label: Text('Наруж.',
                style: TextStyle(
                  fontSize: compact ? 9 : 9.5,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ],
        selected: {shield.mounting},
        onSelectionChanged: (Set<String> newSelection) async {
          final newValue = newSelection.first;
          try {
            await ref
                .read(engineeringRepositoryProvider)
                .updateShield(shield.id, {'mounting': newValue});
            ref.invalidate(projectListProvider);
            ref.invalidate(projectByIdProvider(widget.projectId));
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка обновления: $e')));
            }
          }
        },
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 2)
              : EdgeInsets.zero,
          selectedBackgroundColor: ShieldUiPalette.blendAccentSurface(
            context,
            themeColor,
            baseColor: Theme.of(context).colorScheme.surface,
            lightOpacity: 0.10,
            darkOpacity: 0.20,
          ),
          selectedForegroundColor: themeColor,
          side: BorderSide(color: AppDesignTokens.softBorder(context)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    return ShieldUiPalette.resolveShield(type).icon;
  }

  Color _getColorForType(String type) {
    return ShieldUiPalette.resolveShield(type).accent;
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'power':
        return 'Силовой';
      case 'led':
        return 'LED';
      case 'multimedia':
        return 'Слаботочный щит';
      default:
        return type;
    }
  }

  void _showEditShieldDialog(
      BuildContext context, WidgetRef ref, ShieldModel shield) {
    showDialog(
      context: context,
      builder: (context) =>
          EditShieldDialog(shield: shield, projectId: widget.projectId),
    );
  }

  Future<void> _deleteShield(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Удалить щит?',
        content: 'Все группы внутри будут удалены.',
        confirmText: 'Удалить',
        isDestructive: true,
        themeColor: Color(0xFF374151),
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(engineeringRepositoryProvider)
            .deleteShield(widget.shield.id);
        ref.invalidate(projectListProvider);
        ref.invalidate(projectByIdProvider(widget.projectId));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      }
    }
  }

  void _showSaveTemplateDialog(
      BuildContext context, WidgetRef ref, ShieldModel shield) async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => TextInputDialog(
        title: shield.shieldType == 'power'
            ? "Сохранить щит как шаблон"
            : "Сохранить LED щит как шаблон",
        labelText: "Название шаблона",
        descriptionLabelText: "Описание (опционально)",
        themeColor: _getColorForType(shield.shieldType),
      ),
    );

    if (result == null) return;

    final name = result is Map ? result['text'] : result;
    final description = result is Map ? result['description'] : '';

    if (name == null || name.isEmpty) return;

    try {
      if (shield.shieldType == 'power') {
        await ref
            .read(templateRepositoryProvider)
            .createPowerShieldTemplateFromShield(shield.id, name,
                description: description);
        ref.invalidate(powerShieldTemplatesProvider);
      } else {
        await ref
            .read(templateRepositoryProvider)
            .createLedShieldTemplateFromShield(shield.id, name,
                description: description);
        ref.invalidate(ledShieldTemplatesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка сохранения: $e")));
      }
    }
  }

  void _showTemplateDialog(
      BuildContext context, WidgetRef ref, ShieldModel shield) async {
    try {
      final isPower = shield.shieldType == 'power';
      final templates = isPower
          ? await ref.read(powerShieldTemplatesProvider.future)
          : await ref.read(ledShieldTemplatesProvider.future);

      if (!context.mounted) return;

      // Handle generic type safely
      void showSelect<T>(List<T> items) {
        showDialog(
          context: context,
          builder: (ctx) => TemplateSelectionDialog<T>(
            title: isPower ? "Шаблоны силового щита" : "Шаблоны LED щита",
            templates: items,
            getName: (t) => (t as dynamic).name,
            getDescription: (t) => (t as dynamic).description ?? '',
            onSelected: (t) =>
                _applyTemplate(context, ref, shield, (t as dynamic).id),
            themeColor: _getColorForType(shield.shieldType),
            onCreate: () => _showSaveTemplateDialog(context, ref, shield),
          ),
        );
      }

      if (isPower) {
        showSelect<PowerShieldTemplate>(templates as List<PowerShieldTemplate>);
      } else {
        showSelect<LedShieldTemplate>(templates as List<LedShieldTemplate>);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ошибка загрузки шаблонов: $e")));
      }
    }
  }

  Future<void> _applyTemplate(BuildContext context, WidgetRef ref,
      ShieldModel shield, int templateId) async {
    // Check if shield is not empty
    final isNotEmpty = shield.groups.isNotEmpty ||
        shield.ledZones.isNotEmpty ||
        shield.internetLinesCount > 0 ||
        shield.multimediaNotes.isNotEmpty;

    if (isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (ctx) => const ConfirmationDialog(
          title: "Применить шаблон?",
          content:
              "Применение шаблона приведет к удалению всех текущих позиций в этом щите. Продолжить?",
          confirmText: "Применить",
          themeColor: Color(0xFF374151),
        ),
      );
      if (confirm != true) return;
    }

    try {
      if (shield.shieldType == 'power') {
        await ref
            .read(templateRepositoryProvider)
            .applyPowerShieldTemplate(shield.id, templateId);
      } else {
        await ref
            .read(templateRepositoryProvider)
            .applyLedShieldTemplate(shield.id, templateId);
      }

      ref.invalidate(projectListProvider);
      ref.invalidate(projectByIdProvider(widget.projectId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка применения: $e")));
      }
    }
  }

  void _showNotesDialog(
      BuildContext context, WidgetRef ref, ShieldModel shield) {
    final themeColor = _getColorForType(shield.shieldType);
    showDialog(
      context: context,
      builder: (context) => ShieldNotesDialog(
        projectId: widget.projectId,
        shieldId: shield.id,
        currentNotes: shield.notes,
        themeColor: themeColor,
      ),
    );
  }

  String _getStatsTitle(ShieldModel shield) {
    switch (shield.shieldType) {
      case 'power':
        return 'Устройство щита:';
      case 'led':
        return 'Зоны управления:';
      case 'multimedia':
        return 'Слаботочный щит';
      default:
        return 'Устройства:';
    }
  }

  String _getStatsSubtitle(ShieldModel shield) {
    switch (shield.shieldType) {
      case 'power':
        final totalModules = shield.groups.fold<int>(
            0, (sum, group) => sum + (group.modulesCount * group.quantity));
        return '${shield.groups.length} позиций, $totalModules ${_getModulesText(totalModules)}';
      case 'led':
        return '${shield.ledZones.length} линий LED';
      case 'multimedia':
        return '${shield.internetLinesCount} линий Ethernet';
      default:
        return '';
    }
  }
}
