import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/project_model.dart';

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
}
