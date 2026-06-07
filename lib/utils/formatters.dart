import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _date = DateFormat('dd MMM yyyy');
  static final _dateShort = DateFormat('dd/MM/yy');
  static final _monthYear = DateFormat('MMM yyyy');

  static String currency(double amount) => _currency.format(amount);
  static String date(DateTime dt) => _date.format(dt);
  static String dateShort(DateTime dt) => _dateShort.format(dt);
  static String monthYear(DateTime dt) => _monthYear.format(dt);

  static String daysRemaining(DateTime? dueDate) {
    if (dueDate == null) return 'No due date';
    final diff = dueDate.difference(DateTime.now()).inDays;
    if (diff < 0) return '${diff.abs()} days overdue';
    if (diff == 0) return 'Due today';
    return '$diff days left';
  }

  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return dueDate.isBefore(DateTime.now());
  }
}
