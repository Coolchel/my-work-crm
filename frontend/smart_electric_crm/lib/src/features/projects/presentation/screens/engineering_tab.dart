import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project_model.dart';
import '../widgets/engineering/shield_card.dart';
import '../../../engineering/data/models/shield_model.dart';
import '../dialogs/engineering/add_shield_dialog.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

class EngineeringTab extends ConsumerWidget {
  final ProjectModel project;

  const EngineeringTab({required this.project, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedShields = List<ShieldModel>.from(project.shields)
      ..sort((a, b) {
        final order = {'power': 0, 'multimedia': 1, 'led': 2};
        return (order[a.shieldType] ?? 99).compareTo(order[b.shieldType] ?? 99);
      });

    return Scaffold(
      floatingActionButton: Tooltip(
        message: 'Добавить щит',
        preferBelow: false,
        verticalOffset: 32,
        child: FloatingActionButton(
          heroTag: 'add_shield_fab',
          onPressed: () =>
              _showAddShieldDialog(context, ref, project.id.toString()),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 2,
          tooltip: null, // Disable built-in tooltip
          child: const Icon(Icons.add),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            if (project.shields.isEmpty)
              const FriendlyEmptyState(
                icon: Icons.settings_input_component_outlined,
                title: 'Нет щитов',
                subtitle: 'Добавьте первый щит, чтобы начать инженерную часть проекта.',
                accentColor: Colors.indigo,
              )
            else
              ...sortedShields.map((shield) => ShieldCard(
                    shield: shield,
                    projectId: project.id.toString(),
                  )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showAddShieldDialog(
      BuildContext context, WidgetRef ref, String projectId) {
    showDialog(
      context: context,
      builder: (context) => AddShieldDialog(projectId: projectId),
    );
  }
}
