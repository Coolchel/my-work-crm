import 'package:dio/dio.dart';
import '../models/template_models.dart';

class TemplateRepository {
  final Dio _dio;

  TemplateRepository(this._dio);

  // --- Work Templates ---
  Future<List<WorkTemplate>> getWorkTemplates() async {
    try {
      final response = await _dio.get('/work-templates/');
      return (response.data as List)
          .map((e) => WorkTemplate.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load work templates: $e');
    }
  }

  Future<void> applyWorkTemplate(int stageId, int templateId) async {
    try {
      await _dio.post(
        '/stages/$stageId/apply_work_template/',
        data: {'template_id': templateId},
      );
    } catch (e) {
      throw Exception('Failed to apply work template: $e');
    }
  }

  // --- Material Templates ---
  Future<List<MaterialTemplate>> getMaterialTemplates() async {
    try {
      final response = await _dio.get('/material-templates/');
      return (response.data as List)
          .map((e) => MaterialTemplate.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load material templates: $e');
    }
  }

  Future<void> applyMaterialTemplate(int stageId, int templateId) async {
    try {
      await _dio.post(
        '/stages/$stageId/apply_material_template/',
        data: {'template_id': templateId},
      );
    } catch (e) {
      throw Exception('Failed to apply material template: $e');
    }
  }

  // --- Power Shield Templates ---
  Future<List<PowerShieldTemplate>> getPowerShieldTemplates() async {
    try {
      final response = await _dio.get('/powershield-templates/');
      return (response.data as List)
          .map((e) => PowerShieldTemplate.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load power shield templates: $e');
    }
  }

  Future<void> applyPowerShieldTemplate(int shieldId, int templateId) async {
    try {
      await _dio.post(
        '/shields/$shieldId/apply_powershield_template/',
        data: {'template_id': templateId},
      );
    } catch (e) {
      throw Exception('Failed to apply power shield template: $e');
    }
  }

  // --- LED Shield Templates ---
  Future<List<LedShieldTemplate>> getLedShieldTemplates() async {
    try {
      final response = await _dio.get('/led-shield-templates/');
      return (response.data as List)
          .map((e) => LedShieldTemplate.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load LED shield templates: $e');
    }
  }

  Future<void> applyLedShieldTemplate(int shieldId, int templateId) async {
    try {
      await _dio.post(
        '/shields/$shieldId/apply_led_shield_template/',
        data: {'template_id': templateId},
      );
    } catch (e) {
      throw Exception('Failed to apply LED shield template: $e');
    }
  }

  // --- Create & Delete Methods ---

  Future<void> createWorkTemplateFromStage(int stageId, String name,
      {String? description}) async {
    await _dio.post('/work-templates/create_from_stage/', data: {
      'stage_id': stageId,
      'name': name,
      'description': description ?? '',
    });
  }

  Future<void> deleteWorkTemplate(int id) async {
    await _dio.delete('/work-templates/$id/');
  }

  Future<void> createMaterialTemplateFromStage(int stageId, String name,
      {String? description}) async {
    await _dio.post('/material-templates/create_from_stage/', data: {
      'stage_id': stageId,
      'name': name,
      'description': description ?? '',
    });
  }

  Future<void> deleteMaterialTemplate(int id) async {
    await _dio.delete('/material-templates/$id/');
  }

  Future<void> createPowerShieldTemplateFromShield(int shieldId, String name,
      {String? description}) async {
    await _dio.post('/powershield-templates/create_from_shield/', data: {
      'shield_id': shieldId,
      'name': name,
      'description': description ?? '',
    });
  }

  Future<void> deletePowerShieldTemplate(int id) async {
    await _dio.delete('/powershield-templates/$id/');
  }

  Future<void> createLedShieldTemplateFromShield(int shieldId, String name,
      {String? description}) async {
    await _dio.post('/led-shield-templates/create_from_shield/', data: {
      'shield_id': shieldId,
      'name': name,
      'description': description ?? '',
    });
  }

  Future<void> deleteLedShieldTemplate(int id) async {
    await _dio.delete('/led-shield-templates/$id/');
  }
}
