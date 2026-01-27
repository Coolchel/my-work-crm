import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/utils/decimal_input_formatter.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/marquee_text.dart';

/// Dialog for inputting quantity when adding a catalog item to an estimate
class QuantityInputDialog extends StatefulWidget {
  final CatalogItem item;
  final String itemType;
  final bool hidePrices;
  const QuantityInputDialog(
      {super.key,
      required this.item,
      required this.itemType,
      this.hidePrices = false});

  @override
  State<QuantityInputDialog> createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<QuantityInputDialog> {
  late TextEditingController _totalCtrl;
  late TextEditingController _empCtrl;
  late TextEditingController _myCtrl;
  late TextEditingController _priceCtrl;
  late String _currency;
  bool _showEmployer = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _totalCtrl = TextEditingController(text: '1');
    _empCtrl = TextEditingController(text: '0');
    _myCtrl = TextEditingController(text: '1');
    _priceCtrl = TextEditingController(
        text: widget.item.defaultPrice
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.?0+$'), ''));
    _currency = 'USD';

    if (widget.itemType == 'work') {
      _setupListeners();
    }
  }

  void _setupListeners() {
    _totalCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('total');
    });
    _myCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('my');
    });
    _empCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('emp');
    });
  }

  void _calculate(String source) {
    if (_isUpdating) return;
    _isUpdating = true;
    try {
      final total = double.tryParse(_totalCtrl.text.replaceAll(',', '.')) ?? 0;
      final my = double.tryParse(_myCtrl.text.replaceAll(',', '.')) ?? 0;
      final emp = double.tryParse(_empCtrl.text.replaceAll(',', '.')) ?? 0;

      String formatNum(double val) {
        if (val < 0) val = 0;
        if (val == val.toInt()) return val.toInt().toString();
        final str = val.toStringAsFixed(2);
        if (str.endsWith('.00')) return str.substring(0, str.length - 3);
        if (str.endsWith('0')) return str.substring(0, str.length - 1);
        return str;
      }

      if (source == 'total') {
        _myCtrl.text = formatNum(total - emp);
      } else if (source == 'my') {
        _totalCtrl.text = formatNum(my + emp);
      } else if (source == 'emp') {
        _myCtrl.text = formatNum(total - emp);
      }
    } finally {
      _isUpdating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWork = widget.itemType == 'work';
    final themeColor = isWork ? Colors.green : Colors.blue;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: themeColor),
      ),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: widget.item.name.length > 25
              ? MarqueeText(text: widget.item.name)
              : Text(widget.item.name),
        ),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _totalCtrl,
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
                                _empCtrl.text = '0';
                                _calculate('emp');
                              }
                            });
                          },
                          tooltip: "Показать калькулятор",
                        )
                      : null,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [DecimalInputFormatter()]),
            if (_showEmployer && isWork) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _myCtrl,
                      decoration: const InputDecoration(labelText: "Мы"),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DecimalInputFormatter()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _empCtrl,
                      decoration:
                          const InputDecoration(labelText: "Контрагент"),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DecimalInputFormatter()],
                    ),
                  ),
                ],
              ),
            ],
            if (!widget.hidePrices) ...[
              const SizedBox(height: 10),
              TextField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: "Цена"),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter()]),
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
            ],
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
              child: const Text("Отмена")),
          FilledButton(
              onPressed: () {
                final t =
                    double.tryParse(_totalCtrl.text.replaceAll(',', '.')) ?? 0;
                final e =
                    double.tryParse(_empCtrl.text.replaceAll(',', '.')) ?? 0;
                final p =
                    double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;

                if (e > t) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text("Ошибка: Доля контрагента > Общего объема")));
                  return;
                }

                Navigator.pop(context, {
                  'total': t,
                  'employer': e,
                  'price': p,
                  'currency': _currency,
                });
              },
              child: const Text("Добавить"))
        ],
      ),
    );
  }
}
