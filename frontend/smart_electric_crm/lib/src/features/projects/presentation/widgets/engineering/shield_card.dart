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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppDesignTokens.cardBackground(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isExpanded
              ? themeColor.withOpacity(0.35)
              : AppDesignTokens.cardBorder(context),
        ), // Accent when expanded
        boxShadow: [
          BoxShadow(
            color: AppDesignTokens.cardShadow(context, hovered: _isExpanded),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent stripe on the left
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header (Tappable, neutral)
                    Material(
                      color: _isExpanded
                          ? themeColor.withOpacity(0.08)
                          : AppDesignTokens.cardBackground(context,
                              hovered: true),
                      child: InkWell(
                        onTap: _toggleExpand,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
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
                                  color: themeColor
                                      .withOpacity(0.1), // Accent icon bg
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconForType(shield.shieldType),
                                  color: themeColor.withOpacity(0.8),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shield.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          _getTypeName(shield.shieldType)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: themeColor.withOpacity(0.7),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          child: Text(
                                            '•',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          (shield.mounting == 'internal'
                                              ? 'Встроенный'
                                              : 'Навесной'),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
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
                    // Content
                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      child: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surface, // Clean white background
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mounting Toggle & Recommended Size
                            _buildTopInfo(context, themeColor),

                            const SizedBox(height: 16),

                            // Shield Content based on type
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey
                                    .shade50, // Full opacity for better contrast
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopInfo(BuildContext context, Color themeColor) {
    final shield = widget.shield;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // Full opacity for better contrast
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
                        Icon(Icons.tune_rounded,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          _getStatsTitle(shield),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.8,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text(
                        _getStatsSubtitle(shield),
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            height: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Mounting Toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'РњРћРќРўРђР–:',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.8,
                          color: Color(0xFF374151),
                        ),
                      ),
                      // Icon removed
                    ],
                  ),
                  const SizedBox(width: 12),
                  _buildMountingSegmented(themeColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 16),
          // Bottom Row: Size & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (shield.suggestedSize != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.straighten_rounded,
                          size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 10),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          children: [
                            const TextSpan(text: 'Рекомендовано: '),
                            TextSpan(
                              text: _formatSuggestedSize(shield.suggestedSize),
                              style: TextStyle(
                                color: themeColor.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
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
              if (shield.suggestedSize == null) const Spacer(),
              // Actions Row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Template Button (only for Power/LED)
                  if (shield.shieldType == 'power' ||
                      shield.shieldType == 'led') ...[
                    Tooltip(
                      message: 'Шаблоны',
                      child: OutlinedButton(
                        onPressed: () =>
                            _showTemplateDialog(context, ref, shield),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(36, 36),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Icon(Icons.copy_all_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        return Transform.scale(
                          scale: hasNotes ? _pulseAnimation.value : 1.0,
                          child: OutlinedButton(
                            onPressed: () =>
                                _showNotesDialog(context, ref, shield),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: hasNotes
                                  ? themeColor.withOpacity(0.8)
                                  : Colors.grey.shade600,
                              side: BorderSide(
                                color: hasNotes
                                    ? themeColor.withOpacity(0.4)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                              backgroundColor: hasNotes
                                  ? themeColor.withOpacity(0.05)
                                  : Colors.transparent,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(36, 36),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
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
                                            width: 1.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit Button
                  Tooltip(
                    message: 'Редактировать щит',
                    child: OutlinedButton(
                      onPressed: () =>
                          _showEditShieldDialog(context, ref, shield),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        padding: EdgeInsets.zero, // Icon only
                        minimumSize: const Size(36, 36), // Square 36x36
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete Button
                  Tooltip(
                    message: 'Удалить щит',
                    child: OutlinedButton(
                      onPressed: () => _deleteShield(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSuggestedSize(String? size) {
    if (size == null) return '';
    final count = int.tryParse(size);
    if (count == null) return size; // E.g. "Индивидуальный расчет"
    return '$count ${_getModulesText(count)}';
  }

  String _getModulesText(int count) {
    int n = count % 100;
    if (n >= 11 && n <= 19) return "модулей";
    n = count % 10;
    if (n == 1) return "модуль";
    if (n >= 2 && n <= 4) return "модуля";
    return "модулей";
  }

  Widget _buildMountingSegmented(Color themeColor) {
    final shield = widget.shield;
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'internal',
          label: Text('Внутр.',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        ButtonSegment(
          value: 'external',
          label: Text('Наруж.',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Ошибка обновления: $e')));
          }
        }
      },
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        selectedBackgroundColor: themeColor.withOpacity(0.1),
        selectedForegroundColor: themeColor,
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'power':
        return Icons.bolt_rounded;
      case 'led':
        return Icons.lightbulb_rounded;
      case 'multimedia':
        return Icons.router_rounded;
      default:
        return Icons.wb_iridescent_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'power':
        return Colors.orange.shade800;
      case 'led':
        return Colors.purple.shade600;
      case 'multimedia':
        return Colors.green;
      default:
        return Colors.grey.shade700;
    }
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
      barrierColor: Colors.transparent,
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
        return 'УСТРОЙСТВА ЩИТА:';
      case 'led':
        return 'ЗОНЫ УПРАВЛЕНИЯ:';
      case 'multimedia':
        return 'СЛАБОТОЧНЫЙ ЩИТ';
      default:
        return 'УСТРОЙСТВА:';
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
