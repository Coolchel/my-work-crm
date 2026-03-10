import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_file_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/repositories/project_repository.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';

class _FakeProjectRepository extends ProjectRepository {
  _FakeProjectRepository() : super(dio: Dio());

  bool createProjectCalled = false;
  bool addStageCalled = false;
  int? lastUploadProjectId;
  String? lastUploadPath;
  Uint8List? lastUploadBytes;
  String? lastUploadName;
  String? lastUploadCategory;

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

  @override
  Future<ProjectFileModel> uploadFile({
    required int projectId,
    required String category,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    String description = '',
  }) async {
    lastUploadProjectId = projectId;
    lastUploadPath = filePath;
    lastUploadBytes = fileBytes;
    lastUploadName = fileName;
    lastUploadCategory = category;

    return ProjectFileModel(
      id: 1,
      project: projectId,
      file: '/media/project_files/test.txt',
      description: description,
      category: category,
      originalName: fileName ?? 'test.txt',
    );
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

  test('project operations uploadFile forwards bytes-based uploads', () async {
    final fakeRepository = _FakeProjectRepository();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWith((ref) => fakeRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(projectOperationsProvider.notifier);
    final fileBytes = Uint8List.fromList([1, 2, 3, 4]);

    await notifier.uploadFile(
      projectId: 42,
      category: 'PROJECT',
      fileBytes: fileBytes,
      fileName: 'web-upload.txt',
    );

    expect(fakeRepository.lastUploadProjectId, 42);
    expect(fakeRepository.lastUploadPath, isNull);
    expect(fakeRepository.lastUploadBytes, fileBytes);
    expect(fakeRepository.lastUploadName, 'web-upload.txt');
    expect(fakeRepository.lastUploadCategory, 'PROJECT');
  });
}
