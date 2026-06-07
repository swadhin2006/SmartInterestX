import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/payment_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

class AddPaymentScreen extends StatefulWidget {
  final LoanTransaction transaction;
  const AddPaymentScreen({super.key, required this.transaction});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  PaymentMode _mode = PaymentMode.cash;
  DateTime _paymentDate = DateTime.now();
  String? _proofImagePath;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _proofImagePath = picked.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<TransactionProvider>().addPayment(
            transactionId: widget.transaction.id,
            amount: double.parse(_amountCtrl.text),
            mode: _mode,
            paymentDate: _paymentDate,
            proofImagePath: _proofImagePath,
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final fmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Transaction Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      Text(Formatters.currency(tx.totalPayable),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      Text(
                        Formatters.currency(tx.remainingAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.taken,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Amount
            const Text('Payment Amount (₹)',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Enter amount paid',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Invalid amount';
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Payment Mode
            const Text('Payment Mode',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PaymentMode.values.map((mode) {
                final selected = _mode == mode;
                return ChoiceChip(
                  label: Text(_modeLabel(mode)),
                  selected: selected,
                  onSelected: (_) => setState(() => _mode = mode),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Payment Date
            const Text('Payment Date',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _paymentDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(fmt.format(_paymentDate),
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Proof Image
            const Text('Payment Proof (optional)',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _proofImagePath != null
                        ? AppTheme.given
                        : const Color(0xFFE5E7EB),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _proofImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_proofImagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_rounded,
                              color: AppTheme.textSecondary, size: 28),
                          SizedBox(height: 6),
                          Text('Tap to upload screenshot/receipt',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Notes
            const Text('Notes (optional)',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Any additional notes...',
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _modeLabel(PaymentMode mode) {
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
