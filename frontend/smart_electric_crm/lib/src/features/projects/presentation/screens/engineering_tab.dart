import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project_model.dart';
import '../widgets/engineering/shield_card.dart';
import '../../../engineering/data/models/shield_model.dart';
import '../dialogs/engineering/add_shield_dialog.dart';

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
        verticalOffset: 40,
        child: FloatingActionButton(
          heroTag: 'add_shield_fab',
          onPressed: () =>
              _showAddShieldDialog(context, ref, project.id.toString()),
          backgroundColor: Colors.brown.shade200,
          foregroundColor: Colors.black87,
          elevation: 2,
          tooltip: null, // Disable built-in tooltip
          child: const Icon(Icons.add),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (project.shields.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Нет щитов. Добавьте первый щит.',
                      style: TextStyle(color: Colors.grey)),
                ),
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
