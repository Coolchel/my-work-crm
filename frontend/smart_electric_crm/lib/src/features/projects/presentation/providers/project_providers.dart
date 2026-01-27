import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/project_model.dart';
import '../../data/repositories/project_repository.dart';
import '../../../../core/api/dio_client.dart';

part 'project_providers.g.dart';

/// Провайдер репозитория проектов
@riverpod
ProjectRepository projectRepository(ProjectRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return ProjectRepository(dio: dio);
}

/// Провайдер списка проектов.
/// Использует AsyncNotifier для управления состоянием загрузки и данных.
@riverpod
class ProjectList extends _$ProjectList {
  @override
  FutureOr<List<ProjectModel>> build() async {
    final repository = ref.watch(projectRepositoryProvider);
    return repository.fetchProjects();
  }

  /// Добавляет проект и обновляет список.
  Future<void> addProject(Map<String, dynamic> data) async {
    final repository = ref.read(projectRepositoryProvider);
    // Устанавливаем состояние загрузки, если нужно, или просто ждем
    // state = const AsyncValue.loading(); // Можно раскомментировать для индикации

    // Сначала выполняем запрос
    await repository.createProject(data);

    // Инвалидируем провайдер, чтобы он перезагрузил данные с сервера
    ref.invalidateSelf();

    // Ожидаем завершения будущей загрузки, чтобы UI обновился (опционально)
    await future;
  }

  /// Добавляет этап к проекту и обновляет список.
  Future<void> addStage(String projectId, String title) async {
    final repository = ref.read(projectRepositoryProvider);

    // Выполняем запрос
    await repository.addStage(projectId, title);

    // Инвалидируем провайдер, чтобы обновить данные (включая новые этапы)
    ref.invalidateSelf();

    await future;
  }

  /// Обновляет статус этапа и обновляет список.
  Future<void> updateStageStatus(String stageId, String status) async {
    final repository = ref.read(projectRepositoryProvider);

    await repository.updateStageStatus(stageId, status);

    // Инвалидируем провайдер
    ref.invalidateSelf();
    await future;
  }

  /// Удаляет проект и обновляет список.
  Future<void> deleteProject(String id) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.deleteProject(id);
    ref.invalidateSelf();
    await future;
  }

  /// Обновляет проект и обновляет список.
  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.updateProject(id, data);
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<ProjectModel> projectById(ProjectByIdRef ref, String id) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.fetchProject(id);
}

/// Провайдер для управления отображением цен (для режима "Без цен")
final showPricesProvider = StateProvider<bool>((ref) => true);
