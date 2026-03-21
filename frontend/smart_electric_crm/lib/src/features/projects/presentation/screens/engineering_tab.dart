import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

import '../../data/models/project_model.dart';
import '../../../engineering/data/models/shield_model.dart';
import '../dialogs/engineering/add_shield_dialog.dart';
import '../widgets/engineering/shield_card.dart';

class EngineeringTab extends ConsumerStatefulWidget {
  final ProjectModel project;
  final ScrollController scrollController;
  final double topContentInset;

  const EngineeringTab({
    required this.project,
    required this.scrollController,
    required this.topContentInset,
    super.key,
  });

  @override
  ConsumerState<EngineeringTab> createState() => _EngineeringTabState();
}

class _EngineeringTabState extends ConsumerState<EngineeringTab> {
  Object? _scrollAttachment;

  @override
  void initState() {
    super.initState();
    _scrollAttachment =
        AppNavigation.shieldsScrollController.attach(_scrollToTop);
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.shieldsScrollController.detach(scrollAttachment);
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
    final useOverlayPrimaryAction =
        DesktopWebFrame.usesOverlayPrimaryAction(context);
    final sortedShields = List<ShieldModel>.from(widget.project.shields)
      ..sort((a, b) {
        final order = {'power': 0, 'multimedia': 1, 'led': 2};
        return (order[a.shieldType] ?? 99).compareTo(order[b.shieldType] ?? 99);
      });

    return Scaffold(
      floatingActionButton: useOverlayPrimaryAction
          ? Tooltip(
              message: 'Добавить щит',
              preferBelow: false,
              verticalOffset: 32,
              child: isMobileWeb
                  ? FloatingActionButton.small(
                      heroTag: 'add_shield_fab',
                      onPressed: () => _showAddShieldDialog(
                        context,
                        ref,
                        widget.project.id.toString(),
                      ),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      elevation: 2,
                      tooltip: null,
                      child: const Icon(Icons.add),
                    )
                  : FloatingActionButton(
                      heroTag: 'add_shield_fab',
                      onPressed: () => _showAddShieldDialog(
                        context,
                        ref,
                        widget.project.id.toString(),
                      ),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      elevation: 2,
                      tooltip: null,
                      child: const Icon(Icons.add),
                    ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          const contentMaxWidth = 1380.0;
          final scrollbarEndInset =
              DesktopWebFrame.scrollableContentEndInset(context);
          final bottomPadding = DesktopWebFrame.scrollableContentBottomPadding(
            context,
            hasOverlayAction: useOverlayPrimaryAction,
          );
          final showCenteredAddCard =
              !useOverlayPrimaryAction && widget.project.shields.isEmpty;
          final horizontalPadding =
              DesktopWebFrame.centeredContentHorizontalPadding(
            context,
            constraints.maxWidth,
            maxWidth: contentMaxWidth,
            trailingInset: scrollbarEndInset,
          );

          return SingleChildScrollView(
            controller: widget.scrollController,
            padding: EdgeInsetsDirectional.fromSTEB(
              horizontalPadding,
              widget.topContentInset,
              horizontalPadding + scrollbarEndInset,
              bottomPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight -
                        widget.topContentInset -
                        bottomPadding)
                    .clamp(0.0, double.infinity),
              ),
              child: Column(
                mainAxisAlignment: showCenteredAddCard
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  if (widget.project.shields.isEmpty && useOverlayPrimaryAction)
                    const FriendlyEmptyState(
                      icon: Icons.settings_input_component_outlined,
                      title: 'Нет щитов',
                      subtitle:
                          'Добавьте первый щит, чтобы начать инженерную часть проекта.',
                      accentColor: Colors.indigo,
                    )
                  else
                    ...sortedShields.map((shield) => ShieldCard(
                          shield: shield,
                          projectId: widget.project.id.toString(),
                        )),
                  if (!useOverlayPrimaryAction) ...[
                    if (widget.project.shields.isNotEmpty)
                      const SizedBox(height: 24),
                    _AddShieldCard(
                      onTap: () => _showAddShieldDialog(
                        context,
                        ref,
                        widget.project.id.toString(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddShieldDialog(
    BuildContext context,
    WidgetRef ref,
    String projectId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddShieldDialog(projectId: projectId),
    );
  }
}

class _AddShieldCard extends StatefulWidget {
  const _AddShieldCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<_AddShieldCard> createState() => _AddShieldCardState();
}

class _AddShieldCardState extends State<_AddShieldCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;
    final borderHovered = isDark ? false : _isHovered;
    final lightBaseCardBackground = AppDesignTokens.cardBackground(context);
    final bgGradient = isDark
        ? _isHovered
            ? const [Color(0xFF252C37), Color(0xFF1D232D)]
            : const [Color(0xFF1C2028), Color(0xFF171A21)]
        : _isHovered
            ? [
                Colors.indigo.shade100.withOpacity(0.5),
                Colors.indigo.shade50.withOpacity(0.4),
              ]
            : [
                lightBaseCardBackground,
                lightBaseCardBackground,
              ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 92,
            maxHeight: 92,
            maxWidth: 560,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppDesignTokens.cardBorder(
                  context,
                  hovered: borderHovered,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      AppDesignTokens.cardShadow(context, hovered: _isHovered),
                  blurRadius: _isHovered ? 18 : 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('engineering_add_shield_card'),
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(24),
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return AppDesignTokens.pressedOverlay(context);
                  }
                  return Colors.transparent;
                }),
                child: Container(
                  width: double.infinity,
                  height: 92,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: bgGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF4E67CF), Color(0xFF3A4FA8)]
                                : [
                                    Colors.indigo.shade600,
                                    Colors.indigo.shade400,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo
                                  .withOpacity(isDark ? 0.24 : 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: scheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Новый щит',
                              style: textStyles.sectionTitle.copyWith(
                                fontSize: 17,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Добавить щит в текущий объект',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyles.secondaryBody.copyWith(
                                color: isDark
                                    ? scheme.onSurfaceVariant.withOpacity(0.9)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDark
                            ? scheme.onSurfaceVariant.withOpacity(0.8)
                            : Colors.indigo.withOpacity(0.5),
                      ),
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
