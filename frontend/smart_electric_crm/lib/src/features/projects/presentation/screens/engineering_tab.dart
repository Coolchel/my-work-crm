import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project_model.dart';
import '../widgets/engineering/shield_card.dart';
import '../dialogs/engineering/add_shield_dialog.dart';

class EngineeringTab extends ConsumerWidget {
  final ProjectModel project;

  const EngineeringTab({required this.project, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddShieldDialog(context, ref, project.id.toString()),
        icon: const Icon(Icons.add),
        label: const Text('Добавить щит'),
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
              ...project.shields.map((shield) => ShieldCard(
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
