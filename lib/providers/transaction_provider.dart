import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/payment_model.dart';
import '../db/database_helper.dart';
import '../services/firebase_service.dart';

class TransactionProvider with ChangeNotifier {
  List<LoanTransaction> _transactions = [];
  final List<Payment> _payments = [];

  List<Payment> get payments => _payments;
  List<LoanTransaction> get transactions => _transactions;

  List<LoanTransaction> get givenTransactions =>
      _transactions.where((t) => t.type == TransactionType.given).toList();

  List<LoanTransaction> get takenTransactions =>
      _transactions.where((t) => t.type == TransactionType.taken).toList();

  List<LoanTransaction> get activeTransactions => _transactions
      .where((t) => t.status != TransactionStatus.settled)
      .toList();

  List<LoanTransaction> get overdueTransactions => _transactions
      .where((t) =>
          t.dueDate != null &&
          t.dueDate!.isBefore(DateTime.now()) &&
          t.status != TransactionStatus.settled)
      .toList();

  // ─── Analytics ────────────────────────────────────────────────────────────

  double get totalInterestEarned =>
      givenTransactions.fold(0, (sum, t) => sum + t.interestTillToday);

  double get totalInterestPaid =>
      takenTransactions.fold(0, (sum, t) => sum + t.interestTillToday);

  double get totalReceivable => givenTransactions
      .where((t) => t.status != TransactionStatus.settled)
      .fold(0, (sum, t) => sum + t.remainingAmount);

  double get totalPayable => takenTransactions
      .where((t) => t.status != TransactionStatus.settled)
      .fold(0, (sum, t) => sum + t.remainingAmount);

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadTransactions() async {
    _transactions = await DatabaseHelper.instance.getAllTransactions();
    notifyListeners();
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<LoanTransaction> addTransaction({
    required String contactId,
    required String contactName,
    required double amount,
    required TransactionType type,
    required double interestRate,
    required InterestType interestType,
    required DateTime startDate,
    DateTime? dueDate,
    String? notes,
  }) async {
    final tx = LoanTransaction(
      id: const Uuid().v4(),
      contactId: contactId,
      contactName: contactName,
      amount: amount,
      type: type,
      interestRate: interestRate,
      interestType: interestType,
      startDate: startDate,
      dueDate: dueDate,
      notes: notes,
      status: TransactionStatus.active,
      amountPaid: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertTransaction(tx);
    _transactions.insert(0, tx);
    notifyListeners();
    _syncTxToCloud(tx);
    return tx;
  }

  Future<void> updateTransaction(LoanTransaction tx) async {
    final updated = tx.copyWith(updatedAt: DateTime.now());
    await DatabaseHelper.instance.updateTransaction(updated);
    final idx = _transactions.indexWhere((t) => t.id == tx.id);
    if (idx != -1) _transactions[idx] = updated;
    notifyListeners();
    _syncTxToCloud(updated);
  }

  Future<void> deleteTransaction(String id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    _deleteTxFromCloud(id);
  }

  // ─── Payments ─────────────────────────────────────────────────────────────

  Future<void> addPayment({
    required String transactionId,
    required double amount,
    required PaymentMode mode,
    required DateTime paymentDate,
    String? proofImagePath,
    String? notes,
  }) async {
    final payment = Payment(
      id: const Uuid().v4(),
      transactionId: transactionId,
      amount: amount,
      mode: mode,
      paymentDate: paymentDate,
      proofImagePath: proofImagePath,
      notes: notes,
    );
    await DatabaseHelper.instance.insertPayment(payment);

    // Update transaction amountPaid and status
    final txIdx = _transactions.indexWhere((t) => t.id == transactionId);
    if (txIdx != -1) {
      final tx = _transactions[txIdx];
      final newAmountPaid = tx.amountPaid + amount;
      final newStatus = newAmountPaid >= tx.totalPayable
          ? TransactionStatus.settled
          : TransactionStatus.partiallyPaid;
      final updated = tx.copyWith(
        amountPaid: newAmountPaid,
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.updateTransaction(updated);
      _transactions[txIdx] = updated;
      _syncTxToCloud(updated);
    }

    // Sync payment to cloud
    if (FirebaseService.instance.isLoggedIn) {
      FirebaseService.instance.syncPayment(payment).catchError((_) {});
    }

    notifyListeners();
  }

  Future<List<Payment>> getPaymentsForTransaction(
      String transactionId) async {
    return await DatabaseHelper.instance
        .getPaymentsByTransaction(transactionId);
  }

  LoanTransaction? getById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<LoanTransaction> getByContact(String contactId) =>
      _transactions.where((t) => t.contactId == contactId).toList();

  // ─── Filter helpers ───────────────────────────────────────────────────────

  List<LoanTransaction> filterByMonth(int year, int month) =>
      _transactions
          .where((t) =>
              t.startDate.year == year && t.startDate.month == month)
          .toList();

  List<LoanTransaction> filterByYear(int year) =>
      _transactions.where((t) => t.startDate.year == year).toList();

  // ─── Cloud sync ───────────────────────────────────────────────────────────

  void _syncTxToCloud(LoanTransaction tx) {
    if (FirebaseService.instance.isLoggedIn) {
      FirebaseService.instance.syncTransaction(tx).catchError((_) {});
    }
  }

  void _deleteTxFromCloud(String id) {
    if (FirebaseService.instance.isLoggedIn) {
      FirebaseService.instance
          .deleteTransactionFromCloud(id)
          .catchError((_) {});
    }
  }

  /// Full backup to Firestore
  Future<void> backupToCloud() async {
    if (!FirebaseService.instance.isLoggedIn) return;
    for (final tx in _transactions) {
      await FirebaseService.instance.syncTransaction(tx);
    }
  }

  /// Restore from Firestore
  Future<void> restoreFromCloud() async {
    if (!FirebaseService.instance.isLoggedIn) return;
    final cloudTxs = await FirebaseService.instance.fetchTransactions();
    for (final tx in cloudTxs) {
      await DatabaseHelper.instance.insertTransaction(tx);
    }
    _transactions = await DatabaseHelper.instance.getAllTransactions();
    notifyListeners();
  }
}
