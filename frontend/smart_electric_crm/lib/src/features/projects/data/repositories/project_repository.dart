import 'package:dio/dio.dart';
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
      // Можно добавить более сложную обработку ошибок или логирование
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
      rethrow;
    }
  }
}
