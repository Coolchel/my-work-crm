import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/screens/project_list_screen.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/search/project_search_texts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'objects search uses separate backend layer and unified hint',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final baseProject = _project(
        id: 1,
        address: 'Базовый объект',
      );
      final searchProject = _project(
        id: 2,
        address: 'Найден через backend',
        intercomCode: '1234',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectListProvider.overrideWith((ref) async => [baseProject]),
            objectsProjectSearchResultsProvider.overrideWith(
              (ref) async => [searchProject],
            ),
          ],
          child: const MaterialApp(
            home: ProjectListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Базовый объект'), findsOneWidget);

      await tester.tap(find.byTooltip('Поиск'));
      await tester.pumpAndSettle();

      expect(find.text(ProjectSearchTexts.hint), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();

      expect(find.text('Найден через backend'), findsOneWidget);

      await tester.tap(find.byTooltip('Поиск'));
      await tester.pumpAndSettle();

      expect(find.text('Найден через backend'), findsNothing);
      expect(find.text('Базовый объект'), findsOneWidget);
    },
  );
}

ProjectModel _project({
  required int id,
  required String address,
  String intercomCode = '',
}) {
  return ProjectModel.fromJson({
    'id': id,
    'address': address,
    'object_type': 'new_building',
    'status': 'new',
    'intercom_code': intercomCode,
    'client_info': '',
    'source': '',
    'stages': const [],
    'shields': const [],
    'files': const [],
    'created_at': DateTime(2026, 3, 1).toIso8601String(),
    'updated_at': DateTime(2026, 3, 1).toIso8601String(),
  });
}
