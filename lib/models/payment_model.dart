enum PaymentMode { upi, bankTransfer, cash, other }

class Payment {
  final String id;
  final String transactionId;
  final double amount;
  final PaymentMode mode;
  final DateTime paymentDate;
  final String? proofImagePath;
  final String? notes;

  Payment({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.mode,
    required this.paymentDate,
    this.proofImagePath,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'amount': amount,
      'mode': mode.index,
      'paymentDate': paymentDate.toIso8601String(),
      'proofImagePath': proofImagePath,
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      transactionId: map['transactionId'],
      amount: (map['amount'] as num).toDouble(),
      mode: PaymentMode.values[map['mode']],
      paymentDate: DateTime.parse(map['paymentDate']),
      proofImagePath: map['proofImagePath'],
      notes: map['notes'],
    );
  }

  String get modeLabel {
    switch (mode) {
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.other:
        return 'Other';
    }
  }
}
