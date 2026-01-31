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

  // --- Multimedia Templates ---
  Future<List<MultimediaTemplate>> getMultimediaTemplates() async {
    try {
      final response = await _dio.get('/multimedia-templates/');
      return (response.data as List)
          .map((e) => MultimediaTemplate.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load multimedia templates: $e');
    }
  }

  Future<void> applyMultimediaTemplate(int shieldId, int templateId) async {
    try {
      await _dio.post(
        '/shields/$shieldId/apply_multimedia_template/',
        data: {'template_id': templateId},
      );
    } catch (e) {
      throw Exception('Failed to apply multimedia template: $e');
    }
  }
}
