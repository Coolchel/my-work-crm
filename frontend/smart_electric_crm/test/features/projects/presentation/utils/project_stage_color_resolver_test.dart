import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/utils/project_stage_color_resolver.dart';

void main() {
  group('ProjectStageColorResolver.resolveStripeColor', () {
    test('returns indigo when there are no stages', () {
      final color = ProjectStageColorResolver.resolveStripeColor([]);
      expect(color, Colors.indigo);
    });

    test('returns blueGrey when only precalc exists', () {
      final color = ProjectStageColorResolver.resolveStripeColor(['precalc']);
      expect(color, Colors.blueGrey);
    });

    test('returns blue for stage_1, stage_2, and stage_1_2', () {
      expect(
        ProjectStageColorResolver.resolveStripeColor(['stage_1']),
        Colors.blue,
      );
      expect(
        ProjectStageColorResolver.resolveStripeColor(['stage_2']),
        Colors.blue,
      );
      expect(
        ProjectStageColorResolver.resolveStripeColor(['stage_1_2']),
        Colors.blue,
      );
    });

    test('returns green when stage_3 exists', () {
      final color =
          ProjectStageColorResolver.resolveStripeColor(['precalc', 'stage_3']);
      expect(color, Colors.green);
    });

    test('returns amber when only other exists', () {
      final color = ProjectStageColorResolver.resolveStripeColor(['other']);
      expect(color, Colors.amber);
    });

    test('returns purple when only extra exists', () {
      final color = ProjectStageColorResolver.resolveStripeColor(['extra']);
      expect(color, Colors.purple);
    });

    test('returns amber for precalc + other', () {
      final color =
          ProjectStageColorResolver.resolveStripeColor(['precalc', 'other']);
      expect(color, Colors.amber);
    });

    test('returns purple for precalc + extra', () {
      final color =
          ProjectStageColorResolver.resolveStripeColor(['precalc', 'extra']);
      expect(color, Colors.purple);
    });

    test('returns blue when extra/other are combined with stage_1/2/1+2', () {
      expect(
        ProjectStageColorResolver.resolveStripeColor(['stage_1', 'other']),
        Colors.blue,
      );
      expect(
        ProjectStageColorResolver.resolveStripeColor(['stage_2', 'extra']),
        Colors.blue,
      );
      expect(
        ProjectStageColorResolver.resolveStripeColor(
          ['stage_1_2', 'precalc', 'other', 'extra'],
        ),
        Colors.blue,
      );
    });

    test('returns green when stage_3 is combined with any other stages', () {
      final color = ProjectStageColorResolver.resolveStripeColor(
        ['stage_3', 'precalc', 'other', 'extra', 'stage_2'],
      );
      expect(color, Colors.green);
    });
  });
}
