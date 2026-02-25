import 'package:dio/dio.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import '../models/template_models.dart';

class TemplateRepository {
  final Dio _dio;

  TemplateRepository(this._dio);

  Future<void> _executeVoid(
    Future<void> Function() request, {
    required String fallbackMessage,
  }) async {
    try {
      await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallbackMessage: fallbackMessage);
    } catch (e) {
      throw ApiException.unknown(e, fallbackMessage: fallbackMessage);
    }
  }

  // --- Work Templates ---
  Future<List<WorkTemplate>> getWorkTemplates() async {
    try {
      final response = await _dio.get('/work-templates/');
      return (response.data as List)
          .map((e) => WorkTemplate.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallbackMessage: 'Failed to load work templates',
      );
    } catch (e) {
      throw ApiException.unknown(
        e,
        fallbackMessage: 'Failed to load work templates',
      );
    }
  }

  Future<void> applyWorkTemplate(int stageId, int templateId) async {
    try {
      await _dio.post(
        '/stages/$stageId/apply_work_template/',
        data: {'template_id': templateId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallbackMessage: 'Failed to apply work template',
      );
    } catch (e) {
      throw ApiException.unknown(
        e,
        fallbackMessage: 'Failed to apply work template',
      );
    }
  }

  // --- Material Templates ---
  Future<List<MaterialTemplate>> getMaterialTemplates() async {
    try {
      final response = await _dio.get('/material-templates/');
      return (response.data as List)
          .map((e) => MaterialTemplate.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallbackMessage: 'Failed to load material templates',
      );
    } catch (e) {
      throw ApiException.unknown(
        e,
        fallbackMessage: 'Failed to load material templates',
      );
    }
  }

  Future<void> applyMaterialTemplate(int stageId, int templateId) async {
    try {
      await _dio.post(
        '/stages/$stageId/apply_material_template/',
        data: {'template_id': templateId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallbackMessage: 'Failed to apply material template',
      );
    } catch (e) {
      throw ApiException.unknown(
        e,
        fallbackMessage: 'Failed to apply material template',
      );
    }
  }

  // --- Power Shield Templates ---
  Future<List<PowerShieldTemplate>> getPowerShieldTemplates() async {
    try {
      final response = await _dio.get('/powershield-templates/');
      return (response.data as List)
          .map((e) => PowerShieldTemplate.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallbackMessage: 'Failed to load power shield templates',
      );
    } catch (e) {
      throw ApiException.unknown(
        e,
        fallbackMessage: 'Failed to load power shield templates',
      );
    }
  }

  Future<void> applyPowerShieldTemplate(int shieldId, int templateId) async {
    try {
      await _dio.post(
        '/shields/$shieldId/apply_powershield_template/',
        data: {'template_id': templateId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallbackMessage: 'Failed to apply power shield template',
      );
    } catch (e) {
      throw ApiException.unknown(
        e,
        fallbackMessage: 'Failed to apply power shield template',
      );
    }
  }

  // --- LED Shield Templates ---
  Future<List<LedShieldTemplate>> getLedShieldTemplates() async {
    try {
      final response = await _dio.get('/led-shield-templates/');
      return (response.data as List)
          .map((e) => LedShieldTemplate.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallbackMessage: 'Failed to load LED shield templates',
      );
    } catch (e) {
      throw ApiException.unknown(
        e,
        fallbackMessage: 'Failed to load LED shield templates',
      );
    }
  }

  Future<void> applyLedShieldTemplate(int shieldId, int templateId) async {
    try {
      await _dio.post(
        '/shields/$shieldId/apply_led_shield_template/',
        data: {'template_id': templateId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallbackMessage: 'Failed to apply LED shield template',
      );
    } catch (e) {
      throw ApiException.unknown(
        e,
        fallbackMessage: 'Failed to apply LED shield template',
      );
    }
  }

  // --- Create & Delete Methods ---

  Future<void> createWorkTemplateFromStage(int stageId, String name,
      {String? description}) async {
    await _executeVoid(
      () => _dio.post('/work-templates/create_from_stage/', data: {
        'stage_id': stageId,
        'name': name,
        'description': description ?? '',
      }),
      fallbackMessage: 'Failed to create work template from stage',
    );
  }

  Future<void> deleteWorkTemplate(int id) async {
    await _executeVoid(
      () => _dio.delete('/work-templates/$id/'),
      fallbackMessage: 'Failed to delete work template',
    );
  }

  Future<void> createMaterialTemplateFromStage(int stageId, String name,
      {String? description}) async {
    await _executeVoid(
      () => _dio.post('/material-templates/create_from_stage/', data: {
        'stage_id': stageId,
        'name': name,
        'description': description ?? '',
      }),
      fallbackMessage: 'Failed to create material template from stage',
    );
  }

  Future<void> deleteMaterialTemplate(int id) async {
    await _executeVoid(
      () => _dio.delete('/material-templates/$id/'),
      fallbackMessage: 'Failed to delete material template',
    );
  }

  Future<void> createPowerShieldTemplateFromShield(int shieldId, String name,
      {String? description}) async {
    await _executeVoid(
      () => _dio.post('/powershield-templates/create_from_shield/', data: {
        'shield_id': shieldId,
        'name': name,
        'description': description ?? '',
      }),
      fallbackMessage: 'Failed to create power shield template from shield',
    );
  }

  Future<void> deletePowerShieldTemplate(int id) async {
    await _executeVoid(
      () => _dio.delete('/powershield-templates/$id/'),
      fallbackMessage: 'Failed to delete power shield template',
    );
  }

  Future<void> createLedShieldTemplateFromShield(int shieldId, String name,
      {String? description}) async {
    await _executeVoid(
      () => _dio.post('/led-shield-templates/create_from_shield/', data: {
        'shield_id': shieldId,
        'name': name,
        'description': description ?? '',
      }),
      fallbackMessage: 'Failed to create LED shield template from shield',
    );
  }

  Future<void> deleteLedShieldTemplate(int id) async {
    await _executeVoid(
      () => _dio.delete('/led-shield-templates/$id/'),
      fallbackMessage: 'Failed to delete LED shield template',
    );
  }
}
