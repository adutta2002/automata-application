import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/pos_models.dart';
import '../../core/app_theme.dart';

class SplitPaymentDialog extends StatefulWidget {
  final double totalAmount;
  final List<InvoicePayment> initialPayments;

  const SplitPaymentDialog({
    super.key,
    required this.totalAmount,
    this.initialPayments = const [],
  });

  @override
  State<SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _SplitPaymentDialogState extends State<SplitPaymentDialog> {
  List<InvoicePayment> _payments = [];
  double _remainingAmount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPayments.isNotEmpty) {
      _payments = List.from(widget.initialPayments);
    } else {
      // Default to one row with total amount in CASH
      _payments.add(InvoicePayment(amount: widget.totalAmount, mode: 'CASH'));
    }
    _calculateRemaining();
  }

  void _calculateRemaining() {
    double totalAdded = _payments.fold(0, (sum, p) => sum + p.amount);
    setState(() {
      _remainingAmount = widget.totalAmount - totalAdded;
      // Allow small float point errors
      if (_remainingAmount.abs() < 0.01) _remainingAmount = 0;
    });
  }

  void _addPaymentRow() {
    if (_remainingAmount <= 0) return;
    setState(() {
      _payments.add(InvoicePayment(amount: _remainingAmount, mode: 'CASH'));
    });
    _calculateRemaining();
  }

  void _removePaymentRow(int index) {
    setState(() {
      _payments.removeAt(index);
    });
    _calculateRemaining();
  }

  void _updatePayment(int index, double amount, String mode, String? transactionId) {
    setState(() {
      _payments[index] = InvoicePayment(
        amount: amount,
        mode: mode,
        transactionId: transactionId,
      );
    });
    _calculateRemaining();
  }

  bool get _isValid {
    if (_payments.isEmpty) return false;
    double total = _payments.fold(0, (sum, p) => sum + p.amount);
    return (total - widget.totalAmount).abs() < 0.01;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Split Payment'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryHeader(),
            const SizedBox(height: 16),
            const Divider(),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _payments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildPaymentRow(index),
              ),
            ),
            const SizedBox(height: 12),
            if (_remainingAmount > 0.01)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addPaymentRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Payment Method'),
                ),
              ),
             if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid ? () => Navigator.pop(context, _payments) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Split'),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Payable', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text(
              '₹${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Remaining', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text(
              '₹${_remainingAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: _remainingAmount > 0.01 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentRow(int index) {
    final payment = _payments[index];
    final amountCtrl = TextEditingController(text: payment.amount.toStringAsFixed(0));
    final txnCtrl = TextEditingController(text: payment.transactionId);

    // Ensure we handle updates correctly without endless loops
    // But since we key/rebuild, controllers might lose focus if not careful.
    // For simplicity in dialog, we just recreate them, but ideally we should keep state.
    // Given the simplicity, let's just use onChange.
    
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: payment.mode,
            decoration: const InputDecoration(
              labelText: 'Mode',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            items: ['CASH', 'UPI', 'CARD', 'ADVANCE']
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (val) {
              if (val != null) _updatePayment(index, payment.amount, val, payment.transactionId);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: payment.amount.toStringAsFixed(2),
            decoration: const InputDecoration(
              labelText: 'Amount',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            onChanged: (val) {
              final amt = double.tryParse(val) ?? 0;
              _updatePayment(index, amt, payment.mode, payment.transactionId);
            },
          ),
        ),
        const SizedBox(width: 8),
        if (payment.mode != 'CASH') ...[
          Expanded(
            flex: 3,
            child: TextFormField(
               initialValue: payment.transactionId,
               decoration: const InputDecoration(
                labelText: 'Transaction / Ref ID',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                 _updatePayment(index, payment.amount, payment.mode, val);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.grey),
          onPressed: _payments.length > 1 ? () => _removePaymentRow(index) : null,
        ),
      ],
    );
  }
}
