import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class TransactionListTile extends StatelessWidget {
  final LoanTransaction transaction;
  final VoidCallback onTap;

  const TransactionListTile({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGiven = transaction.type == TransactionType.given;
    final color = isGiven ? AppTheme.given : AppTheme.taken;
    final isOverdue = Formatters.isOverdue(transaction.dueDate) &&
        transaction.status != TransactionStatus.settled;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isOverdue
              ? Border.all(color: AppTheme.taken.withOpacity(0.4))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  transaction.contactName.isNotEmpty
                      ? transaction.contactName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.contactName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isGiven ? 'Given' : 'Taken',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${transaction.interestRate}% ${transaction.interestType == InterestType.monthly ? 'p.m.' : 'p.a.'}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (transaction.dueDate != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      Formatters.daysRemaining(transaction.dueDate),
                      style: TextStyle(
                        color: isOverdue ? AppTheme.taken : AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight:
                            isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(transaction.amount),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                _statusBadge(transaction.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(TransactionStatus status) {
    Color color;
    String label;
    switch (status) {
      case TransactionStatus.active:
        color = AppTheme.primary;
        label = 'Active';
        break;
      case TransactionStatus.partiallyPaid:
        color = AppTheme.warning;
        label = 'Partial';
        break;
      case TransactionStatus.settled:
        color = AppTheme.given;
        label = 'Settled';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
