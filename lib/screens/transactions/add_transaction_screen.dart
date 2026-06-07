import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/contact_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/contact_model.dart';
import '../../services/interest_service.dart';
import '../../services/notification_service.dart';

// Module 3 — Add Transaction Screen
// Roadmap Section 7.2: Form + DatePicker + Real-time interest preview
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _type = 'given';
  String _interestType = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;
  Contact? _selectedContact;
  bool _loading = false;

  // Live preview — Roadmap 7.2
  double _interestToday = 0;
  double _interestDue = 0;
  double _totalPayable = 0;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_recalculate);
    _rateCtrl.addListener(_recalculate);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_recalculate);
    _rateCtrl.removeListener(_recalculate);
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // Roadmap 7.2: live preview recalculation
  void _recalculate() {
    final principal = double.tryParse(_amountCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    if (principal <= 0 || rate <= 0) {
      setState(() {
        _interestToday = 0;
        _interestDue = 0;
        _totalPayable = 0;
      });
      return;
    }

    final isMonthly = _interestType == 'monthly';
    final daysToday = DateTime.now().difference(_startDate).inDays;

    final interestToday = InterestService.calculateForDays(
      principal: principal,
      rate: rate,
      days: daysToday,
      isMonthly: isMonthly,
    );

    double interestDue = interestToday;
    if (_dueDate != null) {
      final daysDue = _dueDate!.difference(_startDate).inDays;
      interestDue = InterestService.calculateForDays(
        principal: principal,
        rate: rate,
        days: daysDue,
        isMonthly: isMonthly,
      );
    }

    setState(() {
      _interestToday = interestToday;
      _interestDue = interestDue;
      _totalPayable = InterestService.totalPayable(principal, interestToday);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a contact')),
      );
      return;
    }
    setState(() => _loading = true);

    final tx = await context.read<TransactionProvider>().addTransaction(
          contactId: _selectedContact!.id,
          contactName: _selectedContact!.name,
          amount: double.parse(_amountCtrl.text),
          type: _type == 'given'
              ? TransactionType.given
              : TransactionType.taken,
          interestRate: double.parse(_rateCtrl.text),
          interestType: _interestType == 'monthly'
              ? InterestType.monthly
              : InterestType.yearly,
          startDate: _startDate,
          dueDate: _dueDate,
          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        );

    // Schedule reminders — Roadmap 9.3
    if (_dueDate != null) {
      await NotificationService.instance
          .scheduleAllReminders(tx, [1, 3, 7]);
    }

    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactProvider>().allContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Amount input — Roadmap 7.2
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Principal Amount (₹)',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _recalculate(),
              validator: (v) => v!.isEmpty ? 'Amount required' : null,
            ),
            const SizedBox(height: 16),

            // Given / Taken toggle — Roadmap 7.2: SegmentedButton
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'given',
                  label: Text('Given (I Lent)'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'taken',
                  label: Text('Taken (I Borrowed)'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) =>
                  setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),

            // Contact picker
            DropdownButtonFormField<Contact>(
              value: _selectedContact,
              decoration: const InputDecoration(
                labelText: 'Select Contact',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              items: contacts
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (c) => setState(() => _selectedContact = c),
              validator: (v) =>
                  v == null ? 'Please select a contact' : null,
            ),
            const SizedBox(height: 16),

            // Interest Rate — Roadmap 7.2
            TextFormField(
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Interest Rate (%)',
                suffixText: '% per year',
                prefixIcon: Icon(Icons.percent),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _recalculate(),
            ),
            const SizedBox(height: 16),

            // Interest type toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
                ButtonSegment(value: 'yearly', label: Text('Yearly')),
              ],
              selected: {_interestType},
              onSelectionChanged: (s) {
                setState(() => _interestType = s.first);
                _recalculate();
              },
            ),
            const SizedBox(height: 16),

            // Date Picker for Start Date — Roadmap 7.2: InkWell
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                  _recalculate();
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                    DateFormat('dd MMM yyyy').format(_startDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Due Date (optional)
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
                  _recalculate();
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date (optional)',
                  prefixIcon: Icon(Icons.event),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _dueDate != null
                      ? DateFormat('dd MMM yyyy').format(_dueDate!)
                      : 'Tap to select',
                  style: TextStyle(
                    color: _dueDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Live Interest Preview Card — Roadmap 7.2
            if (_interestToday > 0 || _totalPayable > 0)
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _previewRow(
                        'Interest Till Today',
                        '₹ ${_interestToday.toStringAsFixed(2)}',
                      ),
                      _previewRow(
                        'Interest Till Due Date',
                        '₹ ${_interestDue.toStringAsFixed(2)}',
                      ),
                      const Divider(),
                      _previewRow(
                        'Total Payable',
                        '₹ ${_totalPayable.toStringAsFixed(2)}',
                        isHighlight: true,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SI = P × R × T / 100',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight:
                    isHighlight ? FontWeight.bold : FontWeight.normal,
              )),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.blue[800] : Colors.black87,
              fontSize: isHighlight ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
