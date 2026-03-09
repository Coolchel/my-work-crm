import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

typedef ScrollToTopCallback = Future<void> Function({bool animated});

enum AppShellSection {
  home,
  projects,
  finance,
  statistics,
  settings,
}

enum ProjectDetailSection {
  stages,
  shields,
  files,
}

enum EstimateSection {
  works,
  materials,
}

enum CatalogSection {
  system,
  catalog,
}

class ScrollToTopController {
  final Map<Object, ScrollToTopCallback> _callbacks =
      <Object, ScrollToTopCallback>{};
  final List<Object> _attachmentOrder = <Object>[];

  Object attach(ScrollToTopCallback callback) {
    final token = Object();
    _callbacks[token] = callback;
    _attachmentOrder.add(token);
    return token;
  }

  void detach(Object token) {
    _callbacks.remove(token);
    _attachmentOrder.remove(token);
  }

  Future<void> scrollToTop({bool animated = true}) async {
    if (_attachmentOrder.isEmpty) {
      return;
    }
    final token = _attachmentOrder.last;
    final callback = _callbacks[token];
    if (callback == null) {
      return;
    }
    await callback(animated: animated);
  }
}

class AppNavigation {
  AppNavigation._();

  static final ScrollToTopController homeScrollController =
      ScrollToTopController();
  static final ScrollToTopController objectsScrollController =
      ScrollToTopController();
  static final ScrollToTopController financeScrollController =
      ScrollToTopController();
  static final ScrollToTopController statisticsScrollController =
      ScrollToTopController();
  static final ScrollToTopController settingsScrollController =
      ScrollToTopController();
  static final ScrollToTopController worksScrollController =
      ScrollToTopController();
  static final ScrollToTopController materialsScrollController =
      ScrollToTopController();
  static final ScrollToTopController stagesScrollController =
      ScrollToTopController();
  static final ScrollToTopController shieldsScrollController =
      ScrollToTopController();
  static final ScrollToTopController filesScrollController =
      ScrollToTopController();
  static final ScrollToTopController directorySystemScrollController =
      ScrollToTopController();
  static final ScrollToTopController directoryCatalogScrollController =
      ScrollToTopController();
  static AppShellSection _lastNonSettingsSection = AppShellSection.home;

  static const String loginPath = '/login';
  static const String loadingPath = '/loading';
  static const String homePath = '/';
  static const String projectsPath = '/projects';
  static const String financePath = '/finance';
  static const String statisticsPath = '/statistics';
  static const String settingsPath = '/settings';
  static const String catalogPath = '/catalog';
  static const String fileViewerPath = '/file-viewer';

  static void setLastNonSettingsSection(AppShellSection section) {
    if (section == AppShellSection.settings) {
      return;
    }
    _lastNonSettingsSection = section;
  }

  static AppShellSection get lastNonSettingsSection => _lastNonSettingsSection;

  static String locationForShellSection(AppShellSection section) {
    return switch (section) {
      AppShellSection.home => homePath,
      AppShellSection.projects => projectsPath,
      AppShellSection.finance => financePath,
      AppShellSection.statistics => statisticsPath,
      AppShellSection.settings => settingsPath,
    };
  }

  static ProjectDetailSection projectDetailSectionFromName(String? value) {
    return switch (value) {
      'shields' => ProjectDetailSection.shields,
      'files' => ProjectDetailSection.files,
      _ => ProjectDetailSection.stages,
    };
  }

  static EstimateSection estimateSectionFromName(String? value) {
    return switch (value) {
      'materials' => EstimateSection.materials,
      _ => EstimateSection.works,
    };
  }

  static CatalogSection catalogSectionFromName(String? value) {
    return switch (value) {
      'catalog' => CatalogSection.catalog,
      _ => CatalogSection.system,
    };
  }

  static String projectLocation(
    String projectId, {
    ProjectDetailSection tab = ProjectDetailSection.stages,
    String? from,
  }) {
    final queryParameters = <String, String>{};
    if (tab != ProjectDetailSection.stages) {
      queryParameters['tab'] = tab.name;
    }
    if (from != null && from.isNotEmpty) {
      queryParameters['from'] = from;
    }
    return Uri(
      path: '$projectsPath/$projectId',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
  }

  static String estimateLocation({
    required String projectId,
    required String stageId,
    EstimateSection tab = EstimateSection.works,
    String? from,
  }) {
    final queryParameters = <String, String>{};
    if (tab != EstimateSection.works) {
      queryParameters['tab'] = tab.name;
    }
    if (from != null && from.isNotEmpty) {
      queryParameters['from'] = from;
    }
    return Uri(
      path: '$projectsPath/$projectId/estimate/$stageId',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
  }

  static String catalogLocation({
    CatalogSection tab = CatalogSection.system,
    String? from,
  }) {
    final queryParameters = <String, String>{};
    if (tab != CatalogSection.system) {
      queryParameters['tab'] = tab.name;
    }
    if (from != null && from.isNotEmpty) {
      queryParameters['from'] = from;
    }
    return Uri(
      path: catalogPath,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
  }

  static String fileViewerLocation({
    required String url,
    required String title,
    String? from,
  }) {
    final queryParameters = <String, String>{
      'url': url,
      'title': title,
    };
    if (from != null && from.isNotEmpty) {
      queryParameters['from'] = from;
    }
    return Uri(
      path: fileViewerPath,
      queryParameters: queryParameters,
    ).toString();
  }

  static String currentLocation(BuildContext context) {
    return GoRouterState.of(context).uri.toString();
  }

  static void goToShellSection(
    BuildContext context,
    AppShellSection section,
  ) {
    context.go(locationForShellSection(section));
  }

  static void openProject(
    BuildContext context, {
    required String projectId,
    ProjectDetailSection tab = ProjectDetailSection.stages,
    String? from,
  }) {
    context.push(
      projectLocation(
        projectId,
        tab: tab,
        from: from ?? currentLocation(context),
      ),
    );
  }

  static void openEstimate(
    BuildContext context, {
    required String projectId,
    required String stageId,
    EstimateSection tab = EstimateSection.works,
    String? from,
  }) {
    context.push(
      estimateLocation(
        projectId: projectId,
        stageId: stageId,
        tab: tab,
        from: from ?? currentLocation(context),
      ),
    );
  }

  static void openCatalog(
    BuildContext context, {
    CatalogSection tab = CatalogSection.system,
    String? from,
  }) {
    context.push(
      catalogLocation(
        tab: tab,
        from: from ?? currentLocation(context),
      ),
    );
  }

  static void openFileViewer(
    BuildContext context, {
    required String url,
    required String title,
    String? from,
  }) {
    context.push(
      fileViewerLocation(
        url: url,
        title: title,
        from: from ?? currentLocation(context),
      ),
    );
  }

  static Future<void> goHome({bool scrollToTop = true}) async {
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      return;
    }

    context.go(homePath);
    await _nextFrame();

    if (!scrollToTop) {
      return;
    }

    await _nextFrame();
    await homeScrollController.scrollToTop();
  }

  static Future<void> _nextFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    return completer.future;
  }
}
