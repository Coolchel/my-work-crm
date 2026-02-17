import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/repositories/project_repository.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';

class _FakeProjectRepository extends ProjectRepository {
  _FakeProjectRepository() : super(dio: Dio());

  bool createProjectCalled = false;
  bool addStageCalled = false;

  @override
  Future<ProjectModel> createProject(Map<String, dynamic> data) async {
    createProjectCalled = true;
    return ProjectModel.fromJson({
      'id': 1,
      'address': data['address'] ?? 'Test',
      'object_type': data['object_type'] ?? 'new_building',
      'status': 'new',
      'intercom_code': data['intercom_code'] ?? '',
      'client_info': data['client_info'] ?? '',
      'source': data['source'] ?? '',
      'stages': const [],
      'shields': const [],
      'files': const [],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> addStage(String projectId, String title) async {
    addStageCalled = true;
  }

  @override
  Future<List<ProjectModel>> fetchProjects({String? search}) async {
    return [];
  }
}

void main() {
  test(
      'project operations addProject/addStage complete without async state error',
      () async {
    final fakeRepository = _FakeProjectRepository();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWith((ref) => fakeRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(projectOperationsProvider.notifier);

    await notifier.addProject({
      'address': 'addr',
      'object_type': 'new_building',
      'intercom_code': '',
      'client_info': '',
      'source': 'source',
      'init_stages': const <String>[],
    });

    await notifier.addStage('1', 'precalc');

    expect(fakeRepository.createProjectCalled, isTrue);
    expect(fakeRepository.addStageCalled, isTrue);
  });
}
