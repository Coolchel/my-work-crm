import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../../projects/presentation/screens/project_detail_screen.dart';
import '../../../projects/data/models/project_model.dart';

class SearchResultsOverlay extends ConsumerWidget {
  const SearchResultsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(projectSearchQueryProvider);
    // Use the dedicated search results provider
    final projectsAsync = ref.watch(projectSearchResultsProvider);

    if (searchQuery == null || searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxHeight: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: projectsAsync.when(
            data: (projects) {
              if (projects.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'Ничего не найдено',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: projects.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return _SearchResultItem(
                    project: project,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailScreen(
                            projectId: project.id.toString(),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Ошибка: $err',
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.project,
    required this.onTap,
  });

  @override
  State<_SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<_SearchResultItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              _isHovered ? Colors.indigo.withOpacity(0.08) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: _isHovered ? Colors.indigo : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hoverColor: Colors.transparent,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.apartment, size: 20, color: Colors.indigo.shade400),
          ),
          title: Text(
            widget.project.address,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.project.clientInfo.isNotEmpty)
                Text(
                  widget.project.clientInfo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (widget.project.intercomCode.isNotEmpty)
                Text(
                  'Домофон: ${widget.project.intercomCode}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          trailing: Icon(Icons.chevron_right,
              size: 16,
              color: _isHovered ? Colors.indigo : Colors.grey.shade400),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
