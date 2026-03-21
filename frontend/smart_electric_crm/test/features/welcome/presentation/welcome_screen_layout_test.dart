import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/welcome/presentation/screens/welcome_screen.dart';
import 'package:smart_electric_crm/src/features/welcome/presentation/widgets/smart_search_bar.dart';
import 'package:smart_electric_crm/src/features/welcome/presentation/widgets/welcome_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  testWidgets(
    'mobile welcome keeps header inside the scrollable content',
    (tester) async {
      await _pumpWelcomeScreen(
        tester,
        width: 390,
        height: 844,
      );

      expect(find.byType(WelcomeHeader), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(WelcomeHeader),
        ),
        findsOneWidget,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'mobile welcome applies bottom scroll padding for content ending',
    (tester) async {
      await _pumpWelcomeScreen(
        tester,
        width: 390,
        height: 844,
      );

      final mainScrollView = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .firstWhere((widget) => widget.controller != null);
      final padding = mainScrollView.padding as EdgeInsets;

      expect(padding.bottom, greaterThan(0));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'windows welcome search shows results without render overflow',
    (tester) async {
      final baseProject = _project(
        id: 1,
        address: 'Базовый объект',
      );
      final searchProject = _project(
        id: 2,
        address: 'Найденный объект',
      );

      await _pumpWelcomeScreen(
        tester,
        width: 1280,
        height: 720,
        projects: [baseProject],
        searchResults: [searchProject],
      );

      await tester.ensureVisible(find.byType(TextField));
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Найденный');
      await tester.pumpAndSettle();

      expect(find.byType(SmartSearchBar), findsOneWidget);
      expect(find.text('Найденный объект'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'windows welcome shows top fade mask over scrollable content',
    (tester) async {
      await _pumpWelcomeScreen(
        tester,
        width: 1280,
        height: 900,
      );

      expect(
        find.byKey(const Key('welcome_desktop_top_fade_mask')),
        findsOneWidget,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'windows welcome keeps a right gutter for the desktop scrollbar',
    (tester) async {
      await _pumpWelcomeScreen(
        tester,
        width: 1280,
        height: 900,
      );

      final mainScrollView = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .firstWhere((widget) => widget.controller != null);
      final padding = mainScrollView.padding as EdgeInsets;

      expect(padding.right, greaterThan(0));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}

Future<void> _pumpWelcomeScreen(
  WidgetTester tester, {
  required double width,
  required double height,
  List<ProjectModel> projects = const [],
  List<ProjectModel> searchResults = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectListProvider.overrideWith((ref) async => projects),
        projectSearchResultsProvider.overrideWith((ref) async => searchResults),
      ],
      child: const MaterialApp(
        home: WelcomeScreen(
          onSettingsPressed: _noop,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

ProjectModel _project({
  required int id,
  required String address,
}) {
  return ProjectModel.fromJson({
    'id': id,
    'address': address,
    'object_type': 'new_building',
    'status': 'new',
    'intercom_code': '',
    'client_info': '',
    'source': '',
    'stages': const [],
    'shields': const [],
    'files': const [],
    'created_at':
        DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    'updated_at':
        DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
  });
}

void _noop() {}
