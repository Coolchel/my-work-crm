import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/estimate_actions_dialog.dart';

void main() {
  StageModel buildStage() {
    return StageModel(
      id: 1,
      title: 'stage_1',
      status: 'plan',
      isPaid: false,
      workRemarks: 'work remarks',
      materialRemarks: 'material remarks',
    );
  }

  EstimateItemModel buildWorkItem() {
    return EstimateItemModel(
      id: 1,
      stage: 1,
      itemType: 'work',
      name: 'Work item',
      unit: 'pcs',
      totalQuantity: 2,
      employerQuantity: 1,
      pricePerUnit: 10,
    );
  }

  EstimateItemModel buildMaterialItem() {
    return EstimateItemModel(
      id: 2,
      stage: 1,
      itemType: 'material',
      name: 'Material item',
      unit: 'm',
      totalQuantity: 3,
      pricePerUnit: 5,
    );
  }

  Widget buildTestWidget({
    required Future<void> Function(EstimatePdfActionRequest request)
        onExecuteAction,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: EstimatePdfActionsDialog(
            projectId: '1',
            stage: buildStage(),
            works: [buildWorkItem()],
            materials: [buildMaterialItem()],
            showPrices: true,
            markupPercent: 10,
            onExecuteAction: onExecuteAction,
          ),
        ),
      ),
    );
  }

  testWidgets('prevents repeated taps while busy and resets after completion',
      (tester) async {
    final completer = Completer<void>();
    var callCount = 0;

    await tester.pumpWidget(
      buildTestWidget(
        onExecuteAction: (_) async {
          callCount++;
          await completer.future;
        },
      ),
    );

    final firstActionButton = find.byType(OutlinedButton).first;

    await tester.tap(firstActionButton);
    await tester.pump();

    expect(callCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final popupButtons = find.byWidgetPredicate(
      (widget) => widget is PopupMenuButton<String>,
    );
    final popupStates =
        tester.widgetList<PopupMenuButton<String>>(popupButtons).toList();
    expect(popupStates, isNotEmpty);
    expect(popupStates.every((button) => button.enabled == false), isTrue);

    await tester.tap(firstActionButton);
    await tester.pump();
    expect(callCount, 1);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(firstActionButton);
    await tester.pump();
    expect(callCount, 2);
  });

  testWidgets('dispatches share action from popup menu', (tester) async {
    EstimatePdfActionRequest? captured;

    await tester.pumpWidget(
      buildTestWidget(
        onExecuteAction: (request) async {
          captured = request;
        },
      ),
    );

    final popupButtons = find.byWidgetPredicate(
      (widget) => widget is PopupMenuButton<String>,
    );

    await tester.tap(popupButtons.first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    final popupItems = find.byType(PopupMenuItem<String>);
    await tester.tap(popupItems.first);
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.share, isTrue);
    expect(captured!.isWork, isTrue);
  });
}
