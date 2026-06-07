import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  Future<void> exportTransactionsToCSV(
      List<LoanTransaction> transactions) async {
    final List<List<dynamic>> rows = [
      [
        'ID',
        'Contact',
        'Type',
        'Amount (₹)',
        'Interest Rate (%)',
        'Interest Type',
        'Start Date',
        'Due Date',
        'Interest Till Today (₹)',
        'Total Payable (₹)',
        'Amount Paid (₹)',
        'Remaining (₹)',
        'Status',
        'Notes',
      ]
    ];

    final fmt = DateFormat('dd-MM-yyyy');

    for (final tx in transactions) {
      rows.add([
        tx.id,
        tx.contactName,
        tx.type == TransactionType.given ? 'Given (Lent)' : 'Taken (Borrowed)',
        tx.amount.toStringAsFixed(2),
        tx.interestRate.toStringAsFixed(2),
        tx.interestType == InterestType.monthly ? 'Monthly' : 'Yearly',
        fmt.format(tx.startDate),
        tx.dueDate != null ? fmt.format(tx.dueDate!) : '-',
        tx.interestTillToday.toStringAsFixed(2),
        tx.totalPayable.toStringAsFixed(2),
        tx.amountPaid.toStringAsFixed(2),
        tx.remainingAmount.toStringAsFixed(2),
        _statusLabel(tx.status),
        tx.notes ?? '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/smartinterestx_$timestamp.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'SmartInterestX — Transaction Export',
    );
  }

  String _statusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.active:
        return 'Active';
      case TransactionStatus.partiallyPaid:
        return 'Partially Paid';
      case TransactionStatus.settled:
        return 'Settled';
    }
  }
}
