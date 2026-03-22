import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/repositories/project_repository.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/screens/add_project_screen.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/project_detail/add_stage_dialog.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/desktop_dialog_foundation.dart';

class _FakeProjectRepository extends ProjectRepository {
  _FakeProjectRepository() : super(dio: Dio());

  Map<String, dynamic>? createPayload;
  String? updatedProjectId;
  Map<String, dynamic>? updatePayload;
  String? addStageProjectId;
  String? addedStageKey;

  @override
  Future<ProjectModel> createProject(Map<String, dynamic> data) async {
    createPayload = Map<String, dynamic>.from(data);
    return ProjectModel(
      id: 1,
      address: data['address'] as String? ?? '',
      objectType: data['object_type'] as String? ?? 'new_building',
      status: 'new',
      intercomCode: data['intercom_code'] as String? ?? '',
      clientInfo: data['client_info'] as String? ?? '',
      source: data['source'] as String? ?? '',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      stages: const [],
    );
  }

  @override
  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    updatedProjectId = id;
    updatePayload = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> addStage(String projectId, String title) async {
    addStageProjectId = projectId;
    addedStageKey = title;
  }

  @override
  Future<List<ProjectModel>> fetchProjects({String? search}) async => const [];
}

void main() {
  testWidgets(
    'AddProjectDialog uses desktop foundation on Windows and submits create payload',
    (tester) async {
      final repository = _FakeProjectRepository();

      await _pumpDialogHost(
        tester,
        size: const Size(1280, 900),
        repository: repository,
        dialogBuilder: () => const AddProjectDialog(),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'ул. Тестовая, д. 5',
      );
      await tester.tap(find.text('Этап 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Создать'));
      await tester.pumpAndSettle();

      expect(repository.createPayload, isNotNull);
      expect(repository.createPayload!['address'], 'ул. Тестовая, д. 5');
      expect(
        repository.createPayload!['init_stages'],
        contains('stage_1'),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'AddProjectDialog uses desktop foundation on Windows and preserves edit flow',
    (tester) async {
      final repository = _FakeProjectRepository();
      final project = ProjectModel(
        id: 42,
        address: 'ул. Старая, д. 1',
        objectType: 'cottage',
        status: 'active',
        intercomCode: '77',
        clientInfo: 'Иван',
        source: 'Владимир',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        stages: const [],
      );

      await _pumpDialogHost(
        tester,
        size: const Size(1280, 900),
        repository: repository,
        dialogBuilder: () => AddProjectDialog(project: project),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsOneWidget);
      expect(find.text('Редактировать объект'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'ул. Новая, д. 9',
      );
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(repository.updatedProjectId, '42');
      expect(repository.updatePayload, isNotNull);
      expect(repository.updatePayload!['address'], 'ул. Новая, д. 9');
      expect(repository.updatePayload!.containsKey('init_stages'), isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'AddStageDialog uses desktop foundation on Windows and keeps add-stage flow',
    (tester) async {
      final repository = _FakeProjectRepository();

      await _pumpDialogHost(
        tester,
        size: const Size(1280, 900),
        repository: repository,
        dialogBuilder: () => const AddStageDialog(
          projectId: '7',
          existingStageKeys: [],
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsOneWidget);

      await tester.tap(find.text('Этап 1 (Черновой)'));
      await tester.pumpAndSettle();

      expect(repository.addStageProjectId, '7');
      expect(repository.addedStageKey, 'stage_1');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Project dialogs keep mobile presentation path on Android',
    (tester) async {
      final repository = _FakeProjectRepository();

      await _pumpDialogHost(
        tester,
        size: const Size(390, 844),
        repository: repository,
        dialogBuilder: () => const AddProjectDialog(),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await _pumpDialogHost(
        tester,
        size: const Size(390, 844),
        repository: repository,
        dialogBuilder: () => const AddStageDialog(
          projectId: '7',
          existingStageKeys: [],
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}

Future<void> _pumpDialogHost(
  WidgetTester tester, {
  required Size size,
  required _FakeProjectRepository repository,
  required Widget Function() dialogBuilder,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;

  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectRepositoryProvider.overrideWith((ref) => repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: _DialogHost(dialogBuilder: dialogBuilder),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _DialogHost extends StatefulWidget {
  final Widget Function() dialogBuilder;

  const _DialogHost({required this.dialogBuilder});

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (_) => widget.dialogBuilder(),
            );
          },
          child: const Text('Open dialog'),
        ),
      ),
    );
  }
}
