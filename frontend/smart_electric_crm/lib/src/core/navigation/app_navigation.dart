import 'dart:async';

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

typedef ScrollToTopCallback = Future<void> Function({bool animated});

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

  static VoidCallback? _selectHomeTab;

  static void registerHomeTabHandler(VoidCallback handler) {
    _selectHomeTab = handler;
  }

  static void unregisterHomeTabHandler(VoidCallback handler) {
    if (identical(_selectHomeTab, handler)) {
      _selectHomeTab = null;
    }
  }

  static Future<void> goHome({bool scrollToTop = true}) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    navigator.popUntil((route) => route.isFirst);
    await _nextFrame();

    _selectHomeTab?.call();

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
