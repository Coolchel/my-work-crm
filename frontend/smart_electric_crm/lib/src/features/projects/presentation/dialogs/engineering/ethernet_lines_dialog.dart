import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';

class EthernetLinesDialog extends StatefulWidget {
  final String projectId;
  final int shieldId;
  final int currentLinesCount;
  final Color themeColor;

  const EthernetLinesDialog({
    required this.projectId,
    required this.shieldId,
    required this.currentLinesCount,
    required this.themeColor,
    super.key,
  });

  @override
  State<EthernetLinesDialog> createState() => _EthernetLinesDialogState();
}

class _EthernetLinesDialogState extends State<EthernetLinesDialog> {
  late TextEditingController _linesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _linesController = TextEditingController(
        text: widget.currentLinesCount > 0
            ? widget.currentLinesCount.toString()
            : '');
  }

  @override
  void dispose() {
    _linesController.dispose();
    super.dispose();
  }

  void _selectQuickValue(int value) {
    _linesController.text = value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.themeColor;

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
          constraints: const BoxConstraints(maxWidth: 450),
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
                      child: Text(
                        "Ethernet линии",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: themeColor),
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
                  padding: const EdgeInsets.only(
                      left: 24, right: 24, top: 24, bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Быстрые кнопки выбора
                      Text(
                        "Быстрый выбор:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          // Первый ряд: 1, 2, 4
                          Row(
                            children: [1, 2, 4].map((value) {
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: SizedBox(
                                    height: 36,
                                    child: OutlinedButton(
                                      onPressed: () => _selectQuickValue(value),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        side: BorderSide(
                                            color: themeColor.withOpacity(0.3)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        '$value',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: themeColor.withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          // Второй ряд: 6, 8, 10
                          Row(
                            children: [6, 8, 10].map((value) {
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: SizedBox(
                                    height: 36,
                                    child: OutlinedButton(
                                      onPressed: () => _selectQuickValue(value),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        side: BorderSide(
                                            color: themeColor.withOpacity(0.3)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        '$value',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: themeColor.withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Поле ввода
                      TextField(
                        controller: _linesController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: "Количество линий UTP-5e",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: "Например: 12",
                          hintStyle: TextStyle(
                            color: Colors.grey.withOpacity(0.35),
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
                        ),
                      ),
                    ],
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
                                  final linesCount =
                                      int.tryParse(_linesController.text) ?? 0;
                                  await ref
                                      .read(engineeringRepositoryProvider)
                                      .updateShield(widget.shieldId, {
                                    'internet_lines_count': linesCount,
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
                            : const Text('Добавить'),
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
