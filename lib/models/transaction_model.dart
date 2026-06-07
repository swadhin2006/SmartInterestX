enum TransactionType { given, taken }
enum TransactionStatus { active, partiallyPaid, settled }
enum InterestType { monthly, yearly }

class LoanTransaction {
  final String id;
  final String contactId;
  final String contactName;
  final double amount;
  final TransactionType type;
  final double interestRate;
  final InterestType interestType;
  final DateTime startDate;
  final DateTime? dueDate;
  final String? notes;
  final TransactionStatus status;
  final double amountPaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanTransaction({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.amount,
    required this.type,
    required this.interestRate,
    required this.interestType,
    required this.startDate,
    this.dueDate,
    this.notes,
    required this.status,
    required this.amountPaid,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Simple Interest = P * R * T / 100
  /// For monthly: T = months elapsed
  /// For yearly: T = years elapsed
  double calculateInterest({DateTime? upTo}) {
    final endDate = upTo ?? DateTime.now();
    final days = endDate.difference(startDate).inDays;
    if (days <= 0) return 0;

    if (interestType == InterestType.monthly) {
      final months = days / 30.0;
      return (amount * interestRate * months) / 100;
    } else {
      final years = days / 365.0;
      return (amount * interestRate * years) / 100;
    }
  }

  double get interestTillToday => calculateInterest();

  double get interestTillDueDate =>
      dueDate != null ? calculateInterest(upTo: dueDate) : interestTillToday;

  double get totalPayable => amount + interestTillToday;

  double get remainingAmount => totalPayable - amountPaid;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactId': contactId,
      'contactName': contactName,
      'amount': amount,
      'type': type.index,
      'interestRate': interestRate,
      'interestType': interestType.index,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'notes': notes,
      'status': status.index,
      'amountPaid': amountPaid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LoanTransaction.fromMap(Map<String, dynamic> map) {
    return LoanTransaction(
      id: map['id'],
      contactId: map['contactId'],
      contactName: map['contactName'],
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values[map['type']],
      interestRate: (map['interestRate'] as num).toDouble(),
      interestType: InterestType.values[map['interestType']],
      startDate: DateTime.parse(map['startDate']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      notes: map['notes'],
      status: TransactionStatus.values[map['status']],
      amountPaid: (map['amountPaid'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  LoanTransaction copyWith({
    String? id,
    String? contactId,
    String? contactName,
    double? amount,
    TransactionType? type,
    double? interestRate,
    InterestType? interestType,
    DateTime? startDate,
    DateTime? dueDate,
    String? notes,
    TransactionStatus? status,
    double? amountPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanTransaction(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      interestRate: interestRate ?? this.interestRate,
      interestType: interestType ?? this.interestType,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      amountPaid: amountPaid ?? this.amountPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
