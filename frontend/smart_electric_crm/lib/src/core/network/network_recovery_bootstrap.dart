import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/projects/presentation/providers/project_providers.dart';
import '../../features/statistics/data/repositories/statistics_repository.dart';

final networkRecoveryBootstrapProvider =
    Provider<NetworkRecoveryCoordinator>((ref) {
  final coordinator = NetworkRecoveryCoordinator(ref);
  coordinator.start();
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

class NetworkRecoveryCoordinator {
  NetworkRecoveryCoordinator(this._ref);

  final Ref _ref;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _subscription;
  bool _hadConnection = true;
  DateTime _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  static const Duration _minRefreshInterval = Duration(seconds: 2);

  Future<void> start() async {
    final initial = await _connectivity.checkConnectivity();
    _hadConnection = _hasConnection(initial);

    _subscription = _connectivity.onConnectivityChanged.listen((event) {
      final hasConnection = _hasConnection(event);
      if (hasConnection && !_hadConnection) {
        _refreshAfterReconnect();
      }
      _hadConnection = hasConnection;
    });
  }

  void _refreshAfterReconnect() {
    final now = DateTime.now();
    if (now.difference(_lastRefresh) < _minRefreshInterval) {
      return;
    }
    _lastRefresh = now;

    debugPrint(
        'NetworkRecoveryCoordinator: reconnect detected, refreshing data');
    _ref.invalidate(projectListProvider);
    _ref.invalidate(projectSearchResultsProvider);
    _ref.invalidate(unpaidProjectsProvider);
    _ref.invalidate(financeSettingsProvider);
    _ref.invalidate(statisticsDataProvider);
  }

  bool _hasConnection(dynamic value) {
    if (value is ConnectivityResult) {
      return value != ConnectivityResult.none;
    }
    if (value is List<ConnectivityResult>) {
      return value.any((item) => item != ConnectivityResult.none);
    }
    if (value is Iterable<ConnectivityResult>) {
      return value.any((item) => item != ConnectivityResult.none);
    }
    return false;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
