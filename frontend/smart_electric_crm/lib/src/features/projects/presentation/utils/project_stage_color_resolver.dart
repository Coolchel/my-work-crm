import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';

class ProjectStageColorResolver {
  static const Set<String> _coreBlueStages = {
    'stage_1',
    'stage_1_2',
    'stage_2',
  };

  static Color resolveStripeColor(Iterable<StageModel> stages) {
    final stageList = stages.toList();
    final titles = stageList.map((stage) => stage.title).toSet();

    if (titles.isEmpty) {
      return Colors.indigo;
    }

    final hasStage3WithWorks = stageList.any(
      (stage) =>
          stage.title == 'stage_3' &&
          stage.estimateItems.any((item) => item.itemType == 'work'),
    );

    if (hasStage3WithWorks) {
      return Colors.green;
    }

    if (titles.intersection(_coreBlueStages).isNotEmpty) {
      return Colors.blue;
    }

    final hasPrecalc = titles.contains('precalc');
    final hasExtra = titles.contains('extra');
    final hasOther = titles.contains('other');

    // Extra/Other should dominate when there are no core stages.
    // If both appear together, prefer extra color for a stable single accent.
    if (hasExtra) {
      return Colors.purple;
    }

    if (hasOther) {
      return Colors.amber;
    }

    if (hasPrecalc) {
      return Colors.blueGrey;
    }

    return Colors.indigo;
  }
}
