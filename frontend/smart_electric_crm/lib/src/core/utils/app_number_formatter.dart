class AppNumberFormatter {
  const AppNumberFormatter._();

  static String integer(num value) {
    final rounded = value.round();
    final sign = rounded < 0 ? '-' : '';
    return '$sign${_groupThousands(rounded.abs().toString())}';
  }

  static String decimal(
    num value, {
    int maxFractionDigits = 2,
    int minFractionDigits = 0,
  }) {
    final sign = value < 0 ? '-' : '';
    final fixed = value.abs().toStringAsFixed(maxFractionDigits);
    final parts = fixed.split('.');
    final integerPart = _groupThousands(parts[0]);

    if (parts.length == 1 || maxFractionDigits == 0) {
      return '$sign$integerPart';
    }

    var fractionPart = parts[1];
    while (
        fractionPart.length > minFractionDigits && fractionPart.endsWith('0')) {
      fractionPart = fractionPart.substring(0, fractionPart.length - 1);
    }

    if (fractionPart.isEmpty) {
      return '$sign$integerPart';
    }

    return '$sign$integerPart.$fractionPart';
  }

  static String _groupThousands(String digits) {
    if (digits.length <= 3) {
      return digits;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final positionFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}
