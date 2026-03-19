import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/screens/project_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Project card action placement', () {
    testWidgets(
      'keeps actions at title height and near the card right edge with a short title',
      (tester) async {
        const address = 'Короткий адрес';
        await _pumpScreen(
          tester,
          width: 900,
          address: address,
        );

        _expectActionsAlignedAndRightAnchored(
          tester,
          address: address,
        );
      },
    );

    testWidgets(
      'keeps actions at title height and near the card right edge with a long two-line title',
      (tester) async {
        const address =
            'Очень длинное название объекта для проверки переноса заголовка на две строки в карточке проекта';
        await _pumpScreen(
          tester,
          width: 360,
          address: address,
        );

        _expectActionsAlignedAndRightAnchored(
          tester,
          address: address,
        );
      },
    );
  });

  group('Project card title hierarchy', () {
    testWidgets(
      'uses cardTitle typography on desktop layout',
      (tester) async {
        const address = 'Desktop title hierarchy';

        await _pumpScreen(
          tester,
          width: 900,
          address: address,
        );

        _expectTitleUsesCardTitleStyle(
          tester,
          address: address,
        );
      },
    );

    testWidgets(
      'uses cardTitle typography on mobile layout',
      (tester) async {
        const address =
            'Mobile title hierarchy for a longer address that should still stay readable';

        await _pumpScreen(
          tester,
          width: 360,
          address: address,
        );

        _expectTitleUsesCardTitleStyle(
          tester,
          address: address,
        );
      },
    );
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required double width,
  required String address,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1200);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final project = ProjectModel.fromJson({
    'id': 1,
    'address': address,
    'object_type': 'new_building',
    'status': 'new',
    'intercom_code': '',
    'client_info': '',
    'source': '',
    'stages': const [],
    'shields': const [],
    'files': const [],
    'created_at': DateTime(2026, 3, 1).toIso8601String(),
    'updated_at': DateTime(2026, 3, 1).toIso8601String(),
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
}

void _expectActionsAlignedAndRightAnchored(
  WidgetTester tester, {
  required String address,
}) {
  final cardFinder = find.byType(AnimatedContainer).first;
  final titleFinder = find.text(address);
  final editFinder = find.byIcon(Icons.edit_outlined);
  final deleteFinder = find.byIcon(Icons.close);

  expect(cardFinder, findsOneWidget);
  expect(titleFinder, findsOneWidget);
  expect(editFinder, findsOneWidget);
  expect(deleteFinder, findsOneWidget);

  final cardRect = tester.getRect(cardFinder);
  final titleRect = tester.getRect(titleFinder);
  final editRect = tester.getRect(editFinder);
  final deleteRect = tester.getRect(deleteFinder);

  expect((editRect.top - titleRect.top).abs(), lessThanOrEqualTo(2));
  expect((deleteRect.top - titleRect.top).abs(), lessThanOrEqualTo(2));
  expect((editRect.top - deleteRect.top).abs(), lessThanOrEqualTo(2));
  expect(cardRect.right - deleteRect.right, lessThanOrEqualTo(24));
}

void _expectTitleUsesCardTitleStyle(
  WidgetTester tester, {
  required String address,
}) {
  final titleFinder = find.text(address);

  expect(titleFinder, findsOneWidget);

  final titleText = tester.widget<Text>(titleFinder);
  final titleContext = tester.element(titleFinder);
  final expectedStyle = Theme.of(titleContext).appTextStyles.cardTitle.copyWith(
        color: Theme.of(titleContext).colorScheme.onSurface,
      );

  expect(titleText.style?.fontSize, expectedStyle.fontSize);
  expect(titleText.style?.fontWeight, expectedStyle.fontWeight);
  expect(titleText.style?.height, expectedStyle.height);
  expect(titleText.style?.letterSpacing, expectedStyle.letterSpacing);
  expect(titleText.maxLines, 2);
  expect(titleText.overflow, TextOverflow.ellipsis);
}
