import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/screens/project_list_screen.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/stages/stage_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'project list uses the same human-friendly dates as welcome',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();
      final project = ProjectModel.fromJson({
        'id': 1,
        'address': 'Объект с датами',
        'object_type': 'new_building',
        'status': 'new',
        'intercom_code': '',
        'client_info': '',
        'source': '',
        'stages': const [],
        'shields': const [],
        'files': const [],
        'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
        'updated_at':
            now.subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectListProvider.overrideWith((ref) async => [project]),
          ],
          child: const MaterialApp(
            home: ProjectListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('5 дн. назад'), findsOneWidget);
      expect(find.text('Вчера'), findsOneWidget);
    },
  );

  testWidgets(
    'stage card uses the shared human-friendly date formatting',
    (tester) async {
      final now = DateTime.now();
      final stage = StageModel(
        id: 1,
        title: 'stage_3',
        status: 'plan',
        isPaid: false,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1, hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageCard(
              stage: stage,
              onTap: () {},
              onStatusChanged: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('3 дн. назад'), findsOneWidget);
      expect(find.text('Вчера'), findsOneWidget);
    },
  );
}
