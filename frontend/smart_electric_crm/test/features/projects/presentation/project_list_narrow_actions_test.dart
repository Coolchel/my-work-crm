import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/screens/project_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'narrow objects screen keeps search and filter actions visible and usable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final project = ProjectModel.fromJson({
        'id': 1,
        'address': 'Узкий экран',
        'object_type': 'new_building',
        'status': 'new',
        'intercom_code': '',
        'client_info': '',
        'source': '',
        'stages': const [],
        'shields': const [],
        'files': const [],
        'created_at': DateTime(2026, 3, 1).toIso8601String(),
        'updated_at': DateTime(2026, 3, 2).toIso8601String(),
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectListProvider.overrideWith((ref) async => [project]),
            objectsProjectSearchResultsProvider.overrideWith(
              (ref) async => [project],
            ),
          ],
          child: const MaterialApp(
            home: ProjectListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final searchAction = find.byTooltip('Поиск');
      final filterAction = find.byTooltip('Фильтры');

      expect(searchAction, findsOneWidget);
      expect(filterAction, findsOneWidget);

      final viewportRight = tester.view.physicalSize.width;
      expect(tester.getTopRight(searchAction).dx,
          lessThanOrEqualTo(viewportRight));
      expect(tester.getTopRight(filterAction).dx,
          lessThanOrEqualTo(viewportRight));

      await tester.tap(searchAction);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
