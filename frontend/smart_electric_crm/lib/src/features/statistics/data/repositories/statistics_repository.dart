import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../models/statistics_model.dart';

part 'statistics_repository.g.dart';

@riverpod
StatisticsRepository statisticsRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return StatisticsRepository(dio: dio);
}

class StatisticsRepository {
  final Dio _dio;

  StatisticsRepository({required Dio dio}) : _dio = dio;

  Never _throwApiError(
    Object error,
    StackTrace stackTrace, {
    required String fallbackMessage,
  }) {
    if (error is DioException) {
      throw ApiException.fromDio(error, fallbackMessage: fallbackMessage);
    }
    Error.throwWithStackTrace(error, stackTrace);
  }

  /// Получает данные статистики
  /// [period] - 'all', 'year', 'month'
  Future<StatisticsModel> fetchStatistics({String period = 'all'}) async {
    try {
      final response = await _dio.get('/statistics/', queryParameters: {
        'period': period,
      });
      return StatisticsModel.fromJson(response.data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to fetch statistics');
    }
  }
}

// Провайдер для хранения текущего фильтра
@riverpod
class StatisticsFilter extends _$StatisticsFilter {
  @override
  String build() => 'month'; // По умолчанию "За текущий месяц"

  void setPeriod(String period) {
    if (state == period) return;
    state = period;
  }
}

@riverpod
Future<StatisticsModel> statisticsData(Ref ref) {
  final period = ref.watch(statisticsFilterProvider);
  return ref
      .watch(statisticsRepositoryProvider)
      .fetchStatistics(period: period);
}
