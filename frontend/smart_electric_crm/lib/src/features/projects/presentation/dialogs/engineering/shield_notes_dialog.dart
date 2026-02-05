import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';

class ShieldNotesDialog extends StatefulWidget {
  final String projectId;
  final int shieldId;
  final String currentNotes;

  const ShieldNotesDialog({
    required this.projectId,
    required this.shieldId,
    required this.currentNotes,
    super.key,
  });

  @override
  State<ShieldNotesDialog> createState() => _ShieldNotesDialogState();
}

class _ShieldNotesDialogState extends State<ShieldNotesDialog> {
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.currentNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Colors.brown;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: themeColor),
      ),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.note_alt_outlined,
                              size: 20, color: themeColor.withOpacity(0.8)),
                          const SizedBox(width: 8),
                          Text(
                            "Заметка",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: themeColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: TextField(
                    controller: _notesController,
                    autofocus: true,
                    maxLines: 6,
                    minLines: 4,
                    decoration: InputDecoration(
                      hintText: "Введите заметку для этого щита...",
                      hintStyle: TextStyle(
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: themeColor.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: themeColor.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.only(
                    left: 24, right: 24, bottom: 24, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.black87),
                      child: const Text("Отмена"),
                    ),
                    const SizedBox(width: 8),
                    Consumer(builder: (context, ref, _) {
                      return FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                try {
                                  await ref
                                      .read(engineeringRepositoryProvider)
                                      .updateShield(widget.shieldId, {
                                    'notes': _notesController.text.trim(),
                                  });
                                  ref.invalidate(projectListProvider);
                                  ref.invalidate(
                                      projectByIdProvider(widget.projectId));
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Ошибка: $e')));
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSaving = false);
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: themeColor,
                          minimumSize: const Size(120, 44),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Сохранить'),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
