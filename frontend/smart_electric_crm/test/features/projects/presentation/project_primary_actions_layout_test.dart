import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/screens/project_detail_screen.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/screens/project_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'ProjectList uses header add action instead of FAB on Windows',
    (tester) async {
      await _pumpProjectList(
        tester,
        width: 1280,
        project: _buildProject(),
      );

      expect(find.byKey(const ValueKey('project_list_add_action')),
          findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'ProjectDetail stages tab shows contextual add action instead of FAB on Windows',
    (tester) async {
      await _pumpProjectDetail(
        tester,
        width: 1280,
        project: _buildProject(),
        initialTab: ProjectDetailSection.stages,
      );

      expect(
        find.byKey(const ValueKey('project_detail_add_stage_action')),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'ProjectDetail shields tab shows add shield card instead of FAB on Windows',
    (tester) async {
      await _pumpProjectDetail(
        tester,
        width: 1280,
        project: _buildProject(withShield: true),
        initialTab: ProjectDetailSection.shields,
      );

      expect(
        find.byKey(const ValueKey('engineering_add_shield_card')),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}

Future<void> _pumpProjectList(
  WidgetTester tester, {
  required double width,
  required ProjectModel project,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectListProvider.overrideWith((ref) async => [project]),
      ],
      child: MaterialApp(
        theme: AppTheme.light().copyWith(platform: TargetPlatform.windows),
        home: const ProjectListScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _pumpProjectDetail(
  WidgetTester tester, {
  required double width,
  required ProjectModel project,
  required ProjectDetailSection initialTab,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectByIdProvider('1').overrideWith((ref) async => project),
      ],
      child: MaterialApp(
        theme: AppTheme.light().copyWith(platform: TargetPlatform.windows),
        home: ProjectDetailScreen(
          projectId: '1',
          initialTab: initialTab,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

ProjectModel _buildProject({
  bool withShield = false,
}) {
  return ProjectModel.fromJson({
    'id': 1,
    'address': 'ул. Тестовая, 12',
    'object_type': 'new_building',
    'status': 'new',
    'intercom_code': '',
    'client_info': 'Иван Петров',
    'source': 'Рекомендация',
    'stages': [
      {
        'id': 10,
        'title': 'stage_1',
        'status': 'plan',
        'is_paid': false,
        'estimate_items': const [],
        'created_at': DateTime(2026, 3, 1).toIso8601String(),
        'updated_at': DateTime(2026, 3, 2).toIso8601String(),
      },
    ],
    'shields': withShield
        ? [
            {
              'id': 7,
              'project': 1,
              'name': 'Щит 1',
              'shield_type': 'power',
              'mounting': 'internal',
              'groups': const [],
              'led_zones': const [],
              'internet_lines_count': 0,
              'multimedia_notes': '',
              'notes': '',
              'suggested_size': null,
            },
          ]
        : const [],
    'files': const [],
    'created_at': DateTime(2026, 3, 1).toIso8601String(),
    'updated_at': DateTime(2026, 3, 2).toIso8601String(),
  });
}
