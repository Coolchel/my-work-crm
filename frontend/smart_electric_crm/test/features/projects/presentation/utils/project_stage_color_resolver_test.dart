import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/utils/project_stage_color_resolver.dart';

StageModel _stage(
  String title, {
  List<EstimateItemModel> estimateItems = const [],
}) {
  return StageModel(
    id: title.hashCode.abs(),
    title: title,
    status: 'plan',
    isPaid: false,
    estimateItems: estimateItems,
  );
}

EstimateItemModel _item(String type) {
  return EstimateItemModel(
    id: type.hashCode.abs(),
    stage: 1,
    itemType: type,
    name: 'Test item',
    unit: 'pcs',
    totalQuantity: 1,
  );
}

void main() {
  group('ProjectStageColorResolver.resolveStripeColor', () {
    test('returns indigo when there are no stages', () {
      final color = ProjectStageColorResolver.resolveStripeColor([]);
      expect(color, Colors.indigo);
    });

    test('returns blueGrey when only precalc exists', () {
      final color = ProjectStageColorResolver.resolveStripeColor([
        _stage('precalc'),
      ]);
      expect(color, Colors.blueGrey);
    });

    test('returns blue for stage_1, stage_2, and stage_1_2', () {
      expect(
        ProjectStageColorResolver.resolveStripeColor([_stage('stage_1')]),
        Colors.blue,
      );
      expect(
        ProjectStageColorResolver.resolveStripeColor([_stage('stage_2')]),
        Colors.blue,
      );
      expect(
        ProjectStageColorResolver.resolveStripeColor([_stage('stage_1_2')]),
        Colors.blue,
      );
    });

    test('returns green when stage_3 has at least one work item', () {
      final color = ProjectStageColorResolver.resolveStripeColor([
        _stage('precalc'),
        _stage('stage_3', estimateItems: [_item('work')]),
      ]);
      expect(color, Colors.green);
    });

    test('returns amber when only other exists', () {
      final color = ProjectStageColorResolver.resolveStripeColor([
        _stage('other'),
      ]);
      expect(color, Colors.amber);
    });

    test('returns purple when only extra exists', () {
      final color = ProjectStageColorResolver.resolveStripeColor([
        _stage('extra'),
      ]);
      expect(color, Colors.purple);
    });

    test('returns amber for precalc + other', () {
      final color = ProjectStageColorResolver.resolveStripeColor([
        _stage('precalc'),
        _stage('other'),
      ]);
      expect(color, Colors.amber);
    });

    test('returns purple for precalc + extra', () {
      final color = ProjectStageColorResolver.resolveStripeColor([
        _stage('precalc'),
        _stage('extra'),
      ]);
      expect(color, Colors.purple);
    });

    test('returns blue when extra/other are combined with stage_1/2/1+2', () {
      expect(
        ProjectStageColorResolver.resolveStripeColor([
          _stage('stage_1'),
          _stage('other'),
        ]),
        Colors.blue,
      );
      expect(
        ProjectStageColorResolver.resolveStripeColor([
          _stage('stage_2'),
          _stage('extra'),
        ]),
        Colors.blue,
      );
      expect(
        ProjectStageColorResolver.resolveStripeColor(
          [
            _stage('stage_1_2'),
            _stage('precalc'),
            _stage('other'),
            _stage('extra'),
          ],
        ),
        Colors.blue,
      );
    });

    test('returns green when stage_3 with works is combined with any stages',
        () {
      final color = ProjectStageColorResolver.resolveStripeColor(
        [
          _stage('stage_3', estimateItems: [_item('work')]),
          _stage('precalc'),
          _stage('other'),
          _stage('extra'),
          _stage('stage_2'),
        ],
      );
      expect(color, Colors.green);
    });

    test('does not return green when stage_3 has no work items', () {
      final color = ProjectStageColorResolver.resolveStripeColor(
        [
          _stage('stage_3', estimateItems: [_item('material')]),
          _stage('precalc'),
        ],
      );
      expect(color, Colors.blueGrey);
    });
  });
}
