import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/utils/decimal_input_formatter.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/marquee_text.dart';

/// Dialog for editing an estimate item
class EditItemDialog extends StatefulWidget {
  final EstimateItemModel item;

  const EditItemDialog({super.key, required this.item});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController _totalQtyCtrl;
  late TextEditingController _empQtyCtrl;
  late TextEditingController _myQtyCtrl;

  late TextEditingController _priceCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _unitCtrl;

  late String _currency;
  bool _showEmployer = false;

  bool _isUpdating = false; // Prevents infinite loops

  @override
  void initState() {
    super.initState();

    String formatNum(double val) {
      if (val == val.toInt()) return val.toInt().toString();
      final str = val.toStringAsFixed(2);
      if (str.endsWith('.00')) return str.substring(0, str.length - 3);
      if (str.endsWith('0')) return str.substring(0, str.length - 1);
      return str;
    }

    _totalQtyCtrl =
        TextEditingController(text: formatNum(widget.item.totalQuantity));
    _empQtyCtrl =
        TextEditingController(text: formatNum(widget.item.employerQuantity));
    _myQtyCtrl = TextEditingController(
        text: formatNum(
            widget.item.totalQuantity - widget.item.employerQuantity));

    _priceCtrl =
        TextEditingController(text: formatNum(widget.item.pricePerUnit ?? 0));

    _nameCtrl = TextEditingController(text: widget.item.name);
    _unitCtrl = TextEditingController(text: widget.item.unit);

    _currency = widget.item.currency;

    // Show if already has value or user expands it
    if (widget.item.employerQuantity > 0 && widget.item.itemType == 'work') {
      _showEmployer = true;
    }

    if (widget.item.itemType == 'work') {
      _setupListeners();
    }
  }

  void _setupListeners() {
    _totalQtyCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('total');
    });
    _empQtyCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('emp');
    });
    _myQtyCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('my');
    });
  }

  void _calculate(String source) {
    _isUpdating = true;
    try {
      final total =
          double.tryParse(_totalQtyCtrl.text.replaceAll(',', '.')) ?? 0;
      final emp = double.tryParse(_empQtyCtrl.text.replaceAll(',', '.')) ?? 0;
      final my = double.tryParse(_myQtyCtrl.text.replaceAll(',', '.')) ?? 0;

      String formatNum(double val) {
        if (val < 0) val = 0; // No negative values
        if (val == val.toInt()) return val.toInt().toString();
        final str = val.toStringAsFixed(2);
        if (str.endsWith('.00')) return str.substring(0, str.length - 3);
        if (str.endsWith('0')) return str.substring(0, str.length - 1);
        return str;
      }

      if (source == 'total') {
        _myQtyCtrl.text = formatNum(total - emp);
      } else if (source == 'my') {
        _totalQtyCtrl.text = formatNum(my + emp);
      } else if (source == 'emp') {
        _myQtyCtrl.text = formatNum(total - emp);
      }
    } finally {
      _isUpdating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewManual = widget.item.id == 0;
    final isWork = widget.item.itemType == 'work';
    final themeColor = isWork ? Colors.green : Colors.blue;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: themeColor),
      ),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: isNewManual
            ? const Center(child: Text("Новая позиция"))
            : Center(
                child: widget.item.name.length > 25
                    ? MarqueeText(text: widget.item.name)
                    : Text(widget.item.name),
              ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNewManual || widget.item.name.isEmpty) ...[
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Название",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: isWork ? "Штроба" : "Кабель",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _unitCtrl,
                  decoration: const InputDecoration(labelText: "Ед. изм."),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _totalQtyCtrl,
                decoration: InputDecoration(
                  labelText: "Общий объем",
                  suffixIcon: isWork
                      ? IconButton(
                          icon: Icon(Icons.person_add_alt,
                              color: _showEmployer ? themeColor : Colors.grey),
                          onPressed: () {
                            setState(() {
                              _showEmployer = !_showEmployer;
                              if (!_showEmployer) {
                                _empQtyCtrl.text = '0';
                                _calculate('emp');
                              } else {
                                if (_empQtyCtrl.text.isEmpty ||
                                    _empQtyCtrl.text == '0.0') {
                                  _empQtyCtrl.text = '0';
                                }
                              }
                            });
                          },
                          tooltip: "Показать калькулятор",
                        )
                      : null,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [DecimalInputFormatter()],
              ),
              if (widget.item.itemType == 'work' && _showEmployer) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _myQtyCtrl,
                        decoration: const InputDecoration(labelText: "Мы"),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [DecimalInputFormatter()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _empQtyCtrl,
                        decoration:
                            const InputDecoration(labelText: "Контрагент"),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [DecimalInputFormatter()],
                      ),
                    ),
                  ],
                ),
              ] else if (_showEmployer) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _empQtyCtrl,
                  decoration: const InputDecoration(labelText: "Контрагент"),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter()],
                ),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: "Цена"),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalInputFormatter()],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'USD', label: Text('USD')),
                  ButtonSegment(value: 'BYN', label: Text('BYN')),
                ],
                selected: {_currency},
                onSelectionChanged: (val) =>
                    setState(() => _currency = val.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return themeColor.withOpacity(0.15);
                    }
                    return null;
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          if (!isNewManual)
            TextButton(
                onPressed: () => Navigator.pop(context, 'delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Удалить")),
          TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
              child: const Text("Отмена")),
          FilledButton(
            onPressed: _save,
            child: Text(isNewManual ? "Добавить" : "Изменить"),
          ),
        ],
      ),
    );
  }

  void _save() {
    final totalFn =
        double.tryParse(_totalQtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final empFn = double.tryParse(_empQtyCtrl.text.replaceAll(',', '.')) ?? 0;

    // VALIDATION
    if (empFn > totalFn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Ошибка: Доля контрагента не может быть больше общего объема!")));
      return;
    }

    final priceFn = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;

    Navigator.pop(
        context,
        widget.item.copyWith(
          totalQuantity: totalFn,
          employerQuantity: empFn,
          pricePerUnit: priceFn,
          currency: _currency,
          name: _nameCtrl.text,
          unit: _unitCtrl.text,
        ));
  }
}
