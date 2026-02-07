import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../models/unpaid_project_model.dart';
import '../models/finance_settings_model.dart';

part 'finance_repository.g.dart';

@riverpod
FinanceRepository financeRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return FinanceRepository(dio: dio);
}

class FinanceRepository {
  final Dio _dio;

  FinanceRepository({required Dio dio}) : _dio = dio;

  /// Получает список проектов с неоплаченными этапами
  Future<UnpaidProjectsResponse> fetchUnpaidProjects() async {
    try {
      final response = await _dio.get('/projects/unpaid_projects/');
      return UnpaidProjectsResponse.fromJson(response.data);
    } catch (e) {
      debugPrint("❌ Fetch Unpaid Projects Error: $e");
      rethrow;
    }
  }

  /// Отмечает этап как оплаченный
  Future<void> markStagePaid(int stageId) async {
    try {
      await _dio.patch('/stages/$stageId/', data: {'is_paid': true});
    } catch (e) {
      debugPrint("❌ Mark Stage Paid Error: $e");
      rethrow;
    }
  }

  /// Получает глобальные финансовые настройки
  Future<FinanceSettingsModel> getSettings() async {
    try {
      final response = await _dio.get('/finance/settings/');
      return FinanceSettingsModel.fromJson(response.data);
    } catch (e) {
      debugPrint("❌ Get Finance Settings Error: $e");
      rethrow;
    }
  }

  /// Обновляет глобальные финансовые настройки
  Future<FinanceSettingsModel> updateSettings({
    String? partnerExternalEstimate,
    String? financialNotes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (partnerExternalEstimate != null) {
        data['partner_external_estimate'] = partnerExternalEstimate;
      }
      if (financialNotes != null) {
        data['financial_notes'] = financialNotes;
      }
      final response = await _dio.patch('/finance/settings/', data: data);
      return FinanceSettingsModel.fromJson(response.data);
    } catch (e) {
      debugPrint("❌ Update Finance Settings Error: $e");
      rethrow;
    }
  }
}
