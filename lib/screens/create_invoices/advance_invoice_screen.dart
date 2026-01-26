import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/pos_models.dart';
import '../../providers/pos_provider.dart';
import '../../providers/tab_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/app_theme.dart';
import '../../widgets/invoice/customer_selector.dart';
import '../../widgets/invoice/invoice_summary_pane.dart';
import '../invoices_screen.dart';
import '../invoice_details_screen.dart';

class AdvancePaymentScreen extends StatefulWidget {
  final String? tabId;
  final Invoice? existingInvoice;
  const AdvancePaymentScreen({super.key, this.tabId, this.existingInvoice});

  @override
  State<AdvancePaymentScreen> createState() => _AdvancePaymentScreenState();
}

class _AdvancePaymentScreenState extends State<AdvancePaymentScreen> {
  Customer? _selectedCustomer;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _paymentMode = 'CASH';

  // Advance payments don't really have "Discounts", but the summary pane expects it.
  double _billDiscount = 0;
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      _loadExistingInvoice();
    }
  }

  void _loadExistingInvoice() {
    final inv = widget.existingInvoice!;
    _selectedCustomer = context.read<POSProvider>().customers.firstWhere(
      (c) => c.id == inv.customerId,
      orElse: () => Customer(name: 'Unknown', phone: '', email: '', address: '', createdAt: DateTime.now())
    );
    _amountController.text = inv.subTotal.toStringAsFixed(2);
    _reasonController.text = inv.notes ?? '';
    _selectedDate = inv.createdAt;
    _billDiscount = inv.discountAmount;
    _paymentMode = inv.paymentMode ?? 'CASH';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingInvoice != null ? 'Edit Advance Payment #${widget.existingInvoice!.invoiceNumber}' : 'Record Advance Payment'),
        automaticallyImplyLeading: false,
        actions: [
          if (widget.tabId != null)
             TextButton.icon(
              onPressed: () => context.read<TabProvider>().removeTab(widget.tabId!),
              icon: const Icon(Icons.close, color: Colors.black87),
              label: const Text('Close Tab', style: TextStyle(color: Colors.black87)),
            ),
          if (_selectedCustomer != null || _amountController.text.isNotEmpty)
            TextButton.icon(
              onPressed: _cleanForm,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1000) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildDateSelector(),
                        ),
                        const SizedBox(height: 16),
                        CustomerSelector(
                          selectedCustomer: _selectedCustomer,
                          customers: context.watch<POSProvider>().customers,
                          onSelected: (c) => setState(() => _selectedCustomer = c),
                        ),
                        const SizedBox(height: 32),
                        _buildAdvanceForm(),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Container(
                  width: 400,
                  padding: const EdgeInsets.all(32),
                  child: SingleChildScrollView(child: _buildSummaryPane()),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildDateSelector(),
                  ),
                  const SizedBox(height: 16),
                  CustomerSelector(
                      selectedCustomer: _selectedCustomer,
                      customers: context.watch<POSProvider>().customers,
                      onSelected: (c) => setState(() => _selectedCustomer = c),
                    ),
                    const SizedBox(height: 24),
                    _buildAdvanceForm(),
                    const SizedBox(height: 24),
                    const Divider(),
                    _buildSummaryPane(),
                    const SizedBox(height: 60),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          final time = await showTimePicker(
             context: context,
             initialTime: TimeOfDay.fromDateTime(_selectedDate),
          );
          if (time != null) {
            setState(() {
              _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvanceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(labelText: 'Advance Amount', prefixText: '₹ ', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        // Payment Mode handled in Summary Pane
        TextField(
          controller: _reasonController,
          decoration: const InputDecoration(labelText: 'Remarks / Reason', border: OutlineInputBorder()),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSummaryPane() {
    final subTotal = double.tryParse(_amountController.text) ?? 0.0;
    return InvoiceSummaryPane(
      selectedCustomer: _selectedCustomer,
      subTotal: subTotal,
      tax: 0,
      discount: _billDiscount,
      discountInput: 0,
      isDiscountPercentage: false,
      isReady: subTotal > 0 && _selectedCustomer != null,
      paymentMode: _paymentMode,
      onPaymentModeChanged: (val) => setState(() => _paymentMode = val),
      onSave: () => _submitAdvance(InvoiceStatus.active),
      onHold: () => _submitAdvance(InvoiceStatus.hold),
      onDiscountChanged: (val, isPercentage) {
        setState(() {
          _billDiscount = isPercentage ? subTotal * (val / 100) : val;
        });
      },
    );
  }

  void _cleanForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Form?'),
        content: const Text('Are you sure you want to clear all details?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedCustomer = null;
                _amountController.clear();
                _reasonController.clear();
                _billDiscount = 0;
                _paymentMode = 'CASH';
              });
            },
            child: const Text('Yes, Clear'),
          ),
        ],
      ),
    );
  }

  void _submitAdvance(InvoiceStatus status) async {
    // Auto-create customer if needed
    if (_selectedCustomer != null && _selectedCustomer!.id == null) {
      final newCustomer = await context.read<POSProvider>().addCustomer(_selectedCustomer!);
      setState(() {
        _selectedCustomer = newCustomer;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('New customer "${newCustomer.name}" created')));
    }

    final branchId = context.read<SettingsProvider>().currentBranchId;

    final amount = double.parse(_amountController.text);
    final invoice = Invoice(
      id: widget.existingInvoice?.id,
      invoiceNumber: widget.existingInvoice?.invoiceNumber ?? context.read<POSProvider>().generateInvoiceNumber(),
      customerId: _selectedCustomer?.id,
      branchId: branchId, 
      type: InvoiceType.advance,
      subTotal: amount,
      taxAmount: 0,
      discountAmount: _billDiscount, 
      totalAmount: amount - _billDiscount,
      createdAt: _selectedDate,
      paymentMode: _paymentMode,
      status: status,
      notes: _reasonController.text,
      items: [
        InvoiceItem(
          itemId: 0,
          itemType: 'ADVANCE',
          name: 'Advance Payment - $_paymentMode',
          quantity: 1,
          rate: amount,
          total: amount,
          gstRate: 0,
        )
      ],
    );
    
    int? createdId;
    if (widget.existingInvoice != null) {
       await context.read<POSProvider>().updateInvoice(invoice);
       createdId = widget.existingInvoice!.id;
    } else {
       createdId = await context.read<POSProvider>().createInvoice(invoice);
    }
    
    if (mounted && createdId != null) {
       final tabProvider = context.read<TabProvider>();
       
       if (widget.tabId != null) {
         tabProvider.removeTab(widget.tabId!);
       }

       final detailsTabId = 'invoice_details_$createdId';
       if (tabProvider.hasTab(detailsTabId)) {
         tabProvider.setActiveTab(detailsTabId);
       } else {
         tabProvider.addTab(
           TabItem(
             id: detailsTabId,
             title: 'Invoice #${invoice.invoiceNumber}',
             widget: InvoiceDetailsScreen(invoiceId: createdId),
             type: TabType.invoiceDetails,
           ),
         );
       }

       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text('Advance ${status == InvoiceStatus.hold ? 'Held' : (widget.existingInvoice != null ? 'Updated' : 'Recorded')} Successfully'), 
         backgroundColor: status == InvoiceStatus.hold ? Colors.orange : Colors.green
       ));
    }
  }
}
