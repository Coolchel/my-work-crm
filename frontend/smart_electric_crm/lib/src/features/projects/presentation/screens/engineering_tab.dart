import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

import '../../data/models/project_model.dart';
import '../../../engineering/data/models/shield_model.dart';
import '../dialogs/engineering/add_shield_dialog.dart';
import '../widgets/engineering/shield_card.dart';

class EngineeringTab extends ConsumerStatefulWidget {
  final ProjectModel project;
  final ScrollController scrollController;

  const EngineeringTab({
    required this.project,
    required this.scrollController,
    super.key,
  });

  @override
  ConsumerState<EngineeringTab> createState() => _EngineeringTabState();
}

class _EngineeringTabState extends ConsumerState<EngineeringTab> {
  Object? _scrollAttachment;

  @override
  void initState() {
    super.initState();
    _scrollAttachment =
        AppNavigation.shieldsScrollController.attach(_scrollToTop);
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.shieldsScrollController.detach(scrollAttachment);
    }
    super.dispose();
  }

  Future<void> _scrollToTop({bool animated = true}) async {
    if (!widget.scrollController.hasClients) {
      return;
    }
    if (animated) {
      await widget.scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final sortedShields = List<ShieldModel>.from(widget.project.shields)
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
              _showAddShieldDialog(context, ref, widget.project.id.toString()),
          backgroundColor: Colors.indigo,
          foregroundColor: Theme.of(context).colorScheme.surface,
          elevation: 2,
          tooltip: null,
          child: const Icon(Icons.add),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: [
                if (widget.project.shields.isEmpty)
                  const FriendlyEmptyState(
                    icon: Icons.settings_input_component_outlined,
                    title: 'Нет щитов',
                    subtitle:
                        'Добавьте первый щит, чтобы начать инженерную часть проекта.',
                    accentColor: Colors.indigo,
                  )
                else
                  ...sortedShields.map((shield) => ShieldCard(
                        shield: shield,
                        projectId: widget.project.id.toString(),
                      )),
                const SizedBox(height: 80),
              ],
            ),
          );
          return content;
        },
      ),
    );
  }

  void _showAddShieldDialog(
    BuildContext context,
    WidgetRef ref,
    String projectId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddShieldDialog(projectId: projectId),
    );
  }
}
