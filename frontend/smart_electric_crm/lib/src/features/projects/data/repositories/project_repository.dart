import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/estimate_template_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/stage_model.dart';

class ProjectRepository {
  final Dio _dio;

  ProjectRepository({required Dio dio}) : _dio = dio;

  /// Получает список всех проектов.
  Future<List<ProjectModel>> fetchProjects() async {
    try {
      final response = await _dio.get('/projects/');
      final List<dynamic> data = response.data;
      return data.map((json) => ProjectModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("❌ Fetch Projects Error: $e");
      rethrow;
    }
  }

  /// Получает проект по ID.
  Future<ProjectModel> fetchProject(String id) async {
    try {
      final response = await _dio.get('/projects/$id/');
      return ProjectModel.fromJson(response.data);
    } catch (e) {
      debugPrint("❌ Fetch Project Error: $e");
      rethrow;
    }
  }

  /// Создает новый проект.
  /// [data] - данные проекта, включая init_stages.
  Future<ProjectModel> createProject(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/projects/', data: data);
      return ProjectModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Create Project Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Добавляет новый этап к проекту.
  Future<void> addStage(String projectId, String title) async {
    try {
      await _dio.post('/stages/', data: {
        'project': projectId,
        'title': title,
      });
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Add Stage Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Получает данные одного этапа (включая items)
  Future<StageModel> fetchStage(int stageId) async {
    try {
      final response = await _dio.get('/stages/$stageId/');
      return StageModel.fromJson(response.data);
    } catch (e) {
      debugPrint("❌ Fetch Stage Error: $e");
      rethrow;
    }
  }

  /// Обновляет статус этапа.
  /// Используем PATCH, чтобы обновить только статус.
  Future<void> updateStageStatus(String stageId, String status) async {
    try {
      await _dio.patch('/stages/$stageId/', data: {'status': status});
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Update Stage Status Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Удаляет проект по ID.
  Future<void> deleteProject(String id) async {
    try {
      await _dio.delete('/projects/$id/');
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Delete Project Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Обновляет данные проекта по ID.
  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/projects/$id/', data: data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Update Project Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Обновляет пункт сметы (кол-во, работодатель, и т.д.)
  Future<void> updateEstimateItem(int itemId, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/estimate-items/$itemId/', data: data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Update Estimate Item Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Получает отчет по этапу, опционально фильтруя по типу ('work' or 'material')
  Future<Map<String, String>> fetchStageReport(int stageId,
      {String? type}) async {
    try {
      final response = await _dio.get(
        '/stages/$stageId/get_report/',
        queryParameters: type != null ? {'type': type} : null,
      );
      return Map<String, String>.from(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Fetch Report Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Добавляет позицию в смету
  Future<void> addEstimateItem(Map<String, dynamic> data) async {
    try {
      await _dio.post('/estimate-items/', data: data);
    } catch (e) {
      if (e is DioException) {
        debugPrint("❌ Add Estimate Item Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Удаляет пункт сметы
  Future<void> deleteEstimateItem(int itemId) async {
    try {
      await _dio.delete('/estimate-items/$itemId/');
    } catch (e) {
      if (e is DioException) {
        debugPrint("❌ Delete Estimate Item Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Получает шаблоны смет
  Future<List<EstimateTemplateModel>> fetchEstimateTemplates() async {
    try {
      final response = await _dio.get('/estimate-templates/');
      final data = response.data as List<dynamic>;
      return data.map((json) => EstimateTemplateModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("❌ Fetch Templates Error: $e");
      rethrow;
    }
  }

  /// Применяет шаблон к этапу
  Future<void> applyTemplate(int stageId, int templateId) async {
    try {
      await _dio.post('/stages/$stageId/apply_template/', data: {
        'template_id': templateId,
      });
    } catch (e) {
      if (e is DioException) {
        debugPrint("❌ Apply Template Error: ${e.response?.data}");
      }
      rethrow;
    }
  }
}
