import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/screens/project_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProjectDetail files tab', () {
    testWidgets(
      'keeps narrow mobile file-group header assembled in one row',
      (tester) async {
        await _pumpProjectDetailFilesTab(
          tester,
          width: 390,
          platform: TargetPlatform.android,
          project: _buildProject(workFilesCount: 1),
        );

        final titleFinder = find.byKey(const ValueKey('file_group_title_WORK'));
        final countFinder = find.byKey(const ValueKey('file_group_count_WORK'));
        final uploadFinder =
            find.byKey(const ValueKey('file_group_upload_WORK'));
        final limitButtonFinder =
            find.byKey(const ValueKey('files_limit_info_button'));

        expect(titleFinder, findsOneWidget);
        expect(countFinder, findsOneWidget);
        expect(uploadFinder, findsOneWidget);
        expect(limitButtonFinder, findsOneWidget);

        final titleText = tester.widget<Text>(titleFinder);
        final titleRect = tester.getRect(titleFinder);
        final countRect = tester.getRect(countFinder);
        final uploadRect = tester.getRect(uploadFinder);

        expect(titleText.maxLines, 2);
        expect(titleText.overflow, TextOverflow.ellipsis);
        expect(find.text('1 файл'), findsOneWidget);
        expect(
            find.byKey(const ValueKey('files_limit_info_block')), findsNothing);
        /*
        expect(find.text('До 12 файлов на проект'), findsOneWidget);
        expect(find.text('Сейчас 1 из 12, до 20 МБ на файл'), findsOneWidget);
        */
        expect(countRect.top, lessThan(titleRect.bottom));
        expect(uploadRect.top, lessThan(titleRect.bottom));

        await tester.tap(limitButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('files_limit_info_block')),
            findsOneWidget);
        expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
        /*
        expect(find.text('Р”Рѕ 12 С„Р°Р№Р»РѕРІ РЅР° РїСЂРѕРµРєС‚'),
            findsOneWidget);
        expect(find.text('РЎРµР№С‡Р°СЃ 1 РёР· 12, РґРѕ 20 РњР‘ РЅР° С„Р°Р№Р»'),
            findsOneWidget);

        */
        await tester
            .tap(find.byKey(const ValueKey('files_limit_info_dismiss_area')));
        await tester.pumpAndSettle();

        expect(
            find.byKey(const ValueKey('files_limit_info_block')), findsNothing);
      },
    );

    testWidgets(
      'shows explicit file action entry point on Android and opens actions menu',
      (tester) async {
        await _pumpProjectDetailFilesTab(
          tester,
          width: 390,
          platform: TargetPlatform.android,
          project: _buildProject(workFilesCount: 1),
        );

        final actionEntryFinder =
            find.byKey(const ValueKey('file_action_entry_1'));

        expect(actionEntryFinder, findsOneWidget);

        await tester.longPress(find.text('work_1.pdf'));
        await tester.pumpAndSettle();

        expect(find.text('Переименовать'), findsNothing);

        await tester.tap(actionEntryFinder);
        await tester.pumpAndSettle();

        expect(find.text('Переименовать'), findsOneWidget);
        expect(find.text('Сохранить как...'), findsOneWidget);
        expect(find.text('Поделиться'), findsOneWidget);
        expect(find.text('Удалить'), findsOneWidget);
      },
    );

    testWidgets(
      'keeps desktop header compact while preserving visible action entry point',
      (tester) async {
        await _pumpProjectDetailFilesTab(
          tester,
          width: 1100,
          platform: TargetPlatform.windows,
          project: _buildProject(projectFilesCount: 2),
        );

        final titleFinder = find.text('Проекты и схемы');
        expect(titleFinder, findsOneWidget);

        final titleText = tester.widget<Text>(titleFinder);
        expect(titleText.maxLines, 1);
        expect(find.text('2 файла'), findsOneWidget);
        expect(
            find.byKey(const ValueKey('file_action_entry_1')), findsOneWidget);
        expect(
            find.byKey(const ValueKey('file_action_entry_2')), findsOneWidget);

        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);
        await gesture.addPointer();
        await gesture.moveTo(tester.getCenter(find.text('project_1.pdf')));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_rounded), findsNothing);
        expect(find.byIcon(Icons.download_rounded), findsNothing);
        expect(find.byIcon(Icons.close_rounded), findsNothing);
      },
    );
  });
}

Future<void> _pumpProjectDetailFilesTab(
  WidgetTester tester, {
  required double width,
  required TargetPlatform platform,
  required ProjectModel project,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  debugDefaultTargetPlatformOverride = platform;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    debugDefaultTargetPlatformOverride = null;
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectByIdProvider('1').overrideWith((ref) async => project),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const ProjectDetailScreen(
          projectId: '1',
          initialTab: ProjectDetailSection.files,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
  debugDefaultTargetPlatformOverride = null;
}

ProjectModel _buildProject({
  int projectFilesCount = 0,
  int workFilesCount = 0,
}) {
  return ProjectModel.fromJson({
    'id': 1,
    'address': 'ул. Тестовая, 12',
    'object_type': 'new_building',
    'status': 'new',
    'intercom_code': '',
    'client_info': 'Иван Петров',
    'source': 'Рекомендация',
    'stages': const [],
    'shields': const [],
    'files': [
      for (var i = 0; i < projectFilesCount; i++)
        {
          'id': i + 1,
          'project': 1,
          'file': '/media/files/project_${i + 1}.pdf',
          'description': '',
          'category': 'PROJECT',
          'original_name': 'project_${i + 1}.pdf',
        },
      for (var i = 0; i < workFilesCount; i++)
        {
          'id': projectFilesCount + i + 1,
          'project': 1,
          'file': '/media/files/work_${i + 1}.pdf',
          'description': '',
          'category': 'WORK',
          'original_name': 'work_${i + 1}.pdf',
        },
    ],
    'created_at': DateTime(2026, 3, 1).toIso8601String(),
    'updated_at': DateTime(2026, 3, 2).toIso8601String(),
  });
}
