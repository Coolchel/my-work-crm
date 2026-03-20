import 'package:intl/intl.dart';

final class HumanFriendlyDateFormatter {
  const HumanFriendlyDateFormatter._();

  static String format(
    DateTime date, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final referenceDate =
        DateTime(reference.year, reference.month, reference.day);
    final valueDate = DateTime(date.year, date.month, date.day);
    final differenceInDays = referenceDate.difference(valueDate).inDays;

    if (differenceInDays == 0) {
      return 'Сегодня';
    }
    if (differenceInDays == 1) {
      return 'Вчера';
    }
    if (differenceInDays > 1 && differenceInDays < 7) {
      return '$differenceInDays дн. назад';
    }
    return DateFormat('dd.MM.yyyy').format(date);
  }
}
