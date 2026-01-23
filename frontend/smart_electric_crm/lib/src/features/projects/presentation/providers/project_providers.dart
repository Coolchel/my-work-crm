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
}
