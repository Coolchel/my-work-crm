import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';

class ShieldContentMultimedia extends ConsumerStatefulWidget {
  final ShieldModel shield;
  final String projectId;

  const ShieldContentMultimedia(
      {required this.shield, required this.projectId, super.key});

  @override
  ConsumerState<ShieldContentMultimedia> createState() =>
      _ShieldContentMultimediaState();
}

class _ShieldContentMultimediaState
    extends ConsumerState<ShieldContentMultimedia> {
  late TextEditingController _linesController;
  late TextEditingController _notesController;
  bool _isSaving = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _linesController = TextEditingController(
        text: widget.shield.internetLinesCount.toString());
    _notesController =
        TextEditingController(text: widget.shield.multimediaNotes);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _linesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      final lines = int.tryParse(_linesController.text) ?? 0;
      await ref
          .read(engineeringRepositoryProvider)
          .updateShield(widget.shield.id, {
        'internet_lines_count': lines,
        'multimedia_notes': _notesController.text,
      });
      ref.invalidate(projectListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onDataChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), _save);
  }

  void _onLinesSelected(String value) {
    _linesController.text = value;
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _linesController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Кол-во интернет линий',
            border: const OutlineInputBorder(),
            suffixIcon: PopupMenuButton<String>(
              tooltip: 'Выбрать количество',
              icon: const Icon(Icons.arrow_drop_down),
              onSelected: _onLinesSelected,
              itemBuilder: (BuildContext context) {
                return List.generate(11, (index) => index.toString())
                    .map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ),
          onChanged: (_) => _onDataChanged(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Заметки по оборудованию и линиям',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description_outlined),
            alignLabelWithHint: true,
          ),
          onChanged: (_) => _onDataChanged(),
        ),
        const SizedBox(height: 8),
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Сохранение...',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ),
      ],
    );
  }
}
