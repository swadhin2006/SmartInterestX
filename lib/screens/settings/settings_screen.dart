import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/contact_provider.dart';
import '../../services/export_service.dart';
import '../../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Reminder preference (roadmap 9.4)
  int _reminderDays = 1;
  final List<int> _reminderOptions = [1, 3, 7];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderDays = prefs.getInt('reminder_days') ?? 1;
    });
  }

  Future<void> _saveReminderDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_days', days);
    setState(() => _reminderDays = days);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── App Info ──────────────────────────────────────────────────
          _sectionHeader('About'),
          _settingsTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'SmartInterestX',
            subtitle: 'Version 1.0.0 — Loan & Interest Manager',
            color: AppTheme.primary,
          ),

          const SizedBox(height: 20),

          // ── Notifications & Reminders (Roadmap 9.4) ───────────────────
          _sectionHeader('Notifications & Reminders'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          color: AppTheme.warning, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Remind me before due date',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // RadioListTile for reminder days (roadmap 9.4)
                ..._reminderOptions.map((day) => RadioListTile<int>(
                      title: Text(
                        '$day day${day > 1 ? 's' : ''} before due date',
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: day,
                      groupValue: _reminderDays,
                      activeColor: AppTheme.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => _saveReminderDays(v!),
                    )),
                const Divider(height: 16),
                const Text(
                  'Reminders are also auto-scheduled for 1, 3, and 7 days before due date when you add a transaction.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Export ────────────────────────────────────────────────────
          _sectionHeader('Data & Export'),
          _settingsTile(
            icon: Icons.download_rounded,
            title: 'Export to CSV',
            subtitle: 'Download all transactions as a spreadsheet',
            color: AppTheme.accent,
            onTap: () async {
              final txProvider = context.read<TransactionProvider>();
              if (txProvider.transactions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('No transactions to export')),
                );
                return;
              }
              try {
                await ExportService.instance
                    .exportTransactionsToCSV(txProvider.transactions);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 10),

          _settingsTile(
            icon: Icons.cloud_upload_rounded,
            title: 'Backup to Firebase',
            subtitle: 'Sync all data to Firestore cloud',
            color: AppTheme.primary,
            onTap: () async {
              final txProvider = context.read<TransactionProvider>();
              final contactProvider = context.read<ContactProvider>();
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backing up to Firebase...')),
                );
                await contactProvider.backupToCloud();
                await txProvider.backupToCloud();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Backup complete!'),
                      backgroundColor: AppTheme.given,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Backup failed: $e')),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 10),

          _settingsTile(
            icon: Icons.cloud_download_rounded,
            title: 'Restore from Firebase',
            subtitle: 'Restore data from Firestore cloud backup',
            color: Color(0xFF7C3AED),
            onTap: () async {
              final txProvider = context.read<TransactionProvider>();
              final contactProvider = context.read<ContactProvider>();
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Restoring from Firebase...')),
                );
                await contactProvider.restoreFromCloud();
                await txProvider.restoreFromCloud();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Restore complete!'),
                      backgroundColor: AppTheme.given,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e')),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 20),

          // ── Interest Calculation Reference ────────────────────────────
          _sectionHeader('Interest Calculation Formula'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                const Text(
                  'Simple Interest (SI)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _formulaBox('SI = (P × R × T) / 100'),
                const SizedBox(height: 12),
                _formulaRow('P', 'Principal Amount'),
                _formulaRow('R', 'Interest Rate (%)'),
                _formulaRow('T (Monthly)', 'Days / 30'),
                _formulaRow('T (Yearly)', 'Days / 365'),
                _formulaRow('Total', 'Principal + SI'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.given.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Example: ₹10,000 at 2% per month for 3 months\n'
                    'SI = (10000 × 2 × 3) / 100 = ₹600\n'
                    'Total = ₹10,600',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── ER Diagram Reference ──────────────────────────────────────
          _sectionHeader('Database Schema'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                const Text(
                  'ER Diagram — 3 Entities',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _erRow('Contact', 'id, name, mobile, email, createdAt'),
                _erRow('Transaction',
                    'id, contactId, amount, type, rate, startDate, dueDate, status'),
                _erRow('Payment',
                    'id, transactionId, amount, mode, date, proofPath'),
                const SizedBox(height: 8),
                const Text(
                  'Contact → (1:N) → Transaction → (1:N) → Payment',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              '© 2025 SmartInterestX\nBuilt with Flutter · SQLite · Provider',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _formulaBox(String formula) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Text(
        formula,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 15,
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _formulaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '= $value',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _erRow(String entity, String fields) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              entity,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fields,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
