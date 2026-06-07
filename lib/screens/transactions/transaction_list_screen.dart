import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import 'transaction_detail_screen.dart';

// Module 3 — Transaction List Screen
class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Given'),
            Tab(text: 'Taken'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(provider.transactions),
          _buildList(provider.givenTransactions),
          _buildList(provider.takenTransactions),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-txn'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildList(List<LoanTransaction> transactions) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: transactions.length,
      itemBuilder: (ctx, i) {
        final tx = transactions[i];
        final isGiven = tx.type == TransactionType.given;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isGiven ? Colors.green[100] : Colors.red[100],
              child: Icon(
                isGiven ? Icons.arrow_upward : Icons.arrow_downward,
                color: isGiven ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              tx.contactName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '₹${tx.amount.toStringAsFixed(0)} · ${tx.interestRate}% '
              '${tx.interestType == InterestType.monthly ? 'p.m.' : 'p.a.'}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isGiven ? 'Given' : 'Taken',
                  style: TextStyle(
                    color: isGiven ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _statusLabel(tx.status),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) =>
                    TransactionDetailScreen(transactionId: tx.id),
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.active:
        return 'Active';
      case TransactionStatus.partiallyPaid:
        return 'Partial';
      case TransactionStatus.settled:
        return 'Settled';
    }
  }
}
