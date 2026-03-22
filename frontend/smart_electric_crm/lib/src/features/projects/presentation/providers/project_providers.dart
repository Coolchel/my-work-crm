import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/project_model.dart';
import '../../data/models/stage_model.dart';
import '../../data/repositories/project_repository.dart';
import '../../../../core/api/dio_client.dart';

part 'project_providers.g.dart';

/// Провайдер репозитория проектов
@riverpod
ProjectRepository projectRepository(ProjectRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return ProjectRepository(dio: dio);
}

/// Провайдер для строки поиска
final projectSearchQueryProvider = StateProvider<String?>((ref) => null);

String? normalizeProjectSearchQuery(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

/// Провайдер для строки поиска на экране объектов.
final objectsProjectSearchQueryProvider = StateProvider<String?>((ref) => null);

// Провайдер для списка проектов (основной, без поиска)
final projectListProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  // This provider now ONLY fetches the full list, ignoring the search query for the main screen
  return repository.fetchProjects();
});

// Провайдер для результатов поиска
final projectSearchResultsProvider =
    FutureProvider<List<ProjectModel>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  final searchQuery = ref.watch(projectSearchQueryProvider);

  final normalizedQuery = normalizeProjectSearchQuery(searchQuery);
  if (normalizedQuery == null) {
    return [];
  }

  return repository.fetchProjects(search: normalizedQuery);
});

/// Провайдер для backend search-результатов на экране объектов.
final objectsProjectSearchResultsProvider =
    FutureProvider<List<ProjectModel>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  final searchQuery = ref.watch(objectsProjectSearchQueryProvider);

  final normalizedQuery = normalizeProjectSearchQuery(searchQuery);
  if (normalizedQuery == null) {
    return [];
  }

  return repository.fetchProjects(search: normalizedQuery);
});

/// Провайдер для управления операциями с проектами (добавление, обновление, удаление).
/// Использует AsyncNotifier для управления состоянием загрузки и данных.
/// Провайдер для управления операциями с проектами (добавление, обновление, удаление).
/// Использует AsyncNotifier для управления состоянием загрузки и данных.
@riverpod
class ProjectOperations extends _$ProjectOperations {
  @override
  FutureOr<void> build() {
    // No initial state needed for operations, just a way to access methods.
    return null;
  }

  /// Добавляет проект и обновляет список.
  Future<void> addProject(Map<String, dynamic> data) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.createProject(data);
    ref.invalidate(projectListProvider);
  }

  /// Добавляет этап к проекту и обновляет список.
  Future<void> addStage(String projectId, String title) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.addStage(projectId, title);
    ref.invalidate(projectListProvider);
    ref.invalidate(projectByIdProvider(projectId));
  }

  /// Обновляет статус этапа и обновляет список.
  Future<void> updateStageStatus(String stageId, String status) async {
    final repository = ref.read(projectRepositoryProvider);
    // Optimistic update could be done here, but for now just invalidate
    await repository.updateStageStatus(stageId, status);
    ref.invalidate(projectListProvider);
  }

  /// Удаляет проект и обновляет список.
  Future<void> deleteProject(String id) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.deleteProject(id);
    ref.invalidate(projectListProvider);
  }

  /// Обновляет проект и обновляет список.
  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.updateProject(id, data);
    ref.invalidate(projectListProvider);
    ref.invalidate(projectByIdProvider(id));
  }

  /// Загружает файл проекта.
  Future<void> uploadFile({
    required int projectId,
    required String category,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    String description = '',
  }) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.uploadFile(
      projectId: projectId,
      filePath: filePath,
      fileBytes: fileBytes,
      category: category,
      fileName: fileName,
      description: description,
    );
    ref.invalidate(projectListProvider);
    ref.invalidate(projectByIdProvider(projectId.toString()));
  }

  /// Удаляет файл проекта.
  Future<void> deleteFile(int fileId, String projectId) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.deleteProjectFile(fileId);
    ref.invalidate(projectListProvider);
    ref.invalidate(projectByIdProvider(projectId));
  }

  /// Переименовывает файл проекта.
  Future<void> renameFile(int fileId, String newName, String projectId) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.updateProjectFile(fileId, {'original_name': newName});
    ref.invalidate(projectListProvider);
    ref.invalidate(projectByIdProvider(projectId));
  }
}

@riverpod
Future<ProjectModel> projectById(ProjectByIdRef ref, String id) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.fetchProject(id);
}

/// Провайдер для управления отображением цен (для режима "Без цен")
final showPricesProvider = StateProvider<bool>((ref) => true);

/// Провайдер для фильтрации проектов на главном экране (Welcome Screen)
/// Возможные значения: 'pre_calc', 'active_objects', 'paid', или null (без фильтра)
final stageByIdProvider =
    FutureProvider.family<StageModel, int>((ref, id) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.fetchStage(id);
});

final dashboardFilterProvider = StateProvider<String?>((ref) => null);
