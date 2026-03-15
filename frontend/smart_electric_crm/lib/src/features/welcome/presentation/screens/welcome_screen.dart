import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../shared/presentation/widgets/desktop_web_frame.dart';
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
  static const double _desktopScrollRightPadding = 16;

  final LayerLink _layerLink = LayerLink();
  final Object _searchTapGroupId = Object();
  final GlobalKey _searchAnchorKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  Object? _scrollAttachment;

  double _searchOverlayMaxHeight = 320;
  double _searchOverlayOffsetY = 56;
  bool _isSearchFocused = false;
  bool _useLightStatusBarIcons = true;

  bool _shouldAutoRepositionSearch(BuildContext context) {
    return (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) ||
        DesktopWebFrame.isMobileWeb(context, maxWidth: 700);
  }

  bool get _useInlineDesktopResults =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_recalculateOverlayMaxHeight);
    _scrollController.addListener(_updateStatusBarStyle);
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
    _scrollController.removeListener(_updateStatusBarStyle);
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

  void _updateStatusBarStyle() {
    final headerContext = _headerKey.currentContext;
    if (headerContext == null || !mounted) {
      return;
    }

    final headerBox = headerContext.findRenderObject() as RenderBox?;
    if (headerBox == null) {
      return;
    }

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final switchOffset = headerBox.size.height > statusBarHeight
        ? headerBox.size.height - statusBarHeight
        : 0.0;
    final shouldUseLightIcons = _scrollController.offset < switchOffset;

    if (_useLightStatusBarIcons == shouldUseLightIcons) {
      return;
    }

    setState(() {
      _useLightStatusBarIcons = shouldUseLightIcons;
    });
  }

  SystemUiOverlayStyle _resolveSystemUiOverlayStyle(BuildContext context) {
    final useLightIcons = _useLightStatusBarIcons;

    return (useLightIcons
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark)
        .copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          useLightIcons ? Brightness.light : Brightness.dark,
      statusBarBrightness: useLightIcons ? Brightness.dark : Brightness.light,
    );
  }

  Widget _buildStatusBarBackdrop(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    if (topInset <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final backdropColor = isDark
        ? scheme.surfaceContainerHigh.withOpacity(0.96)
        : scheme.surface.withOpacity(0.96);
    final borderColor = scheme.outlineVariant.withOpacity(isDark ? 0.45 : 0.55);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          opacity: _useLightStatusBarIcons ? 0 : 1,
          child: Container(
            height: topInset,
            decoration: BoxDecoration(
              color: backdropColor,
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
      if (_shouldAutoRepositionSearch(context)) {
        await _scrollSearchToTop();
      }
    });
  }

  void _deactivateSearch() {
    ref.read(projectSearchQueryProvider.notifier).state = null;
    FocusScope.of(context).unfocus();
    if (_isSearchFocused) {
      setState(() => _isSearchFocused = false);
      if (_shouldAutoRepositionSearch(context) &&
          _scrollController.hasClients) {
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

  double _resolveSearchOverlayWidth(BuildContext context) {
    final anchorContext = _searchAnchorKey.currentContext;
    final anchorBox = anchorContext?.findRenderObject() as RenderBox?;
    if (anchorBox != null) {
      return anchorBox.size.width;
    }
    return MediaQuery.of(context).size.width - 40;
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
    final isDesktopWeb = DesktopWebFrame.isDesktop(context, minWidth: 1180);
    final isMobileWeb = DesktopWebFrame.isMobileWeb(context, maxWidth: 700);
    final usesMobileContentPadding = DesktopWebFrame.usesMobileContentPadding(
      context,
    );
    final shellSidebarInset = DesktopWebFrame.persistentShellContentInset(
      context,
    );
    final hasProjectsLoadError = ref.watch(projectListProvider).maybeWhen(
          error: (_, __) => true,
          orElse: () => false,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recalculateOverlayMaxHeight();
        _updateStatusBarStyle();
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _resolveSystemUiOverlayStyle(context),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: isDesktopWeb
            ? Stack(
                children: [
                  Column(
                    children: [
                      WelcomeHeader(
                        key: _headerKey,
                        onSettingsPressed: widget.onSettingsPressed,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.only(left: shellSidebarInset),
                          child: DesktopWebPageFrame(
                            maxWidth: 1360,
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
                                if (isSearchActive && _useInlineDesktopResults)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24),
                                    child: SearchResultsOverlay(
                                      maxHeight: 520,
                                      queryProvider: projectSearchQueryProvider,
                                      resultsProvider:
                                          projectSearchResultsProvider,
                                      inline: true,
                                      matchSearchWidth: true,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          opacity: isSearchActive ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: isSearchActive,
                            child: AnimatedPadding(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              padding: EdgeInsets.only(left: shellSidebarInset),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return DesktopWebPageFrame(
                                    maxWidth: 1360,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: SizedBox(
                                      height: constraints.maxHeight,
                                      child: SingleChildScrollView(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.only(
                                          top: 8,
                                          right: _desktopScrollRightPadding,
                                          bottom: 100,
                                        ),
                                        child: Column(
                                          children: [
                                            _buildSearchBar(),
                                            const SizedBox(height: 18),
                                            const NewProjectCard(),
                                            const SizedBox(height: 24),
                                            if (hasProjectsLoadError)
                                              const Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: RecentProjectsList(),
                                                  ),
                                                  SizedBox(width: 24),
                                                  SizedBox(
                                                    width: 360,
                                                    child:
                                                        _WelcomeNetworkNotice(),
                                                  ),
                                                ],
                                              )
                                            else
                                              const RecentProjectsList(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBarBackdrop(context),
                  if (isSearchActive && !_useInlineDesktopResults)
                    CompositedTransformFollower(
                      link: _layerLink,
                      showWhenUnlinked: false,
                      offset: Offset(0, _searchOverlayOffsetY),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: _resolveSearchOverlayWidth(context),
                          child: TapRegion(
                            groupId: _searchTapGroupId,
                            child: SearchResultsOverlay(
                              maxHeight: _searchOverlayMaxHeight,
                              queryProvider: projectSearchQueryProvider,
                              resultsProvider: projectSearchResultsProvider,
                              matchSearchWidth: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children: [
                              WelcomeHeader(
                                key: _headerKey,
                                onSettingsPressed: widget.onSettingsPressed,
                              ),
                              Transform.translate(
                                offset: Offset(0, isMobileWeb ? -12 : -20),
                                child: AnimatedPadding(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  padding:
                                      EdgeInsets.only(left: shellSidebarInset),
                                  child: DesktopWebPageFrame(
                                    maxWidth: 1360,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: DesktopWebFrame
                                          .contentHorizontalPadding(
                                        context,
                                        desktop: 20,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        QuickStatsRow(
                                          selectedStat: selectedStat,
                                          onStatSelected: (stat) {
                                            ref
                                                .read(
                                                  dashboardFilterProvider
                                                      .notifier,
                                                )
                                                .state = stat;
                                          },
                                        ),
                                        SizedBox(height: isMobileWeb ? 14 : 24),
                                        _buildSearchBar(),
                                        if (isSearchActive &&
                                            _useInlineDesktopResults)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: isMobileWeb ? 12 : 16,
                                            ),
                                            child: SearchResultsOverlay(
                                              maxHeight: 520,
                                              queryProvider:
                                                  projectSearchQueryProvider,
                                              resultsProvider:
                                                  projectSearchResultsProvider,
                                              inline: true,
                                              matchSearchWidth: true,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                opacity: isSearchActive ? 0 : 1,
                                child: IgnorePointer(
                                  ignoring: isSearchActive,
                                  child: AnimatedPadding(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    padding: EdgeInsets.only(
                                        left: shellSidebarInset),
                                    child: DesktopWebPageFrame(
                                      maxWidth: 1360,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: DesktopWebFrame
                                            .contentHorizontalPadding(
                                          context,
                                          desktop: 16,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          SizedBox(height: isMobileWeb ? 4 : 8),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  usesMobileContentPadding
                                                      ? 0
                                                      : 16,
                                            ),
                                            child: NewProjectCard(),
                                          ),
                                          if (hasProjectsLoadError)
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                usesMobileContentPadding
                                                    ? 0
                                                    : 16,
                                                isMobileWeb ? 10 : 12,
                                                usesMobileContentPadding
                                                    ? 0
                                                    : 16,
                                                0,
                                              ),
                                              child: _WelcomeNetworkNotice(),
                                            ),
                                          SizedBox(
                                              height: isMobileWeb ? 18 : 24),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  usesMobileContentPadding
                                                      ? 0
                                                      : 16,
                                            ),
                                            child: RecentProjectsList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isMobileWeb ? 76 : 100),
                            ],
                          ),
                        ),
                        _buildStatusBarBackdrop(context),
                        if (isSearchActive && !_useInlineDesktopResults)
                          CompositedTransformFollower(
                            link: _layerLink,
                            showWhenUnlinked: false,
                            offset: Offset(0, _searchOverlayOffsetY),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: _resolveSearchOverlayWidth(context),
                                child: TapRegion(
                                  groupId: _searchTapGroupId,
                                  child: SearchResultsOverlay(
                                    maxHeight: _searchOverlayMaxHeight,
                                    queryProvider: projectSearchQueryProvider,
                                    resultsProvider:
                                        projectSearchResultsProvider,
                                    matchSearchWidth: true,
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
