import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/stages/stage_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StageCard title hierarchy', () {
    testWidgets(
      'uses cardTitle typography on desktop layout',
      (tester) async {
        const rawTitle = 'stage_1';

        await _pumpStageCard(
          tester,
          width: 920,
          platform: TargetPlatform.windows,
          stage: _buildStage(rawTitle),
        );

        _expectTitleUsesCardTitleStyle(
          tester,
          title: StageCard.getStageTitleDisplay(rawTitle),
          maxLines: 2,
        );
      },
    );

    testWidgets(
      'keeps long mobile title readable and separate from actions',
      (tester) async {
        const rawTitle =
            'Очень длинное название этапа для проверки мобильной иерархии, переноса и соседней кнопки удаления';

        await _pumpStageCard(
          tester,
          width: 390,
          platform: TargetPlatform.android,
          stage: _buildStage(rawTitle, isPaid: true),
        );

        _expectTitleUsesCardTitleStyle(
          tester,
          title: rawTitle,
          maxLines: 3,
        );

        final titleRect = tester.getRect(find.text(rawTitle));
        final deleteRect = tester.getRect(find.byIcon(Icons.close));

        expect((deleteRect.top - titleRect.top).abs(), lessThanOrEqualTo(6));
        expect(find.text('ОПЛАЧЕНО'), findsNothing);
      },
    );
  });
}

Future<void> _pumpStageCard(
  WidgetTester tester, {
  required double width,
  required TargetPlatform platform,
  required StageModel stage,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  debugDefaultTargetPlatformOverride = platform;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width < 500 ? width - 24 : 560,
            child: StageCard(
              stage: stage,
              onTap: () {},
              onStatusChanged: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
  debugDefaultTargetPlatformOverride = null;
}

StageModel _buildStage(
  String title, {
  bool isPaid = false,
}) {
  return StageModel(
    id: 1,
    title: title,
    status: 'plan',
    isPaid: isPaid,
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 5),
  );
}

void _expectTitleUsesCardTitleStyle(
  WidgetTester tester, {
  required String title,
  required int maxLines,
}) {
  final titleFinder = find.text(title);

  expect(titleFinder, findsOneWidget);

  final titleText = tester.widget<Text>(titleFinder);
  final titleContext = tester.element(titleFinder);
  final theme = Theme.of(titleContext);
  final expectedStyle = theme.appTextStyles.cardTitle.copyWith(
    color: theme.colorScheme.onSurface,
    letterSpacing: -0.15,
  );

  expect(titleText.style?.fontSize, expectedStyle.fontSize);
  expect(titleText.style?.fontWeight, expectedStyle.fontWeight);
  expect(titleText.style?.height, expectedStyle.height);
  expect(titleText.style?.letterSpacing, expectedStyle.letterSpacing);
  expect(titleText.maxLines, maxLines);
  expect(titleText.overflow, TextOverflow.ellipsis);
}
