/// Interest Calculation Service
/// Formula: SI = (P × R × T) / 100
/// P = Principal, R = Rate (%), T = Time
class InterestService {
  /// Simple Interest — Yearly
  /// T = days / 365
  static double calculateSI({
    required double principal,
    required double annualRate,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    endDate ??= DateTime.now();
    final days = endDate.difference(startDate).inDays;
    if (days <= 0) return 0;
    final t = days / 365.0;
    return (principal * annualRate * t) / 100;
  }

  /// Simple Interest — Monthly
  /// T = days / 30 (months elapsed)
  static double calculateMonthlySI({
    required double principal,
    required double monthlyRate,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    endDate ??= DateTime.now();
    final days = endDate.difference(startDate).inDays;
    if (days <= 0) return 0;
    final months = days / 30.0;
    return (principal * monthlyRate * months) / 100;
  }

  /// Total payable = Principal + Interest
  static double totalPayable(double principal, double interest) =>
      principal + interest;

  /// Months between two dates
  static int monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  /// Days between two dates
  static int daysBetween(DateTime from, DateTime to) =>
      to.difference(from).inDays;

  /// Calculate interest for a given number of days
  static double calculateForDays({
    required double principal,
    required double rate,
    required int days,
    required bool isMonthly,
  }) {
    if (days <= 0) return 0;
    if (isMonthly) {
      final months = days / 30.0;
      return (principal * rate * months) / 100;
    } else {
      final years = days / 365.0;
      return (principal * rate * years) / 100;
    }
  }
}
