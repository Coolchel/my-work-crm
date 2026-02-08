import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Получает данные статистики
  Future<StatisticsModel> fetchStatistics() async {
    try {
      final response = await _dio.get('/statistics/');
      // API возвращает данные напрямую для list, если зарегистрировано как ViewSet без поиска
      // Но обычно DRF ViewSet.list возвращает список или объект.
      // Наш StatisticsViewSet.list возвращает Response({...}) напрямую.
      return StatisticsModel.fromJson(response.data);
    } catch (e) {
      debugPrint("❌ Fetch Statistics Error: $e");
      rethrow;
    }
  }
}

@riverpod
Future<StatisticsModel> statisticsData(Ref ref) {
  return ref.watch(statisticsRepositoryProvider).fetchStatistics();
}
