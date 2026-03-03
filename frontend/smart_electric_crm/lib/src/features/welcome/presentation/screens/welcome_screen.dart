import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../projects/presentation/providers/project_providers.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../widgets/new_project_card.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/recent_projects_list.dart';
import '../widgets/search_results_overlay.dart';
import '../widgets/smart_search_bar.dart';
import '../widgets/welcome_header.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onSettingsPressed;

  const WelcomeScreen({
    required this.onSettingsPressed,
    super.key,
  });

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final LayerLink _layerLink = LayerLink();
  final Object _searchTapGroupId = Object();
  final GlobalKey _searchAnchorKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  static const double _overlayOffsetY = 60;
  static const double _overlayBottomGap = 12;
  static const double _overlayMinHeight = 120;
  static const double _overlayMaxHeightCap = 360;

  double _searchOverlayMaxHeight = 320;
  bool _isSearchLifted = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_recalculateOverlayMaxHeight);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recalculateOverlayMaxHeight();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_recalculateOverlayMaxHeight);
    _scrollController.dispose();
    super.dispose();
  }

  void _recalculateOverlayMaxHeight() {
    final anchorContext = _searchAnchorKey.currentContext;
    final rootContext = context;
    if (anchorContext == null || !mounted) {
      return;
    }

    final anchorBox = anchorContext.findRenderObject() as RenderBox?;
    final rootBox = rootContext.findRenderObject() as RenderBox?;
    if (anchorBox == null || rootBox == null) {
      return;
    }

    final anchorTopLeft =
        anchorBox.localToGlobal(Offset.zero, ancestor: rootBox);
    final overlayTop = anchorTopLeft.dy + _overlayOffsetY;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight =
        rootBox.size.height - overlayTop - _overlayBottomGap - bottomInset;
    final nextHeight = availableHeight
        .clamp(
          _overlayMinHeight,
          _overlayMaxHeightCap,
        )
        .toDouble();

    if ((nextHeight - _searchOverlayMaxHeight).abs() >= 1) {
      setState(() {
        _searchOverlayMaxHeight = nextHeight;
      });
    }
  }

  void _scrollSearchFieldToTop() {
    if (!_scrollController.hasClients || !mounted) {
      return;
    }
    final anchorContext = _searchAnchorKey.currentContext;
    final rootBox = context.findRenderObject() as RenderBox?;
    final anchorBox = anchorContext?.findRenderObject() as RenderBox?;
    if (rootBox == null || anchorBox == null) {
      return;
    }

    final anchorTopLeft =
        anchorBox.localToGlobal(Offset.zero, ancestor: rootBox);
    const targetTop = 12.0;
    final delta = anchorTopLeft.dy - targetTop;
    if (delta.abs() < 1) {
      return;
    }

    final nextOffset = (_scrollController.offset + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    if ((nextOffset - _scrollController.offset).abs() < 1) {
      return;
    }

    _scrollController.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        _recalculateOverlayMaxHeight();
      }
    });
  }

  void _activateSearchLift({
    required bool isMobile,
    bool forceScroll = true,
  }) {
    if (!_isSearchLifted && mounted) {
      setState(() {
        _isSearchLifted = true;
      });
    }
    if (isMobile && forceScroll) {
      _scrollSearchFieldToTop();
    }
  }

  void _clearSearchAndResetLift() {
    if (_isSearchLifted && mounted) {
      setState(() {
        _isSearchLifted = false;
      });
    }
    ref.read(projectSearchQueryProvider.notifier).state = null;
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final selectedStat = ref.watch(dashboardFilterProvider);
    final searchQuery = ref.watch(projectSearchQueryProvider);
    final isSearchActive = searchQuery != null && searchQuery.isNotEmpty;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final searchSectionOffsetY =
        isMobile ? (_isSearchLifted ? -44.0 : -20.0) : -20.0;
    final hasProjectsLoadError = ref.watch(projectListProvider).maybeWhen(
          error: (_, __) => true,
          orElse: () => false,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recalculateOverlayMaxHeight();
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                WelcomeHeader(
                  onSettingsPressed: widget.onSettingsPressed,
                ),
                Transform.translate(
                  offset: Offset(0, searchSectionOffsetY),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        QuickStatsRow(
                          selectedStat: selectedStat,
                          onStatSelected: (stat) {
                            ref.read(dashboardFilterProvider.notifier).state =
                                stat;
                          },
                        ),
                        const SizedBox(height: 24),
                        TapRegion(
                          groupId: _searchTapGroupId,
                          onTapInside: (_) {
                            _activateSearchLift(isMobile: isMobile);
                          },
                          onTapOutside: (_) {
                            _clearSearchAndResetLift();
                          },
                          child: CompositedTransformTarget(
                            key: _searchAnchorKey,
                            link: _layerLink,
                            child: SmartSearchBar(
                              onFocusChanged: (hasFocus) {
                                if (hasFocus) {
                                  _activateSearchLift(isMobile: isMobile);
                                }
                              },
                              onQueryChanged: (value) {
                                if (value.trim().isNotEmpty) {
                                  _activateSearchLift(isMobile: isMobile);
                                } else if (_isSearchLifted && isMobile) {
                                  _scrollSearchFieldToTop();
                                }
                              },
                              onCleared: _clearSearchAndResetLift,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!isSearchActive)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: NewProjectCard(),
                  ),
                if (!isSearchActive && hasProjectsLoadError)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _WelcomeNetworkNotice(),
                  ),
                const SizedBox(height: 24),
                if (!isSearchActive)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: RecentProjectsList(),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (isSearchActive)
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 60),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  child: TapRegion(
                    groupId: _searchTapGroupId,
                    child: SearchResultsOverlay(
                      maxHeight: _searchOverlayMaxHeight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WelcomeNetworkNotice extends StatelessWidget {
  const _WelcomeNetworkNotice();

  @override
  Widget build(BuildContext context) {
    final isDark = AppDesignTokens.isDark(context);
    final borderColor = isDark
        ? Colors.deepOrangeAccent.withOpacity(0.35)
        : Colors.deepOrange.withOpacity(0.28);
    final bgGradient = isDark
        ? const [Color(0xFF2D1F1A), Color(0xFF241A17)]
        : [Colors.orange.shade50, Colors.deepOrange.shade50];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 20,
            color: isDark ? Colors.orange.shade200 : Colors.deepOrange.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '\u041d\u0435\u0442 \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f \u043a \u0438\u043d\u0442\u0435\u0440\u043d\u0435\u0442\u0443. \u041d\u0435\u043a\u043e\u0442\u043e\u0440\u044b\u0435 \u0431\u043b\u043e\u043a\u0438 \u0432\u0440\u0435\u043c\u0435\u043d\u043d\u043e \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u043d\u044b.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
