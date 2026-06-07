import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/contact_provider.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedYear = DateTime.now().year;
  String? _selectedContactId; // filter by contact

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final contactProvider = context.watch<ContactProvider>();

    // Apply filters: year + optional contact
    var yearTxs = txProvider.filterByYear(_selectedYear);
    if (_selectedContactId != null) {
      yearTxs = yearTxs
          .where((t) => t.contactId == _selectedContactId)
          .toList();
    }

    // Monthly interest data
    final monthlyGiven = List.filled(12, 0.0);
    final monthlyTaken = List.filled(12, 0.0);
    for (final tx in yearTxs) {
      final m = tx.startDate.month - 1;
      if (tx.type == TransactionType.given) {
        monthlyGiven[m] += tx.interestTillToday;
      } else {
        monthlyTaken[m] += tx.interestTillToday;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          // Filter by contact
          PopupMenuButton<String?>(
            icon: Icon(
              _selectedContactId != null
                  ? Icons.person_rounded
                  : Icons.person_outline_rounded,
              color: Colors.white,
            ),
            tooltip: 'Filter by contact',
            onSelected: (id) => setState(() => _selectedContactId = id),
            itemBuilder: (_) => [
              const PopupMenuItem<String?>(
                value: null,
                child: Text('All Contacts'),
              ),
              ...contactProvider.allContacts.map(
                (c) => PopupMenuItem<String?>(
                  value: c.id,
                  child: Text(c.name),
                ),
              ),
            ],
          ),
          // Filter by year
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<int>(
              value: _selectedYear,
              dropdownColor: AppTheme.primaryDark,
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: List.generate(5, (i) => DateTime.now().year - i)
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text('$y',
                            style:
                                const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (y) => setState(() => _selectedYear = y!),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active filter chip
          if (_selectedContactId != null) ...[
            Wrap(
              children: [
                Chip(
                  label: Text(
                    'Contact: ${contactProvider.getById(_selectedContactId!)?.name ?? "Unknown"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () =>
                      setState(() => _selectedContactId = null),
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  side: BorderSide(
                      color: AppTheme.primary.withOpacity(0.3)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Summary Row
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total Earned',
                  txProvider.totalInterestEarned,
                  AppTheme.given,
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Total Paid',
                  txProvider.totalInterestPaid,
                  AppTheme.taken,
                  Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Receivable',
                  txProvider.totalReceivable,
                  AppTheme.accent,
                  Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Payable',
                  txProvider.totalPayable,
                  AppTheme.warning,
                  Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Given vs Taken Pie Chart
          _chartCard(
            title: 'Given vs Taken',
            child: txProvider.transactions.isEmpty
                ? _noDataWidget()
                : SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: txProvider.givenTransactions.length
                                .toDouble(),
                            color: AppTheme.given,
                            title:
                                'Given\n${txProvider.givenTransactions.length}',
                            radius: 80,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          PieChartSectionData(
                            value: txProvider.takenTransactions.length
                                .toDouble(),
                            color: AppTheme.taken,
                            title:
                                'Taken\n${txProvider.takenTransactions.length}',
                            radius: 80,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        sectionsSpace: 3,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Monthly Interest Flow Bar Chart
          _chartCard(
            title: 'Monthly Interest Flow — $_selectedYear',
            child: yearTxs.isEmpty
                ? _noDataWidget()
                : SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _maxMonthly(monthlyGiven, monthlyTaken) * 1.2,
                        barGroups: List.generate(12, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: monthlyGiven[i],
                                color: AppTheme.given,
                                width: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              BarChartRodData(
                                toY: monthlyTaken[i],
                                color: AppTheme.taken,
                                width: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const months = [
                                  'J', 'F', 'M', 'A', 'M', 'J',
                                  'J', 'A', 'S', 'O', 'N', 'D'
                                ];
                                return Text(
                                  months[val.toInt()],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (val, meta) => Text(
                                '₹${val.toInt()}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (val) => FlLine(
                            color: AppTheme.divider,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppTheme.given, 'Interest Earned (Given)'),
              const SizedBox(width: 20),
              _legendDot(AppTheme.taken, 'Interest Paid (Taken)'),
            ],
          ),

          const SizedBox(height: 24),

          // Transaction Stats
          _chartCard(
            title: 'Transaction Summary',
            child: Column(
              children: [
                _summaryRow('Total Transactions',
                    txProvider.transactions.length.toString()),
                _summaryRow('Active',
                    txProvider.activeTransactions.length.toString()),
                _summaryRow('Overdue',
                    txProvider.overdueTransactions.length.toString(),
                    color: AppTheme.taken),
                _summaryRow(
                    'Settled',
                    txProvider.transactions
                        .where((t) =>
                            t.status == TransactionStatus.settled)
                        .length
                        .toString(),
                    color: AppTheme.given),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _maxMonthly(List<double> given, List<double> taken) {
    double max = 0;
    for (int i = 0; i < 12; i++) {
      if (given[i] > max) max = given[i];
      if (taken[i] > max) max = taken[i];
    }
    return max == 0 ? 100 : max;
  }

  Widget _statCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.currency(amount),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({required String title, required Widget child}) {
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _noDataWidget() {
    return const SizedBox(
      height: 100,
      child: Center(
        child: Text(
          'No data for this period',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
