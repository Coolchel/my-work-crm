import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import '../models/shield_model.dart';
import '../models/shield_group_model.dart';
import '../models/led_zone_model.dart';
import '../models/shield_template_model.dart';
import '../models/led_template_model.dart';

class EngineeringRepository {
  final Dio _dio;

  EngineeringRepository({required Dio dio}) : _dio = dio;

  Never _throwApiError(Object error, String fallbackMessage) {
    if (error is DioException) {
      throw ApiException.fromDio(error, fallbackMessage: fallbackMessage);
    }
    throw ApiException.unknown(error, fallbackMessage: fallbackMessage);
  }

  // --- Shields ---

  /// Добавляет новый щит в проект
  Future<ShieldModel> addShield(
      String projectId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/shields/', data: {
        'project': projectId,
        ...data,
      });
      return ShieldModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Add Shield Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to add shield');
    }
  }

  /// Обновляет щит
  Future<ShieldModel> updateShield(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/shields/$id/', data: data);
      return ShieldModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Update Shield Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to update shield');
    }
  }

  /// Удаляет щит
  Future<void> deleteShield(int id) async {
    try {
      await _dio.delete('/shields/$id/');
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Delete Shield Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to delete shield');
    }
  }

  // --- Shield Groups ---

  /// Добавляет группу в щит
  Future<ShieldGroupModel> addShieldGroup(
      int shieldId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/shield-groups/', data: {
        'shield': shieldId,
        ...data,
      });
      return ShieldGroupModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Add Shield Group Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to add shield group');
    }
  }

  /// Обновляет группу щита
  Future<void> updateShieldGroup(int id, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/shield-groups/$id/', data: data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Update Shield Group Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to update shield group');
    }
  }

  /// Удаляет группу щита
  Future<void> deleteShieldGroup(int id) async {
    try {
      await _dio.delete('/shield-groups/$id/');
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Delete Shield Group Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to delete shield group');
    }
  }

  // --- LED Zones ---

  /// Добавляет зону в LED щит
  Future<LedZoneModel> addLedZone(
      int shieldId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/led-zones/', data: {
        'shield': shieldId,
        ...data,
      });
      return LedZoneModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Add LED Zone Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to add LED zone');
    }
  }

  /// Обновляет зону LED
  Future<void> updateLedZone(int id, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/led-zones/$id/', data: data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Update LED Zone Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to update LED zone');
    }
  }

  /// Удаляет зону LED
  Future<void> deleteLedZone(int id) async {
    try {
      await _dio.delete('/led-zones/$id/');
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Delete LED Zone Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to delete LED zone');
    }
  }

  // --- Templates ---

  Future<List<ShieldTemplateModel>> fetchShieldTemplates() async {
    try {
      final response = await _dio.get('/powershield-templates/');
      final List<dynamic> data = response.data;
      return data.map((json) => ShieldTemplateModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("❌ Fetch Shield Templates Error: $e");
      _throwApiError(e, 'Failed to load shield templates');
    }
  }

  Future<List<LedTemplateModel>> fetchLedTemplates() async {
    try {
      final response = await _dio.get('/led-shield-templates/');
      final List<dynamic> data = response.data;
      return data.map((json) => LedTemplateModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("❌ Fetch LED Templates Error: $e");
      _throwApiError(e, 'Failed to load LED templates');
    }
  }

  /// Применяет шаблон щита к конкретному щиту
  Future<void> applyShieldTemplate(int shieldId, int templateId) async {
    try {
      await _dio.post(
        '/shields/$shieldId/apply_powershield_template/',
        data: {'template_id': templateId},
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Apply Shield Template Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to apply shield template');
    }
  }

  /// Применяет шаблон LED к конкретному щиту
  Future<void> applyLedTemplate(int shieldId, int templateId) async {
    try {
      await _dio.post(
        '/shields/$shieldId/apply_led_shield_template/',
        data: {'template_id': templateId},
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Apply LED Template Error: ${e.response?.data}");
      }
      _throwApiError(e, 'Failed to apply LED template');
    }
  }
}
