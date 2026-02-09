// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statisticsRepositoryHash() =>
    r'cdccb57ab47d5e59bc14528d095f8a57dec77f00';

/// See also [statisticsRepository].
@ProviderFor(statisticsRepository)
final statisticsRepositoryProvider =
    AutoDisposeProvider<StatisticsRepository>.internal(
  statisticsRepository,
  name: r'statisticsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statisticsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StatisticsRepositoryRef = AutoDisposeProviderRef<StatisticsRepository>;
String _$statisticsDataHash() => r'5932b3f8b4f1f256afa055e7d58807a9a228c9cd';

/// See also [statisticsData].
@ProviderFor(statisticsData)
final statisticsDataProvider =
    AutoDisposeFutureProvider<StatisticsModel>.internal(
  statisticsData,
  name: r'statisticsDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statisticsDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StatisticsDataRef = AutoDisposeFutureProviderRef<StatisticsModel>;
String _$statisticsFilterHash() => r'139e56a4da2fea6a74201e68fcccb744f78cb18f';

/// See also [StatisticsFilter].
@ProviderFor(StatisticsFilter)
final statisticsFilterProvider =
    AutoDisposeNotifierProvider<StatisticsFilter, String>.internal(
  StatisticsFilter.new,
  name: r'statisticsFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statisticsFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StatisticsFilter = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
