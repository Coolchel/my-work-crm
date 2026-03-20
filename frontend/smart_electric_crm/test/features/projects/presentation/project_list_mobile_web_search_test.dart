import 'package:flutter/foundation.dart';
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
    'mobile web keeps the search field mounted so opening search focuses it immediately',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final project = _project(
        id: 1,
        address: 'РњРѕР±РёР»СЊРЅС‹Р№ web',
      );
      final searchProject = _project(
        id: 2,
        address: 'РќР°Р№РґРµРЅРЅС‹Р№ mobile web',
        intercomCode: '1234',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectListProvider.overrideWith((ref) async => [project]),
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

      final searchField = find.byKey(const Key('project_list_search_field'));
      expect(searchField, findsOneWidget);
      expect(find.text(ProjectSearchTexts.hint), findsNothing);

      final focusNode = tester.widget<TextField>(searchField).focusNode!;
      expect(focusNode.hasFocus, isFalse);

      await tester.tap(find.byTooltip('РџРѕРёСЃРє'));
      await tester.idle();

      expect(focusNode.hasFocus, isTrue);

      await tester.pumpAndSettle();

      expect(find.text(ProjectSearchTexts.hint), findsOneWidget);

      await tester.enterText(searchField, '1234');
      await tester.pumpAndSettle();

      expect(find.text('РќР°Р№РґРµРЅРЅС‹Р№ mobile web'), findsOneWidget);

      await tester.tap(find.byTooltip('РџРѕРёСЃРє'));
      await tester.pumpAndSettle();

      expect(find.text('РќР°Р№РґРµРЅРЅС‹Р№ mobile web'), findsNothing);
    },
    skip: !kIsWeb,
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
    'updated_at': DateTime(2026, 3, 2).toIso8601String(),
  });
}
