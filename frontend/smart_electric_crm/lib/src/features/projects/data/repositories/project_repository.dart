import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/estimate_template_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/project_file_model.dart';
import '../../data/models/stage_model.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

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

  /// Обновляет данные этапа (например, заметки)
  Future<void> updateStage(int stageId, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/stages/$stageId/', data: data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Update Stage Error: ${e.response?.data}");
      }
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

  /// Импорт материалов из инженерной карты (Щиты)
  Future<Map<String, dynamic>> importFromShields(int stageId) async {
    try {
      final response = await _dio.post('/stages/$stageId/import_from_shields/');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        debugPrint("❌ Import Shields Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Расчет работ на основе материалов
  Future<Map<String, dynamic>> calculateWorks(int stageId) async {
    try {
      final response = await _dio.post('/stages/$stageId/calculate_works/');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {}
      rethrow;
    }
  }

  /// Загружает файл проекта.
  Future<ProjectFileModel> uploadFile({
    required int projectId,
    required String filePath,
    required String category,
    String? fileName,
    String description = '',
  }) async {
    try {
      final file = File(filePath);
      final finalFileName = fileName ?? p.basename(file.path);

      final formData = FormData.fromMap({
        'project': projectId,
        'category': category,
        'description': description,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: finalFileName,
          contentType: _getMediaType(finalFileName),
        ),
      });

      final response = await _dio.post('/project-files/', data: formData);
      return ProjectFileModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        debugPrint("❌ Upload File Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Удаляет файл проекта.
  Future<void> deleteProjectFile(int fileId) async {
    try {
      await _dio.delete('/project-files/$fileId/');
    } catch (e) {
      if (e is DioException) {
        debugPrint("❌ Delete File Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  /// Обновляет данные файла проекта (например, имя)
  Future<void> updateProjectFile(int fileId, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/project-files/$fileId/', data: data);
    } catch (e) {
      if (e is DioException) {
        debugPrint("❌ Update File Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  MediaType _getMediaType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.pdf':
        return MediaType('application', 'pdf');
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
