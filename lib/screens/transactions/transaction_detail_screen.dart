import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/payment_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import 'add_transaction_screen.dart';
import 'add_payment_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments = await context
        .read<TransactionProvider>()
        .getPaymentsForTransaction(widget.transactionId);
    if (mounted) setState(() => _payments = payments);
  }

  @override
  Widget build(BuildContext context) {
    final tx = context
        .watch<TransactionProvider>()
        .getById(widget.transactionId);

    if (tx == null) {
      return const Scaffold(body: Center(child: Text('Transaction not found')));
    }

    final isGiven = tx.type == TransactionType.given;
    final color = isGiven ? AppTheme.given : AppTheme.taken;

    return Scaffold(
      appBar: AppBar(
        title: Text(tx.contactName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(existing: tx),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () => _confirmDelete(context, tx),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayments,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isGiven ? 'Money Lent' : 'Money Borrowed',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      _statusChip(tx.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.currency(tx.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tx.interestRate}% ${tx.interestType == InterestType.monthly ? 'per month' : 'per year'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // ── Payment Progress Bar (Roadmap 7.3) ──────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Progress',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '${((tx.amountPaid / (tx.totalPayable > 0 ? tx.totalPayable : 1)) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: tx.totalPayable > 0
                              ? (tx.amountPaid / tx.totalPayable).clamp(0.0, 1.0)
                              : 0,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${Formatters.currency(tx.amountPaid)} paid of ${Formatters.currency(tx.totalPayable)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Interest Breakdown
            _infoCard('Interest Breakdown', [
              _infoRow('Principal', Formatters.currency(tx.amount)),
              _infoRow('Interest Till Today',
                  Formatters.currency(tx.interestTillToday), color: color),
              _infoRow('Total Payable',
                  Formatters.currency(tx.totalPayable),
                  bold: true),
              if (tx.dueDate != null)
                _infoRow('Interest Till Due Date',
                    Formatters.currency(tx.interestTillDueDate)),
              _infoRow('Amount Paid', Formatters.currency(tx.amountPaid),
                  color: AppTheme.given),
              _infoRow('Remaining', Formatters.currency(tx.remainingAmount),
                  color: tx.remainingAmount > 0 ? AppTheme.taken : AppTheme.given,
                  bold: true),
            ]),

            const SizedBox(height: 12),

            // Dates
            _infoCard('Dates', [
              _infoRow('Start Date', Formatters.date(tx.startDate)),
              if (tx.dueDate != null) ...[
                _infoRow('Due Date', Formatters.date(tx.dueDate!)),
                _infoRow(
                  'Status',
                  Formatters.daysRemaining(tx.dueDate),
                  color: Formatters.isOverdue(tx.dueDate)
                      ? AppTheme.taken
                      : AppTheme.given,
                ),
              ],
            ]),

            if (tx.notes != null && tx.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _infoCard('Notes', [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tx.notes!,
                      style: const TextStyle(color: AppTheme.textSecondary)),
                ),
              ]),
            ],

            // Payment History
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment History',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (tx.status != TransactionStatus.settled)
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddPaymentScreen(transaction: tx),
                        ),
                      );
                      _loadPayments();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Payment'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_payments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'No payments recorded yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ..._payments.map((p) => _paymentTile(p)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppTheme.textPrimary,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentTile(Payment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.given.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payment_rounded,
                color: AppTheme.given, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.modeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  Formatters.date(payment.paymentDate),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(
                    payment.notes!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            Formatters.currency(payment.amount),
            style: const TextStyle(
              color: AppTheme.given,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(TransactionStatus status) {
    String label;
    switch (status) {
      case TransactionStatus.active:
        label = 'Active';
        break;
      case TransactionStatus.partiallyPaid:
        label = 'Partially Paid';
        break;
      case TransactionStatus.settled:
        label = 'Settled';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LoanTransaction tx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
            'Delete transaction with ${tx.contactName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.taken),
            onPressed: () async {
              await context
                  .read<TransactionProvider>()
                  .deleteTransaction(tx.id);
              if (mounted) {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
