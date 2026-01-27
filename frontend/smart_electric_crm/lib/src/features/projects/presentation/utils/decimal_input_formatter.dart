import 'package:flutter/services.dart';

/// Custom formatter: replaces commas with dots, limits to 2 decimal places, no negatives
class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Replace comma with dot
    String text = newValue.text.replaceAll(',', '.');

    // Only allow digits and one dot
    text = text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Ensure only one dot
    final parts = text.split('.');
    if (parts.length > 2) {
      text = '${parts[0]}.${parts.sublist(1).join('')}';
    }

    // Limit to 2 decimal places
    if (parts.length == 2 && parts[1].length > 2) {
      text = '${parts[0]}.${parts[1].substring(0, 2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
