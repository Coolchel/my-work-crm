import 'package:dio/dio.dart';
import '../models/shield_group_model.dart';
import '../models/led_zone_model.dart';
import '../models/shield_template_model.dart';
import '../models/led_template_model.dart';

class EngineeringRepository {
  final Dio _dio;

  EngineeringRepository({required Dio dio}) : _dio = dio;

  /// Получает список групп щита для проекта.
  Future<List<ShieldGroupModel>> fetchShieldGroups(String projectId) async {
    try {
      final response = await _dio
          .get('/shield-groups/', queryParameters: {'project': projectId});
      final List<dynamic> data = response.data;
      return data.map((json) => ShieldGroupModel.fromJson(json)).toList();
    } catch (e) {
      if (e is DioException && e.response != null) {
        print("❌ Fetch Shield Groups Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Получает список зон LED для проекта.
  Future<List<LedZoneModel>> fetchLedZones(String projectId) async {
    try {
      final response = await _dio
          .get('/led-zones/', queryParameters: {'project': projectId});
      final List<dynamic> data = response.data;
      return data.map((json) => LedZoneModel.fromJson(json)).toList();
    } catch (e) {
      if (e is DioException && e.response != null) {
        print("❌ Fetch LED Zones Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Получает список шаблонов щитов.
  Future<List<ShieldTemplateModel>> fetchShieldTemplates() async {
    try {
      final response = await _dio.get('/shield-templates/');
      final List<dynamic> data = response.data;
      return data.map((json) => ShieldTemplateModel.fromJson(json)).toList();
    } catch (e) {
      print("❌ Fetch Shield Templates Error: $e");
      rethrow;
    }
  }

  /// Получает список шаблонов LED.
  Future<List<LedTemplateModel>> fetchLedTemplates() async {
    try {
      final response = await _dio.get('/led-templates/');
      final List<dynamic> data = response.data;
      return data.map((json) => LedTemplateModel.fromJson(json)).toList();
    } catch (e) {
      print("❌ Fetch LED Templates Error: $e");
      rethrow;
    }
  }

  /// Применяет шаблон щита к проекту.
  Future<void> applyShieldTemplate(String projectId, int templateId) async {
    try {
      await _dio.post(
        '/projects/$projectId/apply_shield_template/',
        data: {'template_id': templateId},
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        print("❌ Apply Shield Template Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Применяет шаблон LED к проекту.
  Future<void> applyLedTemplate(String projectId, int templateId) async {
    try {
      await _dio.post(
        '/projects/$projectId/apply_led_template/',
        data: {'template_id': templateId},
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        print("❌ Apply LED Template Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Добавляет группу щита.
  Future<ShieldGroupModel> addShieldGroup(
      String projectId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/shield-groups/', data: {
        'project': projectId,
        ...data,
      });
      return ShieldGroupModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        print("❌ Add Shield Group Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Обновляет группу щита.
  Future<void> updateShieldGroup(int id, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/shield-groups/$id/', data: data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        print("❌ Update Shield Group Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Удаляет группу щита.
  Future<void> deleteShieldGroup(int id) async {
    try {
      await _dio.delete('/shield-groups/$id/');
    } catch (e) {
      if (e is DioException && e.response != null) {
        print("❌ Delete Shield Group Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Добавляет зону LED.
  Future<LedZoneModel> addLedZone(
      String projectId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/led-zones/', data: {
        'project': projectId,
        ...data,
      });
      return LedZoneModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        print("❌ Add LED Zone Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Обновляет зону LED.
  Future<void> updateLedZone(int id, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/led-zones/$id/', data: data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        print("❌ Update LED Zone Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Удаляет зону LED.
  Future<void> deleteLedZone(int id) async {
    try {
      await _dio.delete('/led-zones/$id/');
    } catch (e) {
      if (e is DioException && e.response != null) {
        print("❌ Delete LED Zone Error: ${e.response?.data}");
      }
      rethrow;
    }
  }
}
