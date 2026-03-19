import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/screens/project_detail_screen.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/stages/stage_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'ProjectDetail separates object summary block from stage cards',
    (tester) async {
      final project = ProjectModel.fromJson({
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
        'shields': const [],
        'files': const [],
        'created_at': DateTime(2026, 3, 1).toIso8601String(),
        'updated_at': DateTime(2026, 3, 2).toIso8601String(),
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
              initialTab: ProjectDetailSection.stages,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Об объекте'), findsOneWidget);
      expect(find.text('Сводка'), findsNothing);
      expect(find.text('ул. Тестовая, 12'), findsWidgets);
      expect(
          find.widgetWithText(SelectableText, 'Иван Петров'), findsOneWidget);

      final stageTitle = StageCard.getStageTitleDisplay('stage_1');
      expect(find.text(stageTitle), findsOneWidget);

      final summaryTitleRect =
          tester.getRect(find.text('ул. Тестовая, 12').first);
      final stageTitleRect = tester.getRect(find.text(stageTitle));

      expect(summaryTitleRect.top, lessThan(stageTitleRect.top));
      expect(find.byType(StageCard), findsOneWidget);
    },
  );
}
