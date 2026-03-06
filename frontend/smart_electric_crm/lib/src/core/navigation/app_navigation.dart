import 'dart:async';

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class HomeScrollController {
  Future<void> Function({bool animated})? _scrollToTop;

  void attach(Future<void> Function({bool animated}) callback) {
    _scrollToTop = callback;
  }

  void detach() {
    _scrollToTop = null;
  }

  Future<void> scrollToTop({bool animated = true}) async {
    final callback = _scrollToTop;
    if (callback == null) {
      return;
    }
    await callback(animated: animated);
  }
}

class AppNavigation {
  AppNavigation._();

  static final HomeScrollController homeScrollController =
      HomeScrollController();

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
