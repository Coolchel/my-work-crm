import 'package:dio/dio.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import 'dart:typed_data';
import '../../data/models/project_model.dart';
import '../../data/models/project_file_model.dart';
import '../../data/models/stage_model.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class ProjectRepository {
  final Dio _dio;

  ProjectRepository({required Dio dio}) : _dio = dio;
  Never _throwApiError(
    Object error,
    StackTrace stackTrace, {
    required String fallbackMessage,
  }) {
    if (error is DioException) {
      throw ApiException.fromDio(error, fallbackMessage: fallbackMessage);
    }
    Error.throwWithStackTrace(error, stackTrace);
  }

  /// Получает список всех проектов.
  Future<List<ProjectModel>> fetchProjects({String? search}) async {
    try {
      final response = await _dio.get(
        '/projects/',
        queryParameters:
            search != null && search.isNotEmpty ? {'search': search} : null,
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ProjectModel.fromJson(json)).toList();
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to fetch projects');
    }
  }

  /// Получает проект по ID.
  Future<ProjectModel> fetchProject(String id) async {
    try {
      final response = await _dio.get('/projects/$id/');
      return ProjectModel.fromJson(response.data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to fetch project');
    }
  }

  /// Создает новый проект.
  /// [data] - данные проекта, включая init_stages.
  Future<ProjectModel> createProject(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/projects/', data: data);
      return ProjectModel.fromJson(response.data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to create project');
    }
  }

  /// Добавляет новый этап к проекту.
  Future<void> addStage(String projectId, String title) async {
    try {
      await _dio.post('/stages/', data: {
        'project': projectId,
        'title': title,
      });
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to add stage');
    }
  }

  /// Получает данные одного этапа (включая items)
  Future<StageModel> fetchStage(int stageId) async {
    try {
      final response = await _dio.get('/stages/$stageId/');
      return StageModel.fromJson(response.data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to fetch stage');
    }
  }

  /// Обновляет данные этапа (например, заметки)
  Future<void> updateStage(int stageId, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/stages/$stageId/', data: data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to update stage');
    }
  }

  /// Обновляет статус этапа.
  /// Используем PATCH, чтобы обновить только статус.
  Future<void> updateStageStatus(String stageId, String status) async {
    try {
      await _dio.patch('/stages/$stageId/', data: {'status': status});
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to update stage status');
    }
  }

  /// Удаляет этап по ID
  Future<void> deleteStage(int stageId) async {
    try {
      await _dio.delete('/stages/$stageId/');
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to delete stage');
    }
  }

  /// Удаляет проект по ID.
  Future<void> deleteProject(String id) async {
    try {
      await _dio.delete('/projects/$id/');
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to delete project');
    }
  }

  /// Обновляет данные проекта по ID.
  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/projects/$id/', data: data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to update project');
    }
  }

  /// Обновляет пункт сметы (кол-во, работодатель, и т.д.)
  Future<void> updateEstimateItem(int itemId, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/estimate-items/$itemId/', data: data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to update estimate item');
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
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to fetch stage report');
    }
  }

  /// Добавляет позицию в смету
  Future<void> addEstimateItem(Map<String, dynamic> data) async {
    try {
      await _dio.post('/estimate-items/', data: data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to add estimate item');
    }
  }

  /// Удаляет пункт сметы
  Future<void> deleteEstimateItem(int itemId) async {
    try {
      await _dio.delete('/estimate-items/$itemId/');
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to delete estimate item');
    }
  }

  /// Импорт материалов из инженерной карты (Щиты)
  Future<Map<String, dynamic>> importFromShields(int stageId) async {
    try {
      final response = await _dio.post('/stages/$stageId/import_from_shields/');
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _throwApiError(e, st,
          fallbackMessage: 'Failed to import data from shields');
    }
  }

  /// Расчет работ на основе материалов
  Future<Map<String, dynamic>> calculateWorks(int stageId) async {
    try {
      final response = await _dio.post('/stages/$stageId/calculate_works/');
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to calculate works');
    }
  }

  Future<Map<String, dynamic>> importFromPrecalcSection(
    int stageId, {
    required String itemType,
  }) async {
    try {
      final response = await _dio.post(
        '/stages/$stageId/import_from_precalc_section/',
        data: {'item_type': itemType},
      );
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _throwApiError(e, st,
          fallbackMessage: 'Failed to import from precalc section');
    }
  }

  Future<Map<String, dynamic>> applyStage3Armature(
    int stageId,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      final response = await _dio.post(
        '/stages/$stageId/apply_stage3_armature/',
        data: rows,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to apply stage3 armature');
    }
  }

  /// Загружает файл проекта.
  Future<ProjectFileModel> uploadFile({
    required int projectId,
    required String category,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    String description = '',
  }) async {
    try {
      final normalizedPath = filePath?.trim();
      final finalFileName = _resolveUploadFileName(
        fileName: fileName,
        filePath: normalizedPath,
      );

      final formData = FormData.fromMap({
        'project': projectId,
        'category': category,
        'description': description,
        'file': await _buildUploadMultipartFile(
          fileName: finalFileName,
          filePath: normalizedPath,
          fileBytes: fileBytes,
        ),
      });

      final response = await _dio.post(
        '/project-files/',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return ProjectFileModel.fromJson(response.data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to upload project file');
    }
  }

  /// Удаляет файл проекта.
  Future<void> deleteProjectFile(int fileId) async {
    try {
      await _dio.delete('/project-files/$fileId/');
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to delete project file');
    }
  }

  /// Обновляет данные файла проекта (например, имя)
  Future<void> updateProjectFile(int fileId, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/project-files/$fileId/', data: data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to update project file');
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

  String _resolveUploadFileName({
    String? fileName,
    String? filePath,
  }) {
    final normalizedName = fileName?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      return normalizedName;
    }
    if (filePath != null && filePath.isNotEmpty) {
      return p.basename(filePath);
    }
    throw ArgumentError('Upload requires a file name or file path.');
  }

  Future<MultipartFile> _buildUploadMultipartFile({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    final contentType = _getMediaType(fileName);

    if (fileBytes != null) {
      return MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: contentType,
      );
    }

    if (filePath != null && filePath.isNotEmpty) {
      return MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: contentType,
      );
    }

    throw ArgumentError('Upload requires file bytes or a file path.');
  }
}
