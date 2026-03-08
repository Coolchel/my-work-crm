import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../widgets/new_project_card.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/recent_projects_list.dart';
import '../widgets/search_results_overlay.dart';
import '../widgets/smart_search_bar.dart';
import '../widgets/welcome_header.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onSettingsPressed;
  final ScrollToTopController? scrollController;

  const WelcomeScreen({
    required this.onSettingsPressed,
    this.scrollController,
    super.key,
  });

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const double _overlayGap = 8;
  static const double _overlayBottomGap = 12;
  static const double _overlayMinHeight = 120;
  static const double _overlayMaxHeightCap = 520;
  static const double _searchTopMargin = 8;

  final LayerLink _layerLink = LayerLink();
  final Object _searchTapGroupId = Object();
  final GlobalKey _searchAnchorKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  Object? _scrollAttachment;

  double _searchOverlayMaxHeight = 320;
  double _searchOverlayOffsetY = 56;
  bool _isSearchFocused = false;

  bool get _shouldAutoRepositionSearch =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_recalculateOverlayMaxHeight);
    _attachScrollController(widget.scrollController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recalculateOverlayMaxHeight();
      }
    });
  }

  @override
  void didUpdateWidget(covariant WelcomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _detachScrollController(oldWidget.scrollController);
      _attachScrollController(widget.scrollController);
    }
  }

  @override
  void dispose() {
    _detachScrollController(widget.scrollController);
    _scrollController.removeListener(_recalculateOverlayMaxHeight);
    _scrollController.dispose();
    super.dispose();
  }

  void _attachScrollController(ScrollToTopController? controller) {
    if (controller == null) {
      return;
    }
    _scrollAttachment = controller.attach(scrollToTop);
  }

  void _detachScrollController(ScrollToTopController? controller) {
    final token = _scrollAttachment;
    if (controller == null || token == null) {
      return;
    }
    controller.detach(token);
    _scrollAttachment = null;
  }

  Future<void> scrollToTop({bool animated = true}) async {
    if (!_scrollController.hasClients) {
      return;
    }

    if (animated) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _scrollController.jumpTo(0);
  }

  void _recalculateOverlayMaxHeight() {
    final anchorContext = _searchAnchorKey.currentContext;
    if (anchorContext == null || !mounted) {
      return;
    }

    final anchorBox = anchorContext.findRenderObject() as RenderBox?;
    final rootBox = context.findRenderObject() as RenderBox?;
    if (anchorBox == null || rootBox == null) {
      return;
    }

    final anchorTopLeft =
        anchorBox.localToGlobal(Offset.zero, ancestor: rootBox);
    final overlayTop = anchorTopLeft.dy + anchorBox.size.height + _overlayGap;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight =
        rootBox.size.height - overlayTop - _overlayBottomGap - bottomInset;
    final nextHeight = availableHeight
        .clamp(_overlayMinHeight, _overlayMaxHeightCap)
        .toDouble();
    final nextOffset = anchorBox.size.height + _overlayGap;

    if ((nextHeight - _searchOverlayMaxHeight).abs() >= 1 ||
        (nextOffset - _searchOverlayOffsetY).abs() >= 1) {
      setState(() {
        _searchOverlayMaxHeight = nextHeight;
        _searchOverlayOffsetY = nextOffset;
      });
    }
  }

  void _activateSearch() {
    if (!_isSearchFocused) {
      setState(() => _isSearchFocused = true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      _recalculateOverlayMaxHeight();
      if (_shouldAutoRepositionSearch) {
        await _scrollSearchToTop();
      }
    });
  }

  void _deactivateSearch() {
    ref.read(projectSearchQueryProvider.notifier).state = null;
    FocusScope.of(context).unfocus();
    if (_isSearchFocused) {
      setState(() => _isSearchFocused = false);
      if (_shouldAutoRepositionSearch && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  Future<void> _scrollSearchToTop() async {
    final anchorContext = _searchAnchorKey.currentContext;
    if (anchorContext == null || !_scrollController.hasClients) {
      return;
    }

    final anchorBox = anchorContext.findRenderObject() as RenderBox?;
    final rootBox = context.findRenderObject() as RenderBox?;
    if (anchorBox == null || rootBox == null) {
      return;
    }

    final anchorTopLeft =
        anchorBox.localToGlobal(Offset.zero, ancestor: rootBox);
    final safeTop = MediaQuery.of(context).padding.top + _searchTopMargin;
    final delta = anchorTopLeft.dy - safeTop;
    if (delta.abs() < 1) {
      return;
    }

    final target = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildSearchBar() {
    return TapRegion(
      groupId: _searchTapGroupId,
      onTapInside: (_) => _activateSearch(),
      onTapOutside: (_) => _deactivateSearch(),
      child: CompositedTransformTarget(
        key: _searchAnchorKey,
        link: _layerLink,
        child: SmartSearchBar(
          searchQueryProvider: projectSearchQueryProvider,
          onFocusChanged: (hasFocus) {
            if (hasFocus) {
              _activateSearch();
            } else {
              final q = ref.read(projectSearchQueryProvider);
              if (q == null || q.isEmpty) {
                _deactivateSearch();
              }
            }
          },
          onQueryChanged: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _recalculateOverlayMaxHeight();
              }
            });
          },
          onCleared: _deactivateSearch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedStat = ref.watch(dashboardFilterProvider);
    final searchQuery = ref.watch(projectSearchQueryProvider);
    final isSearchActive = searchQuery != null && searchQuery.isNotEmpty;
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
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      WelcomeHeader(
                        onSettingsPressed: widget.onSettingsPressed,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              QuickStatsRow(
                                selectedStat: selectedStat,
                                onStatSelected: (stat) {
                                  ref
                                      .read(dashboardFilterProvider.notifier)
                                      .state = stat;
                                },
                              ),
                              const SizedBox(height: 24),
                              _buildSearchBar(),
                            ],
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        opacity: isSearchActive ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: isSearchActive,
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: NewProjectCard(),
                              ),
                              if (hasProjectsLoadError)
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                                  child: _WelcomeNetworkNotice(),
                                ),
                              const SizedBox(height: 24),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: RecentProjectsList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                if (isSearchActive)
                  CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: Offset(0, _searchOverlayOffsetY),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: TapRegion(
                          groupId: _searchTapGroupId,
                          child: SearchResultsOverlay(
                            maxHeight: _searchOverlayMaxHeight,
                            queryProvider: projectSearchQueryProvider,
                            resultsProvider: projectSearchResultsProvider,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
              'РќРµС‚ РїРѕРґРєР»СЋС‡РµРЅРёСЏ Рє РёРЅС‚РµСЂРЅРµС‚Сѓ. РќРµРєРѕС‚РѕСЂС‹Рµ Р±Р»РѕРєРё РІСЂРµРјРµРЅРЅРѕ РЅРµРґРѕСЃС‚СѓРїРЅС‹.',
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
